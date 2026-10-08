-- =============================================================================
-- uninstall_admin.sql
-- Removes everything created by install_admin.sql: APEX workspace, network
-- ACL entries, developer account, application and integration schemas (with
-- all their objects), roles and tablespaces (with their datafiles). Requires
-- typing YES. Safe to run when objects are already gone. The personal account
-- DEV_USER, the Oracle-supplied profile and UT3 (utPLSQL) are not touched.
--
-- Close any session connected as EMK_DEV, EMK_APP or EMK_INT (VS Code, SQLcl) first.
-- Run from the repository root as SYS in FREEPDB1:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/uninstall_admin.sql
--
-- Author: Natalia Müller
-- Since:  2026-10-06
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

@@admin/00_config.sql
@@admin/00_check_context.sql

PROMPT
PROMPT This removes: workspace &emk_workspace, network ACL entries, accounts &emk_dev_user,
PROMPT &emk_int_schema and &emk_app_schema (with ALL their objects), roles &emk_owner_role,
PROMPT &emk_dev_role, &emk_ro_role and tablespaces &emk_tablespace, &emk_int_tablespace
PROMPT including their datafiles.
ACCEPT emk_confirm CHAR PROMPT 'Type YES to continue: '

BEGIN
    IF UPPER('&emk_confirm') <> 'YES' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Cancelled. Nothing was removed.');
    END IF;
END;
/

-- One log per run (logs/uninstall_admin_YYYYMMDD_HH24MISS.log), so earlier runs are kept
COLUMN log_file NEW_VALUE emk_log_file NOPRINT
SELECT 'logs/uninstall_admin_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS log_file FROM dual;
SPOOL &emk_log_file

DECLARE
    l_count PLS_INTEGER;

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
    -- 1. APEX workspace (keeps the schema; it is dropped below)
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

    -- 2. Network ACL entries of the project accounts (08_network_acl.sql)
    FOR a IN (SELECT host, lower_port, upper_port, principal, privilege
              FROM   dba_host_aces
              WHERE  UPPER(principal) IN (UPPER('&emk_app_schema'), UPPER('&emk_int_schema'), UPPER('&emk_dev_user')))
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

    -- 3. Accounts
    drop_user('&emk_dev_user');
    drop_user('&emk_int_schema');
    drop_user('&emk_app_schema');

    -- 4. Roles
    drop_role('&emk_owner_role');
    drop_role('&emk_dev_role');
    drop_role('&emk_ro_role');

    -- 5. Tablespaces and datafiles
    drop_tablespace('&emk_int_tablespace');
    drop_tablespace('&emk_tablespace');
END;
/

UNDEFINE emk_confirm
SPOOL OFF
