-- =============================================================================
-- tests/install_tests.sql
-- Installs (or replaces) the unit test packages TEST_EMK_* of the connected
-- schema: tests/emk_data/ in EMK_DATA, tests/emk_api/ in EMK_API. A test lives
-- in the schema of the objects it tests (M1 plan, open point 1: no extra
-- grants). Refuses PROD: tests change data and never run there. Stops with an
-- error if a test package does not compile.
--
-- Run from the repository root, once per schema (DEV: through the proxy):
--   sql -thin "EMK_DEV[EMK_DATA]@localhost:1521/FREEPDB1" @tests/install_tests.sql
--   sql -thin "EMK_DEV[EMK_API]@localhost:1521/FREEPDB1"  @tests/install_tests.sql
-- Output: logs\tests\install_tests_<schema>_<YYYYMMDD_HH24MISS>.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-16
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

HOST powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'logs\tests' | Out-Null"
SET TERMOUT OFF
COLUMN cfg_log NEW_VALUE emk_log_file
COLUMN cfg_dir NEW_VALUE emk_test_dir
SELECT 'logs\tests\install_tests_' || LOWER(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')) || '_'
       || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log,
       LOWER(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')) AS cfg_dir
FROM   dual;
SET TERMOUT ON
SPOOL &emk_log_file
PROMPT Log of this run: &emk_log_file

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC, PROD): '
@@../scripts/admin/00_config.sql

BEGIN
    IF '&emk_env' = 'PROD' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Unit tests are never installed in PROD. Nothing was changed.');
    END IF;
    IF SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') NOT IN ('&emk_data_schema', '&emk_api_schema') THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect to &emk_data_schema or &emk_api_schema (DEV: EMK_DEV[<schema>]); current schema is '
                                        || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') || '.');
    END IF;
END;
/

PROMPT === Installing the test packages of tests/&emk_test_dir
@@&emk_test_dir/install.sql

PROMPT
PROMPT === Compilation (expected: every TEST_EMK package VALID)
DECLARE
    l_invalid PLS_INTEGER := 0;
BEGIN
    FOR o IN (SELECT object_name, object_type, status
              FROM   user_objects
              WHERE  object_name LIKE 'TEST\_EMK\_%' ESCAPE '\'
              AND    object_type IN ('PACKAGE', 'PACKAGE BODY')
              ORDER  BY object_name, object_type) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(o.object_name, 32) || RPAD(o.object_type, 14) || o.status);
        IF o.status <> 'VALID' THEN
            l_invalid := l_invalid + 1;
        END IF;
    END LOOP;
    IF l_invalid > 0 THEN
        FOR e IN (SELECT name, type, line, position, text
                  FROM   user_errors
                  WHERE  name LIKE 'TEST\_EMK\_%' ESCAPE '\'
                  ORDER  BY name, type, sequence) LOOP
            DBMS_OUTPUT.PUT_LINE('! ' || e.name || ' ' || e.type || ' ' || e.line || ':' || e.position || ' ' || e.text);
        END LOOP;
        RAISE_APPLICATION_ERROR(-20001, l_invalid || ' test package(s) did not compile (see the errors above).');
    END IF;
    DBMS_OUTPUT.PUT_LINE(CHR(10) || 'RESULT: all test packages of &emk_test_dir compiled.');
END;
/

SPOOL OFF
EXIT
