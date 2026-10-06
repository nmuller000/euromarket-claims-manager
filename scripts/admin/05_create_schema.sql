-- =============================================================================
-- 05_create_schema.sql
-- Creates the application schema &emk_app_schema as a schema-only account
-- (no password, no direct logins) and grants its privileges.
-- Called by install_admin.sql (requires 00_config.sql).
-- =============================================================================

DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO   l_count
    FROM   dba_users
    WHERE  username = UPPER('&emk_app_schema');

    IF l_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE USER &emk_app_schema NO AUTHENTICATION'
            || ' DEFAULT TABLESPACE &emk_tablespace'
            || ' TEMPORARY TABLESPACE &emk_temp_ts';
        DBMS_OUTPUT.PUT_LINE('Schema &emk_app_schema created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Schema &emk_app_schema already exists.');
    END IF;
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
