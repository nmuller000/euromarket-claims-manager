-- =============================================================================
-- verify_admin.sql
-- Read-only checks of the admin layer (M0 tests T-M0-02 and T-M0-03).
-- Prints PASS/FAIL per check and stops with an error if any check fails.
-- Called by install_admin.sql, or standalone:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/verify_admin.sql
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
@@00_config.sql

DECLARE
    l_failures PLS_INTEGER := 0;
    l_count    PLS_INTEGER;
    l_text     VARCHAR2(4000);

    PROCEDURE check_result (p_ok IN BOOLEAN, p_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN p_ok THEN 'PASS  ' ELSE 'FAIL  ' END || p_label);
        IF NOT p_ok THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;
BEGIN
    -- Tablespace
    SELECT COUNT(*) INTO l_count FROM dba_tablespaces
    WHERE  tablespace_name = UPPER('&emk_tablespace') AND status = 'ONLINE';
    check_result(l_count = 1, 'Tablespace &emk_tablespace exists and is online');

    -- Roles
    SELECT COUNT(*) INTO l_count FROM dba_roles
    WHERE  role IN (UPPER('&emk_owner_role'), UPPER('&emk_dev_role'), UPPER('&emk_ro_role'));
    check_result(l_count = 3, 'Roles &emk_owner_role, &emk_dev_role, &emk_ro_role exist');

    -- Application schema: schema-only, correct tablespace, owner role
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_app_schema')
    AND    authentication_type = 'NONE'
    AND    default_tablespace = UPPER('&emk_tablespace');
    check_result(l_count = 1, 'Schema &emk_app_schema is schema-only with default tablespace &emk_tablespace');

    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee = UPPER('&emk_app_schema') AND granted_role = UPPER('&emk_owner_role');
    check_result(l_count = 1, 'Schema &emk_app_schema has role &emk_owner_role');

    -- Developer account and roles
    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee = UPPER('&emk_dev_user')
    AND    granted_role IN ('DB_DEVELOPER_ROLE', UPPER('&emk_dev_role'));
    check_result(l_count = 2, 'Account &emk_dev_user has DB_DEVELOPER_ROLE and &emk_dev_role');

    -- Least privilege: no default roles
    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee IN (UPPER('&emk_app_schema'), UPPER('&emk_dev_user'))
    AND    granted_role IN ('DBA', 'CONNECT', 'RESOURCE');
    check_result(l_count = 0, 'No DBA, CONNECT or RESOURCE for &emk_app_schema and &emk_dev_user');

    -- Proxy
    SELECT COUNT(*) INTO l_count FROM proxy_users
    WHERE  proxy = UPPER('&emk_dev_user') AND client = UPPER('&emk_app_schema');
    check_result(l_count = 1, 'Proxy &emk_dev_user -> &emk_app_schema exists');

    -- APEX workspace and its primary schema
    SELECT COUNT(*) INTO l_count FROM apex_workspaces
    WHERE  workspace = UPPER('&emk_workspace');
    check_result(l_count = 1, 'Workspace &emk_workspace exists');

    IF l_count = 1 THEN
        BEGIN
            l_text := APEX_INSTANCE_ADMIN.GET_SCHEMAS(p_workspace => '&emk_workspace');
        EXCEPTION
            WHEN OTHERS THEN
                l_text := 'not readable: ' || SQLERRM;
        END;
        -- Separator-independent match of the schema name as a whole word
        check_result(REGEXP_LIKE(UPPER(l_text),
                                 '(^|[^A-Z0-9_$#])' || UPPER('&emk_app_schema') || '([^A-Z0-9_$#]|$)'),
                     'Workspace &emk_workspace uses schema &emk_app_schema (' || l_text || ')');
    END IF;

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0
                                         THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);

    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Admin verification failed.');
    END IF;
END;
/
