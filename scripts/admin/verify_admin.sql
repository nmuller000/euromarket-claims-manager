-- =============================================================================
-- verify_admin.sql
-- Read-only checks of the admin layer (M0 tests T-M0-02 and T-M0-03; M1 test
-- T-M1-23 for ADR-007). Prints PASS/FAIL per check and stops with an error if
-- any check fails.
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
    -- Tablespaces
    SELECT COUNT(*) INTO l_count FROM dba_tablespaces
    WHERE  tablespace_name IN (UPPER('&emk_tablespace'), UPPER('&emk_int_tablespace')) AND status = 'ONLINE';
    check_result(l_count = 2, 'Tablespaces &emk_tablespace and &emk_int_tablespace exist and are online');

    -- Roles
    SELECT COUNT(*) INTO l_count FROM dba_roles
    WHERE  role IN (UPPER('&emk_owner_role'), UPPER('&emk_dev_role'), UPPER('&emk_ro_role'));
    check_result(l_count = 3, 'Roles &emk_owner_role, &emk_dev_role, &emk_ro_role exist');

    -- Schemas: schema-only, correct tablespace, owner role and developer role
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_app_schema') AND authentication_type = 'NONE'
    AND    default_tablespace = UPPER('&emk_tablespace');
    check_result(l_count = 1, 'Schema &emk_app_schema is schema-only with default tablespace &emk_tablespace');

    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_int_schema') AND authentication_type = 'NONE'
    AND    default_tablespace = UPPER('&emk_int_tablespace');
    check_result(l_count = 1, 'Schema &emk_int_schema is schema-only with default tablespace &emk_int_tablespace');

    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'))
    AND    granted_role IN (UPPER('&emk_owner_role'), UPPER('&emk_dev_role'));
    check_result(l_count = 4, 'Schemas &emk_app_schema and &emk_int_schema have &emk_owner_role and &emk_dev_role');

    -- Developer account: CREATE SESSION only, no roles, CIS profile (ADR-007)
    SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = UPPER('&emk_dev_user');
    check_result(l_count = 0, 'Account &emk_dev_user holds no roles');

    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_dev_user') AND privilege <> 'CREATE SESSION';
    check_result(l_count = 0, 'Account &emk_dev_user has no system privilege other than CREATE SESSION');

    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_dev_user') AND privilege = 'CREATE SESSION';
    check_result(l_count = 1, 'Account &emk_dev_user has CREATE SESSION (direct)');

    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_dev_user') AND profile = UPPER('&emk_dev_profile');
    check_result(l_count = 1, 'Account &emk_dev_user uses profile &emk_dev_profile');

    -- Service account keeps the DEFAULT profile (expiry or lockout would stop ORDS)
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = 'ORDS_PUBLIC_USER' AND profile = 'DEFAULT';
    check_result(l_count = 1, 'Service account ORDS_PUBLIC_USER keeps profile DEFAULT');

    -- Least privilege: no default roles
    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'), UPPER('&emk_dev_user'))
    AND    granted_role IN ('DBA', 'CONNECT', 'RESOURCE', 'DB_DEVELOPER_ROLE');
    check_result(l_count = 0, 'No DBA, CONNECT, RESOURCE or DB_DEVELOPER_ROLE for the project accounts');

    -- Proxies
    SELECT COUNT(*) INTO l_count FROM proxy_users
    WHERE  proxy = UPPER('&emk_dev_user')
    AND    client IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'));
    check_result(l_count = 2, 'Proxy &emk_dev_user -> &emk_app_schema and &emk_int_schema exist');

    -- Debugger ACL (jdwp) for the proxy schemas, local machine only
    SELECT COUNT(*) INTO l_count FROM dba_host_aces
    WHERE  UPPER(privilege) = 'JDWP'
    AND    UPPER(principal) IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'))
    AND    LOWER(host) IN ('localhost', '127.0.0.1');
    check_result(l_count = 4, 'ACL jdwp on localhost and 127.0.0.1 for &emk_app_schema and &emk_int_schema');

    SELECT COUNT(*) INTO l_count FROM dba_host_aces
    WHERE  UPPER(principal) IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'), UPPER('&emk_dev_user'))
    AND    LOWER(host) NOT IN ('localhost', '127.0.0.1');
    check_result(l_count = 0, 'No network ACL for the project accounts outside the local machine');

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
