-- =============================================================================
-- tests/emk_ui/error_messages_test.sql
-- Test of the error handling function of the application (step 7.8, owner
-- rule 2026-10-22: every message a user sees is friendly): runs as EMK_UI,
-- the parsing schema of APEX, with an APEX session of application
-- &emk_apex_app_id, and passes errors through
-- EMK_APEX_ERROR_PKG.handle_error as APEX does. Checks:
--   1. every business error -20001 … -20999 of EMK_ERRORS_PKG shows its text
--      message EMK_ERROR_<code>;
--   2. every constraint a user can reach from a page shows the text message
--      named as the constraint, also for a real violation through the API;
--   3. a value too long and a number too large show their general texts;
--   4. an error without its text, and an internal APEX error, show
--      EMK_ERROR_UNEXPECTED with the number of a log entry that exists;
--   5. a message of APEX itself (e.g. a required page item) stays as it is;
--   6. no message shows an ORA- code.
-- Data changes are rolled back. The two log entries of step 4 are committed
-- by EMK_LOG_PKG and EMK_UI cannot delete them: run test_log_cleanup.sql as
-- EMK_API right after this script. Refuses PROD.
--
-- Run from the repository root (DEV: through the proxy of EMK_UI):
--   sql -thin "EMK_DEV[EMK_UI]@localhost:1521/FREEPDB1" @tests/emk_ui/error_messages_test.sql
--   sql -thin "EMK_DEV[EMK_API]@localhost:1521/FREEPDB1" @tests/emk_ui/test_log_cleanup.sql
-- Output: logs\tests\error_messages_test_<YYYYMMDD_HH24MISS>.log
-- Expected last line: "RESULT: all checks passed"
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-22
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

HOST powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'logs\tests' | Out-Null"
SET TERMOUT OFF
COLUMN cfg_log NEW_VALUE emk_log_file
SELECT 'logs\tests\error_messages_test_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log FROM dual;
SET TERMOUT ON
SPOOL &emk_log_file
PROMPT Log of this run: &emk_log_file

-- PROD is not offered (tests never run there); the check below still refuses it.
ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST or ACC): '
@@../../scripts/admin/00_config.sql

BEGIN
    IF '&emk_env' = 'PROD' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Tests never run in PROD.');
    END IF;
    IF USER <> UPPER('&emk_ui_schema') THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect as the parsing schema: EMK_DEV[&emk_ui_schema], not ' || USER || '.');
    END IF;
END;
/

PROMPT === Error messages: APEX session of application &emk_apex_app_id as &emk_ui_schema
DECLARE
    TYPE t_names IS TABLE OF VARCHAR2(100 CHAR);
    c_test_user   CONSTANT VARCHAR2(30 CHAR) := 'ERROR_MESSAGES_TEST';   -- removed from the log by test_log_cleanup.sql
    c_test_failed CONSTANT PLS_INTEGER := -20999;                        -- this script only
    -- Business errors of EMK_ERRORS_PKG (EMK_UI has no EXECUTE on it: codes as literals)
    l_codes       t_names := t_names('20001', '20002', '20003', '20004', '20005', '20101', '20102', '20103', '20104',
                                     '20105', '20106', '20201', '20202', '20203', '20204', '20301', '20302', '20303',
                                     '20401', '20402', '20403');
    -- Constraints a user can reach from a page
    l_constraints t_names := t_names('EMK_PARTIES_VAT_CK', 'EMK_CONTACTS_EMAIL_CK', 'EMK_CONTACTS_PHONE_CK',
                                     'EMK_SHIPMENTS_COUNTRIES_CK', 'EMK_SHIPMENTS_DATES_CK', 'EMK_SHIPMENTS_DISPOSAL_CK',
                                     'EMK_SHIPMENTS_WEIGHT_CK', 'EMK_SHIPMENTS_PACKAGES_CK', 'EMK_SHIPMENTS_CHARGES_CK',
                                     'EMK_SHIPMENTS_DECLARED_VALUE_CK', 'EMK_SHIPMENTS_SPECIAL_INTEREST_CK',
                                     'EMK_PARTY_ROLE_TYPES_CODE_CK', 'EMK_DOCUMENT_TYPES_CODE_CK',
                                     'EMK_PARTY_ROLE_TYPES_VALID_CK', 'EMK_DOCUMENT_TYPES_VALID_CK', 'EMK_FILE_TYPES_VALID_CK');
    l_failures    PLS_INTEGER := 0;
    l_text        VARCHAR2(4000 CHAR);
    l_expected    VARCHAR2(4000 CHAR);
    l_log_id      NUMBER;
    l_count       PLS_INTEGER;
    l_sender      NUMBER;
    l_carrier     NUMBER;
    l_consignee   NUMBER;
    l_shipment    NUMBER;

    PROCEDURE check_result (in_ok IN BOOLEAN, in_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN in_ok THEN 'PASS  ' ELSE 'FAIL  ' END || in_label);
        IF NOT in_ok OR in_ok IS NULL THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;

    -- The message the user sees for an error, as APEX hands it to the function
    FUNCTION get_friendly (in_sqlcode IN NUMBER, in_sqlerrm IN VARCHAR2, in_internal IN BOOLEAN DEFAULT FALSE)
        RETURN VARCHAR2 IS
        l_error apex_error.t_error;
    BEGIN
        l_error.message                 := in_sqlerrm;
        l_error.ora_sqlcode             := in_sqlcode;
        l_error.ora_sqlerrm             := in_sqlerrm;
        l_error.is_internal_error       := in_internal;
        l_error.is_common_runtime_error := FALSE;
        RETURN &emk_api_schema..emk_apex_error_pkg.handle_error(p_error => l_error).message;
    END get_friendly;

    -- Text message of the application; NULL if it does not exist
    FUNCTION get_message (in_name IN VARCHAR2) RETURN VARCHAR2 IS
        l_message VARCHAR2(4000 CHAR) := APEX_LANG.MESSAGE(p_name => in_name);
    BEGIN
        RETURN CASE WHEN l_message IS NULL OR l_message = in_name THEN NULL ELSE l_message END;
    END get_message;

    FUNCTION new_party (in_name IN VARCHAR2, in_country IN VARCHAR2, in_roles IN VARCHAR2) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
        &emk_api_schema..emk_party_api.create_party(in_name => in_name, in_vat_number => NULL,
            in_country_code => in_country, in_street => NULL, in_postal_code => NULL, in_city => NULL,
            in_language_code => 'en', in_role_codes => in_roles, out_party_id => l_id);
        RETURN l_id;
    END new_party;
BEGIN
    APEX_SESSION.CREATE_SESSION(p_app_id => &emk_apex_app_id, p_page_id => 1, p_username => c_test_user);

    -- 1. Business errors, raised for real
    FOR i IN 1 .. l_codes.COUNT LOOP
        l_expected := get_message('EMK_ERROR_' || l_codes(i));
        BEGIN
            RAISE_APPLICATION_ERROR(-TO_NUMBER(l_codes(i)), 'Technical text of the API');
        EXCEPTION
            WHEN OTHERS THEN
                l_text := get_friendly(SQLCODE, SQLERRM);
        END;
        check_result(l_expected IS NOT NULL AND l_text = l_expected AND l_text NOT LIKE '%ORA-%',
                     '-' || l_codes(i) || ': ' || SUBSTR(l_text, 1, 90));
    END LOOP;

    -- 2. Constraints, as the database reports them
    FOR i IN 1 .. l_constraints.COUNT LOOP
        l_expected := get_message(l_constraints(i));
        l_text := get_friendly(-2290, 'ORA-02290: check constraint (EMK_DATA.' || l_constraints(i) || ') violated');
        check_result(l_expected IS NOT NULL AND l_text = l_expected AND l_text NOT LIKE '%ORA-%',
                     l_constraints(i) || ': ' || SUBSTR(l_text, 1, 70));
    END LOOP;

    --    and a real violation through the API: delivery before the taking over
    l_sender    := new_party('Error Messages Test Sender', 'DE', 'SENDER');
    l_carrier   := new_party('Error Messages Test Carrier', 'PL', 'CARRIER');
    l_consignee := new_party('Error Messages Test Consignee', 'FR', 'CONSIGNEE');
    BEGIN
        &emk_api_schema..emk_shipment_api.create_shipment(in_cmr_note_no => 'ERROR-MESSAGES-TEST-1',
            in_cmr_note_date => DATE '2026-09-01', in_sender_id => l_sender, in_carrier_id => l_carrier,
            in_consignee_id => l_consignee, in_taking_over_place => 'Berlin', in_origin_country => 'DE',
            in_delivery_place => 'Paris', in_destination_country => 'FR', in_taking_over_date => DATE '2026-09-10',
            in_agreed_time_limit => NULL, in_delivery_date => DATE '2026-09-05', in_disposal_date => NULL,
            in_goods_description => 'Test goods', in_packages => 1, in_gross_weight_kg => 100,
            in_carriage_charges => NULL, in_currency_code => NULL, in_declared_value => NULL,
            in_declared_value_currency => NULL, in_special_interest => NULL, in_special_interest_currency => NULL,
            out_shipment_id => l_shipment);
        check_result(FALSE, 'A delivery before the taking over was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            l_text := get_friendly(SQLCODE, SQLERRM);
            check_result(l_text = get_message('EMK_SHIPMENTS_DATES_CK'),
                         'A real violation through the API shows the text of its constraint: ' || SUBSTR(l_text, 1, 60));
    END;

    -- 3. General texts
    l_text := get_friendly(-12899, 'ORA-12899: value too large for column "EMK_DATA"."EMK_PARTIES"."NAME" (actual: 300, maximum: 200)');
    check_result(l_text = get_message('EMK_ERROR_ORA_12899'), 'A value too long: ' || l_text);
    l_text := get_friendly(-1438, 'ORA-01438: value larger than specified precision allowed for this column');
    check_result(l_text = get_message('EMK_ERROR_ORA_01438'), 'A number too large: ' || l_text);

    -- 4. No text, or an internal error: the generic text with a log entry that exists
    BEGIN
        RAISE_APPLICATION_ERROR(-20000, 'An error of a script, without a friendly text');
    EXCEPTION
        WHEN OTHERS THEN
            l_text := get_friendly(SQLCODE, SQLERRM);
    END;
    l_log_id := TO_NUMBER(REGEXP_SUBSTR(l_text, '([0123456789]+)\.$', 1, 1, NULL, 1));
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_log
    WHERE  log_id = l_log_id AND created_by = c_test_user AND log_level = 'ERROR';
    check_result(l_text LIKE 'Something went wrong%' AND l_count = 1,
                 'An error without its text shows the generic message and its log entry ' || l_log_id || ' exists');
    l_text := get_friendly(NULL, 'ORA-06502: PL/SQL: numeric or value error in an internal statement', in_internal => TRUE);
    check_result(l_text LIKE 'Something went wrong%' AND l_text NOT LIKE '%ORA-%',
                 'An internal APEX error is masked: ' || SUBSTR(l_text, 1, 60));

    -- 5. A message of APEX itself stays as it is
    l_text := get_friendly(NULL, 'Name must have some value.');
    check_result(l_text = 'Name must have some value.', 'A message of APEX without ORA code is kept: ' || l_text);

    -- 6. Nothing is kept: data rolled back, session closed
    ROLLBACK;
    APEX_SESSION.DELETE_SESSION;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0 THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);
    DBMS_OUTPUT.PUT_LINE('Next: run tests/emk_ui/test_log_cleanup.sql as EMK_DEV[EMK_API].');
    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(c_test_failed, 'Error messages test failed.');
    END IF;
END;
/

SPOOL OFF
EXIT
