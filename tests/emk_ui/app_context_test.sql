-- =============================================================================
-- tests/emk_ui/app_context_test.sql
-- Test in the context of the application (test level "Application context",
-- step 7.5): runs as EMK_UI, the parsing schema of APEX, with an APEX session
-- of application &emk_apex_app_id, and calls the APIs and views exactly as a
-- page does. Checks what the unit tests in EMK_API cannot see:
--   1. EMK_UI has no privilege on any table (ADR-008): direct SELECT and
--      INSERT fail;
--   2. the APIs work with the grants of EMK_UI only (EXECUTE, SELECT on views);
--   3. audit columns and change history record the APEX user, not EMK_UI;
--   4. business errors reach the caller with their code;
--   5. row_version read from a view is accepted back by the API;
--   6. the lists of values read the code lists through their views (D-68)
--      and a code list table is refused.
-- EMK_UI owns no objects, so this is a script, not a utPLSQL package. Every
-- change is rolled back at the end; no rule rejection that writes to the log
-- is triggered (EMK_UI cannot delete log entries). Refuses PROD.
--
-- Run from the repository root (DEV: through the proxy of EMK_UI):
--   sql -thin "EMK_DEV[EMK_UI]@localhost:1521/FREEPDB1" @tests/emk_ui/app_context_test.sql
-- Output: logs\tests\app_context_test_<YYYYMMDD_HH24MISS>.log
-- Expected last line: "RESULT: all checks passed"
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-18
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

HOST powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'logs\tests' | Out-Null"
SET TERMOUT OFF
COLUMN cfg_log NEW_VALUE emk_log_file
SELECT 'logs\tests\app_context_test_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log FROM dual;
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

PROMPT === Application context: APEX session of application &emk_apex_app_id as &emk_ui_schema
DECLARE
    c_app_user     CONSTANT VARCHAR2(30 CHAR) := 'APP_CONTEXT_TEST';
    -- Codes of EMK_ERRORS_PKG as literals: EMK_UI has no EXECUTE on that package
    c_carrier_not_third_party CONSTANT PLS_INTEGER := -20204;
    c_record_changed          CONSTANT PLS_INTEGER := -20004;
    l_failures     PLS_INTEGER := 0;
    l_count        PLS_INTEGER;
    l_text         VARCHAR2(4000 CHAR);
    l_version      VARCHAR2(40 CHAR);
    l_sender       NUMBER;
    l_carrier      NUMBER;
    l_consignee    NUMBER;
    l_contact      NUMBER;
    l_shipment     NUMBER;

    PROCEDURE check_result (in_ok IN BOOLEAN, in_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN in_ok THEN 'PASS  ' ELSE 'FAIL  ' END || in_label);
        IF NOT in_ok OR in_ok IS NULL THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;

    -- TRUE if the statement fails because EMK_UI has no privilege on the table
    FUNCTION is_refused (in_sql IN VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        EXECUTE IMMEDIATE in_sql;
        ROLLBACK;
        RETURN FALSE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN SQLCODE IN (-942, -1031);   -- table or view does not exist / insufficient privileges
    END is_refused;

    FUNCTION version_of (in_view IN VARCHAR2, in_key IN VARCHAR2, in_id IN NUMBER) RETURN TIMESTAMP WITH TIME ZONE IS
        l_row_version VARCHAR2(40 CHAR);
    BEGIN
        EXECUTE IMMEDIATE 'SELECT row_version FROM &emk_api_schema..' || in_view || ' WHERE ' || in_key || ' = :id'
            INTO l_row_version USING in_id;
        RETURN &emk_api_schema..emk_row_version_pkg.parse_row_version(l_row_version);   -- as an APEX page does
    END version_of;

    FUNCTION new_party (in_name IN VARCHAR2, in_country IN VARCHAR2, in_roles IN VARCHAR2) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
        &emk_api_schema..emk_party_api.create_party(in_name => in_name, in_vat_number => NULL,
            in_country_code => in_country, in_street => NULL, in_postal_code => NULL, in_city => NULL,
            in_language_code => 'en', in_role_codes => in_roles, out_party_id => l_id);
        RETURN l_id;
    END new_party;
BEGIN
    -- 1. No privilege on any table (ADR-008)
    check_result(is_refused('SELECT COUNT(*) FROM &emk_data_schema..emk_parties'),
                 'A direct SELECT on a table of &emk_data_schema is refused');
    check_result(is_refused('INSERT INTO &emk_data_schema..emk_parties (name, country_code) VALUES (''X'', ''DE'')'),
                 'A direct INSERT into a table of &emk_data_schema is refused');
    check_result(is_refused('SELECT COUNT(*) FROM &emk_data_schema..emk_parties_jn'),
                 'A direct SELECT on a journal is refused (history only through the views)');
    check_result(is_refused('SELECT COUNT(*) FROM &emk_data_schema..emk_party_role_types'),
                 'A direct SELECT on a code list table is refused (lists only through the views)');
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_party_role_types WHERE valid_yn = 'Y';
    check_result(l_count = 6, 'The list of values of roles offers the 6 roles valid today (' || l_count || ')');

    -- 2. APEX session, as after a login
    APEX_SESSION.CREATE_SESSION(p_app_id => &emk_apex_app_id, p_page_id => 1, p_username => c_app_user);
    check_result(SYS_CONTEXT('APEX$SESSION', 'APP_USER') = c_app_user,
                 'APEX session of application &emk_apex_app_id for ' || c_app_user);

    -- 3. Companies, contact and shipment through the APIs: the APEX user is recorded
    l_sender    := new_party('App Context Test Sender', 'DE', 'SENDER');
    l_carrier   := new_party('App Context Test Carrier', 'PL', 'CARRIER');
    l_consignee := new_party('App Context Test Consignee', 'FR', 'CONSIGNEE');
    SELECT created_by INTO l_text FROM &emk_api_schema..emk_v_parties WHERE party_id = l_carrier;
    check_result(l_text = c_app_user, 'create_party records the APEX user in created_by (' || l_text || ')');

    &emk_api_schema..emk_party_api.update_party(l_carrier, version_of('emk_v_parties', 'party_id', l_carrier),
        'App Context Test Carrier Renamed', NULL, 'PL', NULL, NULL, NULL, 'en');
    SELECT updated_by INTO l_text FROM &emk_api_schema..emk_v_parties WHERE party_id = l_carrier;
    check_result(l_text = c_app_user, 'update_party with row_version from the view: updated_by is the APEX user');
    SELECT MAX(changed_by) INTO l_text FROM &emk_api_schema..emk_v_party_history WHERE party_id = l_carrier AND action = 'UPDATED';
    check_result(l_text = c_app_user, 'Company history (journal) records the APEX user (' || l_text || ')');

    &emk_api_schema..emk_party_api.create_contact(l_consignee, 'App Context Test Person', 'old@example.com', NULL, l_contact);
    &emk_api_schema..emk_party_api.update_contact(l_contact, version_of('emk_v_contacts', 'contact_id', l_contact),
        'App Context Test Person', 'new@example.com', NULL);
    SELECT MAX(changed_by) INTO l_text FROM &emk_api_schema..emk_v_contact_history WHERE contact_id = l_contact;
    check_result(l_text = c_app_user, 'Contact history (journal) records the APEX user');

    &emk_api_schema..emk_shipment_api.create_shipment(in_cmr_note_no => 'APP-CONTEXT-TEST-1', in_cmr_note_date => DATE '2026-09-01',
        in_sender_id => l_sender, in_carrier_id => l_carrier, in_consignee_id => l_consignee,
        in_taking_over_place => 'Berlin', in_origin_country => 'DE', in_delivery_place => 'Paris',
        in_destination_country => 'FR', in_taking_over_date => DATE '2026-09-01', in_agreed_time_limit => NULL,
        in_delivery_date => NULL, in_disposal_date => NULL, in_goods_description => 'Test goods', in_packages => 1,
        in_gross_weight_kg => 100, in_carriage_charges => NULL, in_currency_code => NULL,
        in_declared_value => NULL, in_declared_value_currency => NULL, in_special_interest => NULL,
        in_special_interest_currency => NULL,
        out_shipment_id => l_shipment);
    &emk_api_schema..emk_shipment_api.delete_shipment(l_shipment, version_of('emk_v_shipments', 'shipment_id', l_shipment));
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_deleted_records
    WHERE  entity = 'SHIPMENT' AND record_id = l_shipment AND deleted_by = c_app_user;
    check_result(l_count = 1, 'A deleted shipment appears in the restore list, deleted by the APEX user');
    &emk_api_schema..emk_shipment_api.restore_shipment(l_shipment);
    SELECT LISTAGG(action || '/' || changed_by, ' ') WITHIN GROUP (ORDER BY changed_at, history_id)
    INTO   l_text
    FROM   &emk_api_schema..emk_v_shipment_history
    WHERE  shipment_id = l_shipment;
    check_result(l_text = 'DELETED/' || c_app_user || ' RESTORED/' || c_app_user,
                 'Shipment history: DELETED and RESTORED by the APEX user (' || l_text || ')');

    -- 4. Business errors reach the caller with their code
    BEGIN
        &emk_api_schema..emk_shipment_api.create_shipment(in_cmr_note_no => 'APP-CONTEXT-TEST-2', in_cmr_note_date => DATE '2026-09-01',
            in_sender_id => l_carrier, in_carrier_id => l_carrier, in_consignee_id => l_consignee,
            in_taking_over_place => 'Warsaw', in_origin_country => 'PL', in_delivery_place => 'Paris',
            in_destination_country => 'FR', in_taking_over_date => DATE '2026-09-01', in_agreed_time_limit => NULL,
            in_delivery_date => NULL, in_disposal_date => NULL, in_goods_description => 'Test goods', in_packages => 1,
            in_gross_weight_kg => 100, in_carriage_charges => NULL, in_currency_code => NULL,
        in_declared_value => NULL, in_declared_value_currency => NULL, in_special_interest => NULL,
        in_special_interest_currency => NULL,
            out_shipment_id => l_shipment);
        check_result(FALSE, 'A carrier that is also the sender was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_carrier_not_third_party,
                         'Error "carrier must be another company" reaches the page with its code (' || SQLCODE || ')');
    END;

    BEGIN
        &emk_api_schema..emk_party_api.update_party(l_sender, SYSTIMESTAMP - INTERVAL '1' DAY,
            'App Context Test Sender 2', NULL, 'DE', NULL, NULL, NULL, 'en');
        check_result(FALSE, 'An update with an old version was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_record_changed,
                         'Error "changed by another user" reaches the page with its code (' || SQLCODE || ')');
    END;

    -- 5. Nothing is kept: roll back, then close the APEX session
    ROLLBACK;
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_parties WHERE name LIKE 'App Context Test%';
    check_result(l_count = 0, 'Every change was rolled back: no test company is left');
    APEX_SESSION.DELETE_SESSION;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0 THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);
    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Application context test failed.');
    END IF;
END;
/

SPOOL OFF
EXIT
