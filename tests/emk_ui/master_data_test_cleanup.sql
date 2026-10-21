-- =============================================================================
-- tests/emk_ui/master_data_test_cleanup.sql
-- Second part of the master data test (T-M1-44): runs as EMK_API, the owner
-- of the technical log, right after tests/emk_ui/master_data_test.sql.
--   1. Deletes the log entries of the two test users of that script (its
--      refusals are committed by EMK_LOG_PKG and EMK_UI cannot delete them),
--      the same rule as the utPLSQL suites: only entries the test caused.
--   2. Checks that the run left nothing behind: no test value, no test
--      company, the protected role, the claim status and the file type as
--      before.
-- Refuses PROD.
--
-- Run from the repository root (DEV: through the proxy of EMK_API):
--   sql -thin "EMK_DEV[EMK_API]@localhost:1521/FREEPDB1" @tests/emk_ui/master_data_test_cleanup.sql
-- Output: logs\tests\master_data_test_cleanup_<YYYYMMDD_HH24MISS>.log
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
SELECT 'logs\tests\master_data_test_cleanup_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log FROM dual;
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
    IF USER <> UPPER('&emk_api_schema') THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect as the owner of the log: EMK_DEV[&emk_api_schema], not ' || USER || '.');
    END IF;
END;
/

PROMPT === Master data test: log entries of the test users, and nothing left behind
DECLARE
    -- The test users of master_data_test.sql: names used by no real user
    c_plain_user CONSTANT VARCHAR2(30 CHAR) := 'MASTER_DATA_TEST_USER';
    c_admin_user CONSTANT VARCHAR2(30 CHAR) := 'MASTER_DATA_TEST_ADMIN';
    l_failures PLS_INTEGER := 0;
    l_count    PLS_INTEGER;
    l_text     VARCHAR2(4000 CHAR);

    PROCEDURE check_result (in_ok IN BOOLEAN, in_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN in_ok THEN 'PASS  ' ELSE 'FAIL  ' END || in_label);
        IF NOT in_ok OR in_ok IS NULL THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;
BEGIN
    -- 1. Log entries the test caused: the refusals of the two test users
    DELETE FROM emk_log
    WHERE  created_by IN (c_plain_user, c_admin_user)
    AND    log_level = 'WARN'
    AND    (message = 'Role check refused' OR message LIKE 'Master data change rejected: %');
    l_count := SQL%ROWCOUNT;
    COMMIT;
    check_result(l_count >= 2, 'Log entries of the test users deleted (' || l_count || ')');
    SELECT COUNT(*) INTO l_count FROM emk_log WHERE created_by IN (c_plain_user, c_admin_user);
    check_result(l_count = 0, 'No log entry of the test users is left (' || l_count || ')');

    -- 2. Nothing else left behind
    SELECT COUNT(*) INTO l_count FROM emk_data.emk_party_role_types WHERE role_code = 'MD_TEST_ROLE';
    check_result(l_count = 0, 'No test role');
    SELECT COUNT(*) INTO l_count FROM emk_data.emk_document_types WHERE doc_type = 'MD_TEST_DOC';
    check_result(l_count = 0, 'No test document type');
    SELECT COUNT(*) INTO l_count FROM emk_data.emk_parties WHERE name = 'Master Data Test Company';
    check_result(l_count = 0, 'No test company');
    SELECT name || '/' || NVL(TO_CHAR(valid_to, 'YYYY-MM-DD'), 'no end') INTO l_text
    FROM   emk_data.emk_party_role_types WHERE role_code = 'SHIPPER';
    check_result(l_text = 'Shipper/no end', 'SHIPPER as before (' || l_text || ')');
    SELECT name INTO l_text FROM emk_data.emk_claim_statuses WHERE status_code = 'RESOLVED';
    check_result(l_text NOT LIKE '%(test)%', 'Claim status RESOLVED as before (' || l_text || ')');
    SELECT TO_CHAR(valid_from, 'YYYY-MM-DD') || '/' || NVL(TO_CHAR(valid_to, 'YYYY-MM-DD'), 'no end') INTO l_text
    FROM   emk_data.emk_file_types WHERE mime_type = 'image/png';
    check_result(l_text = '1900-01-01/no end', 'File type image/png as before (' || l_text || ')');
    SELECT COUNT(*) INTO l_count FROM emk_data.emk_party_role_types_jn WHERE jn_by IN (c_plain_user, c_admin_user);
    check_result(l_count = 0, 'No journal row of the test users (the changes were rolled back)');

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0 THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);
    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20999, 'Master data test cleanup found something left behind.');
    END IF;
END;
/

SPOOL OFF
EXIT
