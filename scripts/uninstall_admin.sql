-- =============================================================================
-- uninstall_admin.sql
-- Removes everything created by install_admin.sql: APEX workspace, developer
-- account, application schema (with all its objects), roles and tablespace
-- (with its datafile). Requires typing YES. Safe to run when objects are
-- already gone. The personal account DEV_USER is not touched.
--
-- Close any session connected as EMK_DEV or EMK_APP (VS Code, SQLcl) first.
-- Run from the repository root as SYS in FREEPDB1:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/uninstall_admin.sql
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

@@admin/00_config.sql
@@admin/00_check_context.sql

PROMPT
PROMPT This removes: workspace &emk_workspace, accounts &emk_dev_user and &emk_app_schema
PROMPT (with ALL their objects), roles &emk_owner_role, &emk_dev_role, &emk_ro_role
PROMPT and tablespace &emk_tablespace including its datafile.
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

    -- 2. Accounts
    drop_user('&emk_dev_user');
    drop_user('&emk_app_schema');

    -- 3. Roles
    drop_role('&emk_owner_role');
    drop_role('&emk_dev_role');
    drop_role('&emk_ro_role');

    -- 4. Tablespace and datafile
    SELECT COUNT(*) INTO l_count FROM dba_tablespaces WHERE tablespace_name = UPPER('&emk_tablespace');
    IF l_count = 1 THEN
        EXECUTE IMMEDIATE 'DROP TABLESPACE &emk_tablespace INCLUDING CONTENTS AND DATAFILES';
        DBMS_OUTPUT.PUT_LINE('Tablespace &emk_tablespace dropped.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace &emk_tablespace does not exist.');
    END IF;
END;
/

UNDEFINE emk_confirm
SPOOL OFF
