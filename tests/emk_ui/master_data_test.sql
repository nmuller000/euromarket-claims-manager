-- =============================================================================
-- tests/emk_ui/master_data_test.sql
-- Test of the master data API in the context of the application (T-M1-44,
-- D-82, step 7.7): runs as EMK_UI, the parsing schema of APEX, with APEX
-- sessions of application &emk_apex_app_id, and calls the API and views as
-- the master data pages do. The API checks the administrator role, which
-- exists only in an APEX session, so this cannot be a utPLSQL test of EMK_API
-- (decision of 2026-10-21: EMK_API gets no workspace access, ADR-008).
-- Checks:
--   1. a user without the administrator role is refused, and the refusal is
--      in the technical log;
--   2. the administrator adds a role and a document type; a code is never
--      reused (also in lower case) and a required value is never defaulted;
--   3. retiring: a retired role stays on the company that has it and is no
--      longer offered; a retired document type is no longer offered;
--   4. a protected role cannot be retired (refusal logged), but its name can
--      change; statuses and claim types: name and order only;
--   5. file types: retire and allow again;
--   6. optimistic locking; an update without change writes no history;
--      every change is in the history with the APEX user.
-- Users: two test names that exist only in this run; the administrator role
-- is given at the start with APEX_ACL.ADD_USER_ROLE and removed at the end,
-- also when a check fails. Data changes are rolled back. The log entries of
-- the two refusals are committed by EMK_LOG_PKG (own transaction) and EMK_UI
-- cannot delete them: run master_data_test_cleanup.sql as EMK_API right
-- after this script. Refuses PROD.
--
-- Run from the repository root (DEV: through the proxy of EMK_UI):
--   sql -thin "EMK_DEV[EMK_UI]@localhost:1521/FREEPDB1" @tests/emk_ui/master_data_test.sql
--   sql -thin "EMK_DEV[EMK_API]@localhost:1521/FREEPDB1" @tests/emk_ui/master_data_test_cleanup.sql
-- Output: logs\tests\master_data_test_<YYYYMMDD_HH24MISS>.log
-- Expected last line: "RESULT: all checks passed"
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-21
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

HOST powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'logs\tests' | Out-Null"
SET TERMOUT OFF
COLUMN cfg_log NEW_VALUE emk_log_file
SELECT 'logs\tests\master_data_test_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log FROM dual;
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

PROMPT === Master data: APEX sessions of application &emk_apex_app_id as &emk_ui_schema
DECLARE
    -- Test users: names that exist only in this run (removed again by the cleanup script)
    c_plain_user CONSTANT VARCHAR2(30 CHAR) := 'MASTER_DATA_TEST_USER';
    c_admin_user CONSTANT VARCHAR2(30 CHAR) := 'MASTER_DATA_TEST_ADMIN';
    c_admin_role CONSTANT VARCHAR2(30 CHAR) := 'ADMINISTRATOR';
    -- Codes of EMK_ERRORS_PKG as literals: EMK_UI has no EXECUTE on that package
    c_not_authorized   CONSTANT PLS_INTEGER := -20001;
    c_invalid_argument CONSTANT PLS_INTEGER := -20003;
    c_record_changed   CONSTANT PLS_INTEGER := -20004;
    c_code_protected   CONSTANT PLS_INTEGER := -20402;
    c_code_exists      CONSTANT PLS_INTEGER := -20403;
    c_test_failed      CONSTANT PLS_INTEGER := -20999;   -- this script only; cleanup already done
    c_test_role        CONSTANT VARCHAR2(20 CHAR) := 'MD_TEST_ROLE';
    c_test_doc_type    CONSTANT VARCHAR2(30 CHAR) := 'MD_TEST_DOC';
    l_failures PLS_INTEGER := 0;
    l_count    PLS_INTEGER;
    l_text     VARCHAR2(4000 CHAR);
    l_company  NUMBER;

    PROCEDURE check_result (in_ok IN BOOLEAN, in_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN in_ok THEN 'PASS  ' ELSE 'FAIL  ' END || in_label);
        IF NOT in_ok OR in_ok IS NULL THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;

    -- row_version of a list view, read back as an APEX page does
    FUNCTION version_of (in_view IN VARCHAR2, in_key IN VARCHAR2, in_code IN VARCHAR2) RETURN TIMESTAMP WITH TIME ZONE IS
        l_row_version VARCHAR2(40 CHAR);
    BEGIN
        EXECUTE IMMEDIATE 'SELECT row_version FROM &emk_api_schema..' || in_view || ' WHERE ' || in_key || ' = :code'
            INTO l_row_version USING in_code;
        RETURN &emk_api_schema..emk_row_version_pkg.parse_row_version(l_row_version);
    END version_of;

    -- Gives back the state before the run: no data, no administrator role, no APEX session
    PROCEDURE clean_up IS
    BEGIN
        ROLLBACK;
        APEX_ACL.REMOVE_USER_ROLE(p_application_id => &emk_apex_app_id, p_user_name => c_admin_user,
                                  p_role_static_id => c_admin_role);
        COMMIT;   -- only the removal of the role is pending after the rollback
        APEX_SESSION.DELETE_SESSION;
    END clean_up;
BEGIN
    -- 1. A user without the administrator role is refused, and the refusal is logged
    APEX_SESSION.CREATE_SESSION(p_app_id => &emk_apex_app_id, p_page_id => 1, p_username => c_plain_user);
    BEGIN
        &emk_api_schema..emk_master_data_api.update_claim_status(in_status_code => 'DRAFT',
            in_expected_updated_at => version_of('emk_v_claim_statuses', 'status_code', 'DRAFT'),
            in_name => 'Draft', in_description => NULL, in_sort_order => 10);
        check_result(FALSE, 'A user without the administrator role changed a claim status');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_not_authorized, 'A user without the administrator role is refused (' || SQLCODE || ')');
    END;
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_log
    WHERE  created_by = c_plain_user AND log_level = 'WARN' AND message = 'Role check refused';
    check_result(l_count >= 1, 'The refusal is in the technical log with the APEX user (ASVS V16.3.2)');

    -- The administrator role, as the master data pages will require it
    APEX_ACL.ADD_USER_ROLE(p_application_id => &emk_apex_app_id, p_user_name => c_admin_user,
                           p_role_static_id => c_admin_role);
    APEX_SESSION.DELETE_SESSION;
    APEX_SESSION.CREATE_SESSION(p_app_id => &emk_apex_app_id, p_page_id => 1, p_username => c_admin_user);
    check_result(APEX_ACL.HAS_USER_ROLE(p_role_static_id => c_admin_role),
                 'APEX session of ' || c_admin_user || ' with the administrator role');

    -- 2. Adding values; a code is never reused; required values are never defaulted
    &emk_api_schema..emk_master_data_api.create_role_type(in_role_code => ' md_test_role ',
        in_name => '  Master data test role ', in_description => NULL, in_sort_order => 99, in_valid_from => TRUNC(SYSDATE));
    SELECT MAX(name || '/' || valid_yn) INTO l_text FROM &emk_api_schema..emk_v_party_role_types WHERE role_code = c_test_role;
    check_result(l_text = 'Master data test role/Y', 'A new role: code upper case, name trimmed, valid from today (' || l_text || ')');
    BEGIN
        &emk_api_schema..emk_master_data_api.create_role_type(in_role_code => 'Md_Test_Role',
            in_name => 'Again', in_description => NULL, in_sort_order => 98, in_valid_from => TRUNC(SYSDATE));
        check_result(FALSE, 'An existing code was created again');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_code_exists, 'An existing code, in other letter case, is refused: never reused (' || SQLCODE || ')');
    END;
    BEGIN
        &emk_api_schema..emk_master_data_api.create_document_type(in_doc_type => c_test_doc_type,
            in_name => 'Master data test document', in_description => NULL, in_sort_order => 99, in_valid_from => NULL);
        check_result(FALSE, 'A document type without a start of validity was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_invalid_argument, 'A missing start of validity is refused, never defaulted (' || SQLCODE || ')');
    END;
    &emk_api_schema..emk_master_data_api.create_document_type(in_doc_type => c_test_doc_type,
        in_name => 'Master data test document', in_description => NULL, in_sort_order => 99, in_valid_from => TRUNC(SYSDATE));

    -- 3. Retiring: a retired value stays where it is used and is no longer offered
    &emk_api_schema..emk_party_api.create_party(in_name => 'Master Data Test Company', in_vat_number => NULL,
        in_country_code => 'DE', in_street => NULL, in_postal_code => NULL, in_city => NULL,
        in_language_code => 'en', in_role_codes => 'SENDER:' || c_test_role, out_party_id => l_company);
    &emk_api_schema..emk_master_data_api.update_role_type(in_role_code => c_test_role,
        in_expected_updated_at => version_of('emk_v_party_role_types', 'role_code', c_test_role),
        in_name => 'Master data test role', in_description => NULL, in_sort_order => 99,
        in_valid_from => TRUNC(SYSDATE) - 1, in_valid_to => TRUNC(SYSDATE) - 1);
    SELECT MAX(valid_yn) INTO l_text FROM &emk_api_schema..emk_v_party_role_types WHERE role_code = c_test_role;
    check_result(l_text = 'N', 'A retired role is no longer offered (valid_yn = ' || l_text || ')');
    SELECT MAX(roles) INTO l_text FROM &emk_api_schema..emk_v_parties WHERE party_id = l_company;
    check_result(l_text = c_test_role || ':SENDER', 'The company keeps the retired role (' || l_text || ')');
    &emk_api_schema..emk_master_data_api.update_document_type(in_doc_type => c_test_doc_type,
        in_expected_updated_at => version_of('emk_v_document_types', 'doc_type', c_test_doc_type),
        in_name => 'Master data test document', in_description => NULL, in_sort_order => 99,
        in_valid_from => TRUNC(SYSDATE) - 1, in_valid_to => TRUNC(SYSDATE) - 1);
    SELECT MAX(valid_yn) INTO l_text FROM &emk_api_schema..emk_v_document_types WHERE doc_type = c_test_doc_type;
    check_result(l_text = 'N', 'A retired document type is no longer offered (valid_yn = ' || l_text || ')');
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_code_list_history
    WHERE  list_name = 'PARTY_ROLE_TYPES' AND code = c_test_role AND changed_by = c_admin_user AND previous_valid_to IS NULL;
    check_result(l_count = 1, 'The history shows the change with the APEX user and the previous end of validity');

    -- 4. Protected codes; claim statuses and types: name and order only
    BEGIN
        &emk_api_schema..emk_master_data_api.update_role_type(in_role_code => 'SENDER',
            in_expected_updated_at => version_of('emk_v_party_role_types', 'role_code', 'SENDER'),
            in_name => 'Sender', in_description => 'Sender of the goods (CMR Art. 6(1)(b), 7)', in_sort_order => 10,
            in_valid_from => DATE '1900-01-01', in_valid_to => TRUNC(SYSDATE) + 30);
        check_result(FALSE, 'A protected role was retired');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_code_protected, 'A protected role cannot be retired, not even later (' || SQLCODE || ')');
    END;
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_log
    WHERE  created_by = c_admin_user AND log_level = 'WARN' AND message LIKE 'Master data change rejected: Role SENDER%';
    check_result(l_count >= 1, 'The attempt to retire a protected role is in the technical log (ASVS V16.3.3)');
    &emk_api_schema..emk_master_data_api.update_role_type(in_role_code => 'SENDER',
        in_expected_updated_at => version_of('emk_v_party_role_types', 'role_code', 'SENDER'),
        in_name => 'Sender (test)', in_description => 'Sender of the goods (CMR Art. 6(1)(b), 7)', in_sort_order => 10,
        in_valid_from => DATE '1900-01-01', in_valid_to => NULL);
    SELECT MAX(name || '/' || protected_yn) INTO l_text FROM &emk_api_schema..emk_v_party_role_types WHERE role_code = 'SENDER';
    check_result(l_text = 'Sender (test)/Y', 'The name of a protected role can change (' || l_text || ')');
    &emk_api_schema..emk_master_data_api.update_claim_status(in_status_code => 'RESOLVED',
        in_expected_updated_at => version_of('emk_v_claim_statuses', 'status_code', 'RESOLVED'),
        in_name => 'Resolved (test)', in_description => NULL, in_sort_order => 50);
    SELECT MAX(name || '/' || final_yn || '/' || valid_yn) INTO l_text FROM &emk_api_schema..emk_v_claim_statuses
    WHERE  status_code = 'RESOLVED';
    check_result(l_text = 'Resolved (test)/Y/Y', 'A claim status: the name changes, final and validity do not (' || l_text || ')');

    -- 5. File types: retire and allow again; the catalog itself is read only
    &emk_api_schema..emk_master_data_api.retire_file_type(in_mime_type => 'image/png',
        in_expected_updated_at => version_of('emk_v_file_types', 'mime_type', 'image/png'), in_valid_to => TRUNC(SYSDATE) - 1);
    SELECT MAX(allowed_yn) INTO l_text FROM &emk_api_schema..emk_v_file_types WHERE mime_type = 'image/png';
    check_result(l_text = 'N', 'A retired file type is not allowed (allowed_yn = ' || l_text || ')');
    &emk_api_schema..emk_master_data_api.allow_file_type(in_mime_type => 'image/png',
        in_expected_updated_at => version_of('emk_v_file_types', 'mime_type', 'image/png'), in_valid_from => TRUNC(SYSDATE));
    SELECT MAX(allowed_yn || '/' || NVL(TO_CHAR(valid_to, 'YYYY-MM-DD'), 'no end') || '/' || extensions)
    INTO   l_text FROM &emk_api_schema..emk_v_file_types WHERE mime_type = 'image/png';
    check_result(l_text = 'Y/no end/png', 'A file type allowed again, with no end; extensions unchanged (' || l_text || ')');

    -- 6. Optimistic locking; no change, no history
    BEGIN
        &emk_api_schema..emk_master_data_api.update_claim_type(in_claim_type => 'DELAY',
            in_expected_updated_at => SYSTIMESTAMP - INTERVAL '1' DAY,
            in_name => 'Delay (test)', in_description => NULL, in_sort_order => 40);
        check_result(FALSE, 'An update with an old version was accepted');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(SQLCODE = c_record_changed, 'An update with an old version is refused (' || SQLCODE || ')');
    END;
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_code_list_history WHERE list_name = 'CLAIM_TYPES';
    FOR r IN (SELECT name, description, sort_order FROM &emk_api_schema..emk_v_claim_types WHERE claim_type = 'DELAY') LOOP
        &emk_api_schema..emk_master_data_api.update_claim_type(in_claim_type => 'DELAY',
            in_expected_updated_at => version_of('emk_v_claim_types', 'claim_type', 'DELAY'),
            in_name => r.name, in_description => r.description, in_sort_order => r.sort_order);
    END LOOP;
    SELECT COUNT(*) - l_count INTO l_count FROM &emk_api_schema..emk_v_code_list_history WHERE list_name = 'CLAIM_TYPES';
    check_result(l_count = 0, 'An update without change writes no history row (' || l_count || ' new)');

    -- 7. Nothing is kept: data rolled back, role removed, session closed
    clean_up;
    SELECT COUNT(*) INTO l_count FROM &emk_api_schema..emk_v_party_role_types WHERE role_code = c_test_role;
    check_result(l_count = 0, 'Every data change was rolled back: no test role is left');
    APEX_SESSION.CREATE_SESSION(p_app_id => &emk_apex_app_id, p_page_id => 1, p_username => c_admin_user);
    check_result(NOT APEX_ACL.HAS_USER_ROLE(p_role_static_id => c_admin_role),
                 'The administrator role of ' || c_admin_user || ' was removed');
    APEX_SESSION.DELETE_SESSION;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0 THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);
    DBMS_OUTPUT.PUT_LINE('Next: run tests/emk_ui/master_data_test_cleanup.sql as EMK_DEV[EMK_API].');
    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(c_test_failed, 'Master data test failed.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <> c_test_failed THEN   -- an unexpected error: leave nothing behind, then stop
            DBMS_OUTPUT.PUT_LINE('ERROR ' || SQLERRM);
            BEGIN
                clean_up;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;   -- report the first error
            END;
        END IF;
        RAISE;
END;
/

SPOOL OFF
EXIT
