-- =============================================================================
-- 05_create_schema.sql
-- Creates the schema-only accounts (no password, no direct logins) and grants
-- their privileges:
--   &emk_app_schema  application schema: operational data and business APIs
--   &emk_int_schema  integration schema: inbound data and batch jobs (ADR-007)
-- Called by install_admin.sql (requires 00_config.sql).
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
    create_schema('&emk_int_schema', '&emk_int_tablespace');
END;
/

-- Kept in the desired state on every run
ALTER USER &emk_app_schema
    DEFAULT TABLESPACE &emk_tablespace
    QUOTA UNLIMITED ON &emk_tablespace;

ALTER USER &emk_int_schema
    DEFAULT TABLESPACE &emk_int_tablespace
    QUOTA UNLIMITED ON &emk_int_tablespace;

GRANT &emk_owner_role TO &emk_app_schema;
GRANT &emk_owner_role TO &emk_int_schema;

-- Direct grants: privileges used inside definer's-rights PL/SQL
-- (roles are not active there)
GRANT CREATE JOB          TO &emk_app_schema;
GRANT CREATE MINING MODEL TO &emk_app_schema;
GRANT CREATE JOB          TO &emk_int_schema;    -- job per inbound batch (ADR-007)

BEGIN
    DBMS_OUTPUT.PUT_LINE('Schemas &emk_app_schema and &emk_int_schema: quota and privileges set.');
END;
/
