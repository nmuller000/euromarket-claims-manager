-- =============================================================================
-- 09_install_utplsql.sql
-- Installs the utPLSQL test framework into schema &emk_ut3_schema and gives
-- access to &emk_app_schema only. Idempotent: the framework is installed once;
-- owner settings, grants and synonyms are re-applied on every run (needed again
-- after uninstall_admin.sql drops &emk_app_schema).
--
-- Why not the official install_headless.sql:
--   - it creates the owner with a default password published in the utPLSQL
--     documentation (or one typed on the command line, kept in shell history);
--   - it grants the framework to PUBLIC (every database account);
--   - it ends with EXIT.
-- Here the owner is created schema-only (NO AUTHENTICATION): nobody can log in
-- as &emk_ut3_schema, and no password exists. The official install.sql,
-- create_user_grants.sql and create_user_synonyms.sql do the rest.
--
-- Prerequisite: release ZIP extracted so that &emk_utplsql_src/install.sql exists
-- (see docs/setup.md). Separate step, not called by install_admin.sql.
-- Run from the repository root as SYS in FREEPDB1 (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/09_install_utplsql.sql
-- The official scripts write install.log and a temporary params.sql.tmp in the
-- current folder. install.log is moved to logs/. params.sql.tmp could not be
-- deleted from within the session (probably still held by SQLcl): remove it by
-- hand after the run (ignored by Git, not needed).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
SET SQLFORMAT DEFAULT
WHENEVER SQLERROR EXIT FAILURE

@@00_config.sql
@@00_check_context.sql

-- One log per run (logs/install_utplsql_YYYYMMDD_HH24MISS.log)
-- plus the official installer log (logs/install_utplsql_YYYYMMDD_HH24MISS_official.log)
COLUMN log_file      NEW_VALUE emk_log_file      NOPRINT
COLUMN official_file NEW_VALUE emk_official_file NOPRINT
SELECT 'logs/install_utplsql_' || ts || '.log'          AS log_file,
       'logs/install_utplsql_' || ts || '_official.log' AS official_file
FROM   (SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS ts FROM dual);
SPOOL &emk_log_file

PROMPT
PROMPT === 1/4 Owner schema &emk_ut3_schema (schema-only) ===
DECLARE
    l_auth dba_users.authentication_type%TYPE;
BEGIN
    SELECT MAX(authentication_type)
    INTO   l_auth
    FROM   dba_users
    WHERE  username = UPPER('&emk_ut3_schema');

    IF l_auth IS NULL THEN
        EXECUTE IMMEDIATE 'CREATE USER &emk_ut3_schema NO AUTHENTICATION '
                       || 'DEFAULT TABLESPACE &emk_ut3_ts QUOTA UNLIMITED ON &emk_ut3_ts';
        DBMS_OUTPUT.PUT_LINE('Schema &emk_ut3_schema created (no password).');
    ELSIF l_auth <> 'NONE' THEN
        -- Installed earlier with a password (e.g. by install_headless.sql): remove it
        EXECUTE IMMEDIATE 'ALTER USER &emk_ut3_schema NO AUTHENTICATION';
        DBMS_OUTPUT.PUT_LINE('Schema &emk_ut3_schema existed with a password: changed to schema-only.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Schema &emk_ut3_schema already exists (schema-only).');
    END IF;
END;
/

-- Same privileges as the official create_utplsql_owner.sql (v3.2.3); recheck on upgrade
GRANT CREATE SESSION, CREATE SEQUENCE, CREATE PROCEDURE, CREATE TYPE,
      CREATE TABLE, CREATE VIEW, CREATE SYNONYM, ALTER SESSION TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_LOCK   TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_LOB    TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_XMLGEN TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_SQL    TO &emk_ut3_schema;
GRANT EXECUTE ON SYS.DBMS_RANDOM TO &emk_ut3_schema;

PROMPT
PROMPT === 2/4 Framework objects ===
COLUMN next_step NEW_VALUE next_step NOPRINT
SELECT CASE WHEN COUNT(*) = 0 THEN '09a_install_utplsql_objects.sql'
            ELSE '00_noop.sql' END AS next_step
FROM   dba_objects
WHERE  owner = UPPER('&emk_ut3_schema')
AND    object_name = 'UT'
AND    object_type = 'PACKAGE';

@@&next_step

BEGIN
    DBMS_OUTPUT.PUT_LINE('utPLSQL objects are present in &emk_ut3_schema.');
END;
/

PROMPT
PROMPT === 3/4 Access for &emk_app_schema (grants) and public synonyms (names only) ===
-- The official scripts spool their own temporary file: pause this log meanwhile
SPOOL OFF
@&emk_utplsql_src/create_user_grants.sql &emk_ut3_schema &emk_app_schema
@&emk_utplsql_src/create_user_synonyms.sql &emk_ut3_schema PUBLIC
@@09b_reset_session.sql
SPOOL &emk_log_file APPEND

PROMPT
PROMPT === 4/4 Verification ===
-- Recompile only objects left invalid (e.g. after grants were re-applied)
EXEC DBMS_UTILITY.COMPILE_SCHEMA(schema => UPPER('&emk_ut3_schema'), compile_all => FALSE)

DECLARE
    l_failures PLS_INTEGER := 0;
    l_count    PLS_INTEGER;
    l_version  VARCHAR2(100);

    PROCEDURE check_result (p_ok IN BOOLEAN, p_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN p_ok THEN 'PASS  ' ELSE 'FAIL  ' END || p_label);
        IF NOT p_ok THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;
BEGIN
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_ut3_schema') AND authentication_type = 'NONE';
    check_result(l_count = 1, 'Schema &emk_ut3_schema is schema-only (no password)');

    SELECT COUNT(*) INTO l_count FROM dba_objects
    WHERE  owner = UPPER('&emk_ut3_schema') AND status <> 'VALID';
    check_result(l_count = 0, 'No invalid objects in &emk_ut3_schema');

    SELECT COUNT(*) INTO l_count FROM dba_tab_privs
    WHERE  owner = UPPER('&emk_ut3_schema') AND table_name = 'UT'
    AND    grantee = UPPER('&emk_app_schema') AND privilege = 'EXECUTE';
    check_result(l_count = 1, '&emk_app_schema may execute &emk_ut3_schema..UT');

    SELECT COUNT(*) INTO l_count FROM dba_tab_privs
    WHERE  owner = UPPER('&emk_ut3_schema') AND table_name = 'UT' AND grantee = 'PUBLIC';
    check_result(l_count = 0, 'utPLSQL is not granted to PUBLIC');

    SELECT COUNT(*) INTO l_count FROM dba_synonyms
    WHERE  owner = 'PUBLIC' AND synonym_name = 'UT' AND table_owner = UPPER('&emk_ut3_schema');
    check_result(l_count = 1, 'Public synonym UT points to &emk_ut3_schema..UT');

    -- Version read from the source, not by calling UT.VERSION: package UT is
    -- AUTHID CURRENT_USER and must not run as SYS. Functional test: T-M0-06.
    SELECT MAX(REGEXP_SUBSTR(text, 'v\.[0-9.]+[0-9]'))
    INTO   l_version
    FROM   dba_source
    WHERE  owner = UPPER('&emk_ut3_schema')
    AND    name  = 'UT_UTILS'
    AND    type  = 'PACKAGE'
    AND    UPPER(text) LIKE '%GC_VERSION%CONSTANT%';
    check_result(l_version IS NOT NULL, 'utPLSQL version: ' || NVL(l_version, 'not found'));

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0
                                         THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);

    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'utPLSQL verification failed.');
    END IF;
END;
/

SPOOL OFF
