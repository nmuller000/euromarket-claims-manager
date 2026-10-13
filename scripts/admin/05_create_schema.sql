-- =============================================================================
-- 05_create_schema.sql
-- Creates the schema-only accounts (no password, no direct logins) and grants
-- their privileges:
--   &emk_app_schema  single-schema layout of M1a steps 0-6 (DEV only; retired in M.4)
-- The separated schemas, including &emk_int_schema, are created by
-- 11_create_separated_schemas.sql (ADR-008).
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

DECLARE
    PROCEDURE create_schema (p_name IN VARCHAR2, p_tablespace IN VARCHAR2) IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_users
        WHERE  username = UPPER(p_name);

        IF l_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE USER ' || p_name || ' NO AUTHENTICATION'
                || ' DEFAULT TABLESPACE ' || p_tablespace
                || ' TEMPORARY TABLESPACE &emk_temp_ts';
            DBMS_OUTPUT.PUT_LINE('Schema ' || p_name || ' created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Schema ' || p_name || ' already exists.');
        END IF;
    END create_schema;
BEGIN
    create_schema('&emk_app_schema', '&emk_tablespace');
END;
/

-- Kept in the desired state on every run
ALTER USER &emk_app_schema
    DEFAULT TABLESPACE &emk_tablespace
    QUOTA UNLIMITED ON &emk_tablespace;

GRANT &emk_owner_role TO &emk_app_schema;

-- Direct grants: privileges used inside definer's-rights PL/SQL
-- (roles are not active there)
GRANT CREATE JOB          TO &emk_app_schema;
GRANT CREATE MINING MODEL TO &emk_app_schema;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Schema &emk_app_schema: quota and privileges set.');
END;
/
