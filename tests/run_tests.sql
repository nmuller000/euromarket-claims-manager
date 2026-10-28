-- =============================================================================
-- tests/run_tests.sql
-- Runs every unit test suite of the connected schema with utPLSQL (ut.run,
-- documentation reporter). utPLSQL rolls back every change of the tests at
-- the end; suites that write committed log entries delete them themselves.
-- Refuses PROD.
--
-- Run from the repository root, once per schema (DEV: through the proxy):
--   sql -thin "EMK_DEV[EMK_DATA]@localhost:1521/FREEPDB1" @tests/run_tests.sql
--   sql -thin "EMK_DEV[EMK_API]@localhost:1521/FREEPDB1"  @tests/run_tests.sql
-- Output: logs\tests\run_tests_<schema>_<YYYYMMDD_HH24MISS>.log
-- Expected last line of the report: "<n> tests, 0 failed, 0 errored, ..."
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
SELECT 'logs\tests\run_tests_' || LOWER(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')) || '_'
       || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log
FROM   dual;
SET TERMOUT ON
SPOOL &emk_log_file
PROMPT Log of this run: &emk_log_file

-- PROD is not offered (tests never run there); the check below still refuses it.
ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST or ACC): '
@@../scripts/admin/00_config.sql

BEGIN
    IF '&emk_env' = 'PROD' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Unit tests never run in PROD.');
    END IF;
    IF SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') NOT IN ('&emk_data_schema', '&emk_api_schema') THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect to &emk_data_schema or &emk_api_schema (DEV: EMK_DEV[<schema>]); current schema is '
                                        || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') || '.');
    END IF;
END;
/

PROMPT === Unit tests of the connected schema (utPLSQL)
BEGIN
    ut.run();
END;
/

SPOOL OFF
EXIT
