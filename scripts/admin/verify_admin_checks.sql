-- =============================================================================
-- verify_admin_checks.sql
-- The checks of verify_admin.sql (see there): read-only, PASS/FAIL per check,
-- stops with an error if any check fails. A sub-script without EXIT, called by
-- verify_admin.sql (standalone run) and by install_admin.sql (after an install).
-- Requires 00_config.sql.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

DECLARE
    l_failures PLS_INTEGER := 0;
    l_count    PLS_INTEGER;
    l_text     VARCHAR2(4000);
    l_dev      CONSTANT BOOLEAN := '&emk_dev_access' = 'Y';

    PROCEDURE check_result (p_ok IN BOOLEAN, p_label IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(CASE WHEN p_ok THEN 'PASS  ' ELSE 'FAIL  ' END || p_label);
        IF NOT p_ok THEN
            l_failures := l_failures + 1;
        END IF;
    END check_result;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Environment &emk_env, PDB &emk_pdb, developer access &emk_dev_access');

    -- Keystore (ADR-011)
    SELECT COUNT(*) INTO l_count FROM v$encryption_wallet WHERE status = 'OPEN';
    check_result(l_count > 0, 'TDE keystore is open');

    -- Tablespaces: encrypted (T-M1-35) and in the project data folder (D-53)
    SELECT COUNT(*) INTO l_count FROM dba_tablespaces
    WHERE  tablespace_name IN (UPPER('&emk_data_ts'), UPPER('&emk_int_ts'))
    AND    status = 'ONLINE' AND encrypted = 'YES';
    check_result(l_count = 2, 'Tablespaces &emk_data_ts and &emk_int_ts exist, are online and encrypted (T-M1-35)');

    SELECT COUNT(*) INTO l_count FROM v$encrypted_tablespaces e JOIN v$tablespace t
           ON t.ts# = e.ts# AND t.con_id = e.con_id
    WHERE  t.name IN (UPPER('&emk_data_ts'), UPPER('&emk_int_ts')) AND e.encryptionalg = UPPER('&emk_tde_algorithm');
    check_result(l_count = 2, 'Tablespaces &emk_data_ts and &emk_int_ts use &emk_tde_algorithm');

    SELECT COUNT(*) INTO l_count FROM dba_data_files
    WHERE  tablespace_name IN (UPPER('&emk_data_ts'), UPPER('&emk_int_ts'))
    AND    UPPER(file_name) NOT LIKE UPPER('&emk_datafile_dir\%');
    check_result(l_count = 0, 'Data files of &emk_data_ts and &emk_int_ts are in &emk_datafile_dir, apart from Oracle''s files');

    -- Roles
    SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role IN (UPPER('&emk_owner_role'), UPPER('&emk_ro_role'));
    check_result(l_count = 2, 'Roles &emk_owner_role and &emk_ro_role exist');

    SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = UPPER('&emk_dev_role');
    check_result((l_dev AND l_count = 1) OR (NOT l_dev AND l_count = 0),
                 'Role &emk_dev_role exists only in DEV');

    -- Separated schemas (ADR-008): schema-only, default tablespaces
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  authentication_type = 'NONE'
    AND   (   (username = UPPER('&emk_data_schema') AND default_tablespace = UPPER('&emk_data_ts'))
           OR (username = UPPER('&emk_api_schema')  AND default_tablespace = UPPER('&emk_data_ts'))
           OR (username = UPPER('&emk_ui_schema')   AND default_tablespace = UPPER('&emk_data_ts'))
           OR (username = UPPER('&emk_int_schema')  AND default_tablespace = UPPER('&emk_int_ts')));
    check_result(l_count = 4, 'Schemas &emk_data_schema, &emk_api_schema, &emk_ui_schema, &emk_int_schema are schema-only with their tablespaces');

    SELECT COUNT(*) INTO l_count FROM dba_objects WHERE owner = UPPER('&emk_ui_schema');
    check_result(l_count = 0, 'Schema &emk_ui_schema owns no objects');

    SELECT COUNT(*) INTO l_count FROM dba_ts_quotas
    WHERE  username = UPPER('&emk_ui_schema');
    check_result(l_count = 0, 'Schema &emk_ui_schema has no tablespace quota');

    -- Roles of the separated schemas: owner and developer role in DEV only
    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_int_schema'))
    AND    granted_role IN (UPPER('&emk_owner_role'), UPPER('&emk_dev_role'));
    check_result((l_dev AND l_count = 6) OR (NOT l_dev AND l_count = 0),
                 'Owner and developer roles on the separated schemas only in DEV (found ' || l_count || ')');

    SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = UPPER('&emk_ui_schema');
    check_result(l_count = 0, 'Schema &emk_ui_schema holds no roles');

    -- No direct system privileges for the separated schemas (only EMK_DEPLOY creates
    -- objects); EMK_INT keeps CREATE JOB for its batch jobs (ADR-007); in DEV,
    -- EMK_UI has CREATE SESSION for its proxy session (06_create_dev_user.sql)
    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'), UPPER('&emk_int_schema'))
    AND    NOT (grantee = UPPER('&emk_int_schema') AND privilege = 'CREATE JOB')
    AND    NOT (grantee = UPPER('&emk_ui_schema')  AND privilege = 'CREATE SESSION');
    check_result(l_count = 0, 'Separated schemas have no direct system privileges (except CREATE JOB of &emk_int_schema and CREATE SESSION of &emk_ui_schema)');

    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_ui_schema') AND privilege = 'CREATE SESSION';
    check_result((l_dev AND l_count = 1) OR (NOT l_dev AND l_count = 0),
                 'Schema &emk_ui_schema has CREATE SESSION only in DEV (proxy session)');

    -- No project object is granted to PUBLIC (every account of the database)
    SELECT COUNT(*) INTO l_count FROM dba_tab_privs
    WHERE  grantee = 'PUBLIC'
    AND    owner IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'),
                     UPPER('&emk_int_schema'));
    check_result(l_count = 0, 'No object of the project schemas is granted to PUBLIC');

    -- No synonyms in the project (ADR-008)
    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_owner_role') AND privilege = 'CREATE SYNONYM';
    check_result(l_count = 0, 'Role &emk_owner_role has no CREATE SYNONYM (schema-qualified names, ADR-008)');

    -- Deployment account (ADR-008)
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = UPPER('&emk_deploy_user') AND authentication_type = 'PASSWORD'
    AND    profile = UPPER('&emk_deploy_profile');
    check_result(l_count = 1, 'Account &emk_deploy_user exists with profile &emk_deploy_profile');

    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_deploy_user') AND privilege NOT IN ('CREATE SESSION', 'CREATE TABLE');
    check_result(l_count = 0, 'Account &emk_deploy_user has no system privilege other than CREATE SESSION and CREATE TABLE');

    SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = UPPER('&emk_deploy_user');
    check_result(l_count = 0, 'Account &emk_deploy_user holds no roles');

    SELECT COUNT(*) INTO l_count FROM dba_schema_privs
    WHERE  grantee = UPPER('&emk_deploy_user')
    AND    schema IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_int_schema'));
    check_result(l_count = 87, 'Account &emk_deploy_user has the 29 deployment privileges on each of &emk_data_schema, &emk_api_schema, &emk_int_schema (' || l_count || '/87)');

    SELECT COUNT(*) INTO l_count FROM dba_schema_privs
    WHERE  grantee = UPPER('&emk_deploy_user')
    AND    schema NOT IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_int_schema'));
    check_result(l_count = 0, 'Account &emk_deploy_user has no schema privilege outside the project schemas');

    -- Developer account and proxies: DEV only (ADR-009)
    SELECT COUNT(*) INTO l_count FROM proxy_users
    WHERE  proxy = UPPER('&emk_dev_user')
    AND    client IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'), UPPER('&emk_int_schema'));
    check_result((l_dev AND l_count = 4) OR (NOT l_dev AND l_count = 0),
                 'Proxies &emk_dev_user -> &emk_data_schema, &emk_api_schema, &emk_ui_schema, &emk_int_schema only in DEV');

    IF l_dev THEN
        SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = UPPER('&emk_dev_user');
        check_result(l_count = 0, 'Account &emk_dev_user holds no roles');

        SELECT COUNT(*) INTO l_count FROM dba_sys_privs
        WHERE  grantee = UPPER('&emk_dev_user') AND privilege <> 'CREATE SESSION';
        check_result(l_count = 0, 'Account &emk_dev_user has no system privilege other than CREATE SESSION');

        SELECT COUNT(*) INTO l_count FROM dba_users
        WHERE  username = UPPER('&emk_dev_user') AND profile = UPPER('&emk_dev_profile');
        check_result(l_count = 1, 'Account &emk_dev_user uses profile &emk_dev_profile');
    END IF;

    -- Service account keeps the DEFAULT profile (expiry or lockout would stop ORDS)
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = 'ORDS_PUBLIC_USER' AND profile = 'DEFAULT';
    check_result(l_count = 1, 'Service account ORDS_PUBLIC_USER keeps profile DEFAULT');

    -- Least privilege: no default roles for any project account
    SELECT COUNT(*) INTO l_count FROM dba_role_privs
    WHERE  grantee IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'),
                       UPPER('&emk_int_schema'), UPPER('&emk_deploy_user'), UPPER('&emk_dev_user'))
    AND    granted_role IN ('DBA', 'CONNECT', 'RESOURCE', 'DB_DEVELOPER_ROLE');
    check_result(l_count = 0, 'No DBA, CONNECT, RESOURCE or DB_DEVELOPER_ROLE for the project accounts');

    -- Debugger ACL (jdwp): DEV only, local machine only
    SELECT COUNT(*) INTO l_count FROM dba_host_aces
    WHERE  UPPER(privilege) = 'JDWP'
    AND    UPPER(principal) IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_int_schema'))
    AND    LOWER(host) IN ('localhost', '127.0.0.1');
    check_result((l_dev AND l_count = 6) OR (NOT l_dev AND l_count = 0),
                 'ACL jdwp for the separated schemas only in DEV, local machine only');

    SELECT COUNT(*) INTO l_count FROM dba_host_aces
    WHERE  UPPER(principal) IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'),
                                UPPER('&emk_int_schema'), UPPER('&emk_deploy_user'), UPPER('&emk_dev_user'))
    AND    LOWER(host) NOT IN ('localhost', '127.0.0.1');
    check_result(l_count = 0, 'No network ACL for the project accounts outside the local machine');

    -- Database auditing (ADR-010 section 3): 3 policies enabled for the 5 audited accounts
    SELECT COUNT(*) INTO l_count FROM audit_unified_enabled_policies
    WHERE  policy_name IN (UPPER('&emk_aud_ddl'), UPPER('&emk_aud_grants'), UPPER('&emk_aud_sessions'))
    AND    entity_name IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'),
                           UPPER('&emk_int_schema'), UPPER('&emk_deploy_user'));
    check_result(l_count = 15, 'Audit policies &emk_aud_ddl, &emk_aud_grants, &emk_aud_sessions enabled for &emk_audited_users (' || l_count || '/15)');

    SELECT COUNT(*) INTO l_count FROM audit_unified_enabled_policies
    WHERE  policy_name = UPPER('&emk_aud_deploy_dml') AND entity_name = UPPER('&emk_deploy_user');
    check_result(l_count = 1, 'Audit policy &emk_aud_deploy_dml enabled for &emk_deploy_user (data changes of the deployment account)');

    -- ORDS: project schemas are not REST-enabled (AutoREST would publish tables over HTTP)
    BEGIN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM ords_metadata.ords_schemas '
            || 'WHERE parsing_schema IN (:d, :a, :u, :i) AND status = ''ENABLED'''
            INTO l_count
            USING UPPER('&emk_data_schema'), UPPER('&emk_api_schema'), UPPER('&emk_ui_schema'),
                  UPPER('&emk_int_schema');
        check_result(l_count = 0, 'No project schema is REST-enabled in ORDS');
    EXCEPTION
        WHEN OTHERS THEN
            check_result(FALSE, 'ORDS REST status not readable: ' || SQLERRM);
    END;

    -- APEX workspace and the parsing schema of the application (ADR-008)
    SELECT COUNT(*) INTO l_count FROM apex_workspaces WHERE workspace = UPPER('&emk_workspace');
    check_result(l_count = 1, 'Workspace &emk_workspace exists');

    IF l_count = 1 THEN
        BEGIN
            l_text := APEX_INSTANCE_ADMIN.GET_SCHEMAS(p_workspace => '&emk_workspace');
        EXCEPTION
            WHEN OTHERS THEN
                l_text := 'not readable: ' || SQLERRM;
        END;
        check_result(REGEXP_LIKE(UPPER(l_text),
                                 '(^|[^A-Z0-9_$#])' || UPPER('&emk_ui_schema') || '([^A-Z0-9_$#]|$)'),
                     'Workspace &emk_workspace uses schema &emk_ui_schema (' || l_text || ')');
    END IF;

    -- The first schema of the workspace cannot be changed later (07_create_workspace.sql),
    -- and every application parses as the connect user (ADR-008)
    SELECT COUNT(*) INTO l_count FROM apex_workspace_schemas
    WHERE  workspace_name = UPPER('&emk_workspace') AND first_schema_provisioned = UPPER('&emk_ui_schema');
    check_result(l_count > 0, 'Workspace &emk_workspace was created with first schema &emk_ui_schema');

    SELECT COUNT(*) INTO l_count FROM apex_applications
    WHERE  workspace = UPPER('&emk_workspace') AND owner <> UPPER('&emk_ui_schema');
    check_result(l_count = 0, 'Every application of &emk_workspace parses as &emk_ui_schema (' || l_count || ' other)');

    DBMS_OUTPUT.PUT_LINE(CHR(10) || CASE WHEN l_failures = 0
                                         THEN 'RESULT: all checks passed'
                                         ELSE 'RESULT: ' || l_failures || ' check(s) failed' END);

    IF l_failures > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Admin verification failed.');
    END IF;
END;
/
