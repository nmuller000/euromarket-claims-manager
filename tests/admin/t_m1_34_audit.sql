-- =============================================================================
-- t_m1_34_audit.sql - Test T-M1-34 (DEV): privileged activity is audited and
-- attributed to the person (ADR-010 section 3).
--   1. As SYS: remember the start time.
--   2. As the developer through the proxy (EMK_DEV[EMK_DATA]): logon, CREATE
--      TABLE, COMMENT, GRANT, REVOKE, DROP TABLE on a test table.
--   3. As SYS: the six actions are in UNIFIED_AUDIT_TRAIL with DBUSERNAME =
--      EMK_DATA and DBPROXY_USERNAME = EMK_DEV.
-- Values from scripts/admin/00_config.sql. Two passwords are asked by SQLcl
-- (developer account, then SYS); none is stored.
--
-- Run from the repository root:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @tests/admin/t_m1_34_audit.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

-- The proxy exists only in DEV (ADR-009)
DEFINE emk_env = DEV
@@../../scripts/admin/00_config.sql
@@../../scripts/admin/00_check_context.sql

SET TERMOUT OFF
COLUMN cfg_start NEW_VALUE emk_t34_start NOPRINT
SELECT TO_CHAR(SYSTIMESTAMP - INTERVAL '1' SECOND, 'YYYY-MM-DD"T"HH24:MI:SS.FF6') AS cfg_start FROM dual;
SET TERMOUT ON
PROMPT === 1. Start time: &emk_t34_start

PROMPT
PROMPT === 2. Developer session through the proxy &emk_dev_user[&emk_data_schema]
PROMPT Password of &emk_dev_user (from the password manager):
CONNECT &emk_dev_user[&emk_data_schema]@//&emk_db_address/&emk_pdb
CREATE TABLE emk_t34_audit (id NUMBER);
COMMENT ON TABLE emk_t34_audit IS 'T-M1-34 audit test, dropped at the end';
GRANT SELECT ON emk_t34_audit TO &emk_api_schema;
REVOKE SELECT ON emk_t34_audit FROM &emk_api_schema;
DROP TABLE emk_t34_audit PURGE;
PROMPT Actions done.

PROMPT
PROMPT === 3. Back as SYS: audit records of the test
PROMPT Password of SYS:
CONNECT sys@//&emk_db_address/&emk_pdb AS SYSDBA
SET SERVEROUTPUT ON

COLUMN action_name      FORMAT A14
COLUMN dbusername       FORMAT A10
COLUMN dbproxy_username FORMAT A10
COLUMN object_name      FORMAT A16
COLUMN unified_audit_policies FORMAT A20
SET FEEDBACK ON
SELECT event_timestamp, action_name, dbusername, dbproxy_username, object_name, unified_audit_policies
FROM   unified_audit_trail
WHERE  event_timestamp >= TO_TIMESTAMP('&emk_t34_start', 'YYYY-MM-DD"T"HH24:MI:SS.FF6')
AND    dbusername = UPPER('&emk_data_schema')
ORDER  BY event_timestamp;

DECLARE
    l_found PLS_INTEGER;
BEGIN
    SELECT COUNT(DISTINCT action_name)
    INTO   l_found
    FROM   unified_audit_trail
    WHERE  event_timestamp >= TO_TIMESTAMP('&emk_t34_start', 'YYYY-MM-DD"T"HH24:MI:SS.FF6')
    AND    dbusername       = UPPER('&emk_data_schema')
    AND    dbproxy_username = UPPER('&emk_dev_user')
    AND    action_name IN ('LOGON', 'CREATE TABLE', 'COMMENT', 'GRANT', 'REVOKE', 'DROP TABLE');

    DBMS_OUTPUT.PUT_LINE(CASE WHEN l_found = 6
                              THEN 'PASS  T-M1-34: 6/6 actions audited and attributed to &emk_dev_user'
                              ELSE 'FAIL  T-M1-34: ' || l_found || '/6 actions found' END);
END;
/
