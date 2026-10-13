-- =============================================================================
-- uninstall_admin.sql
-- Removes everything created by install_admin.sql in the environment asked
-- first: audit policies, APEX workspace, network ACL entries, accounts (with
-- ALL their objects), roles and tablespaces (with their data files). Requires
-- typing YES. Safe to run when objects are already gone. The personal account
-- DEV_USER, the Oracle-supplied profile, UT3 (utPLSQL) and the TDE keystore are
-- not touched. The data folder itself stays (empty).
--
-- Close any session connected as a project account (VS Code, SQLcl) first.
-- Run from the repository root as SYS in the PDB of the environment, e.g. DEV:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/uninstall_admin.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC or PROD): '

@@admin/00_config.sql
@@admin/00_check_context.sql

PROMPT
PROMPT This removes in &emk_env (&emk_pdb): audit policies &emk_aud_ddl, &emk_aud_grants, &emk_aud_sessions, &emk_aud_deploy_dml;
PROMPT workspace &emk_workspace; network ACL entries; accounts &emk_deploy_user, &emk_dev_user,
PROMPT &emk_ui_schema, &emk_api_schema, &emk_data_schema, &emk_int_schema, &emk_app_schema (with ALL
PROMPT their objects); roles &emk_owner_role, &emk_dev_role, &emk_ro_role; tablespaces &emk_data_ts,
PROMPT &emk_int_ts, &emk_tablespace, &emk_int_tablespace including their data files.
ACCEPT emk_confirm CHAR PROMPT 'Type YES to continue: '

BEGIN
    IF UPPER('&emk_confirm') <> 'YES' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cancelled. Nothing was removed.');
    END IF;
END;
/

-- One log per run (logs/uninstall_admin_<ENV>_YYYYMMDD_HH24MISS.log), so earlier runs are kept
SET TERMOUT OFF
COLUMN log_file NEW_VALUE emk_log_file NOPRINT
SELECT 'logs/uninstall_admin_' || '&emk_env' || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS log_file FROM dual;
SET TERMOUT ON
SPOOL &emk_log_file

DECLARE
    l_count PLS_INTEGER;

    PROCEDURE drop_policy (p_name IN VARCHAR2, p_users IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO l_count FROM audit_unified_enabled_policies WHERE policy_name = UPPER(p_name);
        IF l_count > 0 THEN
            EXECUTE IMMEDIATE 'NOAUDIT POLICY ' || p_name || ' BY ' || p_users;
        END IF;
        SELECT COUNT(*) INTO l_count FROM audit_unified_policies WHERE policy_name = UPPER(p_name);
        IF l_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP AUDIT POLICY ' || p_name;
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' does not exist.');
        END IF;
    END drop_policy;

    PROCEDURE drop_user (p_user IN VARCHAR2) IS
        e_user_connected EXCEPTION;          -- ORA-01940: cannot drop a user that is currently connected
        PRAGMA EXCEPTION_INIT(e_user_connected, -1940);
    BEGIN
        SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = UPPER(p_user);
        IF l_count = 1 THEN
            BEGIN
                EXECUTE IMMEDIATE 'DROP USER ' || p_user || ' CASCADE';
            EXCEPTION
                WHEN e_user_connected THEN
                    RAISE_APPLICATION_ERROR(-20004,
                        'Account ' || p_user || ' has open sessions (e.g., VS Code or SQLcl). '
                        || 'Close them and run this script again.');
            END;
            DBMS_OUTPUT.PUT_LINE('Account ' || p_user || ' dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Account ' || p_user || ' does not exist.');
        END IF;
    END drop_user;

    PROCEDURE drop_role (p_role IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = UPPER(p_role);
        IF l_count = 1 THEN
            EXECUTE IMMEDIATE 'DROP ROLE ' || p_role;
            DBMS_OUTPUT.PUT_LINE('Role ' || p_role || ' dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Role ' || p_role || ' does not exist.');
        END IF;
    END drop_role;

    PROCEDURE drop_tablespace (p_name IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO l_count FROM dba_tablespaces WHERE tablespace_name = UPPER(p_name);
        IF l_count = 1 THEN
            EXECUTE IMMEDIATE 'DROP TABLESPACE ' || p_name || ' INCLUDING CONTENTS AND DATAFILES';
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' dropped.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' does not exist.');
        END IF;
    END drop_tablespace;
BEGIN
    -- 1. Audit policies (before the audited accounts disappear)
    drop_policy('&emk_aud_ddl',        '&emk_audited_users');
    drop_policy('&emk_aud_grants',     '&emk_audited_users');
    drop_policy('&emk_aud_sessions',   '&emk_audited_users');
    drop_policy('&emk_aud_deploy_dml', '&emk_deploy_user');

    -- 2. APEX workspace (keeps the schemas; they are dropped below)
    SELECT COUNT(*) INTO l_count FROM apex_workspaces WHERE workspace = UPPER('&emk_workspace');
    IF l_count = 1 THEN
        APEX_INSTANCE_ADMIN.REMOVE_WORKSPACE(
            p_workspace        => '&emk_workspace',
            p_drop_users       => 'N',
            p_drop_tablespaces => 'N'
        );
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace removed.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace does not exist.');
    END IF;

    -- 3. Network ACL entries of the project accounts (08_network_acl.sql)
    FOR a IN (SELECT host, lower_port, upper_port, principal, privilege
              FROM   dba_host_aces
              WHERE  UPPER(principal) IN (UPPER('&emk_data_schema'), UPPER('&emk_api_schema'),
                                          UPPER('&emk_ui_schema'), UPPER('&emk_int_schema'),
                                          UPPER('&emk_deploy_user'), UPPER('&emk_dev_user'),
                                          UPPER('&emk_app_schema')))
    LOOP
        DBMS_NETWORK_ACL_ADMIN.REMOVE_HOST_ACE(
            host             => a.host,
            lower_port       => a.lower_port,
            upper_port       => a.upper_port,
            ace              => xs$ace_type(privilege_list => xs$name_list(a.privilege),
                                            principal_name => a.principal,
                                            principal_type => xs_acl.ptype_db),
            remove_empty_acl => TRUE);
        DBMS_OUTPUT.PUT_LINE('ACL ' || a.privilege || ' on ' || a.host || ' for ' || a.principal || ' removed.');
    END LOOP;

    -- 4. Accounts
    drop_user('&emk_deploy_user');
    drop_user('&emk_dev_user');
    drop_user('&emk_ui_schema');
    drop_user('&emk_api_schema');
    drop_user('&emk_data_schema');
    drop_user('&emk_int_schema');
    drop_user('&emk_app_schema');

    -- 5. Roles
    drop_role('&emk_owner_role');
    drop_role('&emk_dev_role');
    drop_role('&emk_ro_role');

    -- 6. Tablespaces and data files
    drop_tablespace('&emk_int_ts');
    drop_tablespace('&emk_data_ts');
    drop_tablespace('&emk_int_tablespace');
    drop_tablespace('&emk_tablespace');
END;
/

UNDEFINE emk_confirm
SPOOL OFF
