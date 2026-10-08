-- =============================================================================
-- 07a_create_workspace_admin.sql
-- Called by 07_create_workspace.sql only when &emk_workspace does not exist.
-- Creates the workspace and its administrator. Values entered at run time are
-- not stored in any file.
--
-- Author: Natalia Müller
-- Since:  2026-10-06
-- =============================================================================

-- Pause the install log so that the name and email typed below are not logged
SPOOL OFF

ACCEPT emk_ws_admin       CHAR PROMPT 'Workspace administrator user name: '
ACCEPT emk_ws_admin_email CHAR PROMPT 'Workspace administrator email: '
PROMPT Use a strong password (APEX rules: upper and lower case, digit, symbol). Avoid double quotes, single quotes and the ampersand character.
ACCEPT emk_ws_admin_pwd   CHAR PROMPT 'Workspace administrator password: ' HIDE

-- Resume this run's install log (file name set by install_admin.sql).
-- The values above are not written to it: VERIFY is OFF.
SPOOL &emk_log_file APPEND

BEGIN
    -- Run as the APEX instance (INTERNAL workspace) to create a workspace
    APEX_UTIL.SET_SECURITY_GROUP_ID(p_security_group_id => 10);

    APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
        p_workspace      => '&emk_workspace',
        p_primary_schema => '&emk_app_schema'
    );

    -- Switch to the new workspace to create its administrator
    APEX_UTIL.SET_WORKSPACE(p_workspace => '&emk_workspace');

    APEX_UTIL.CREATE_USER(
        p_user_name                    => '&emk_ws_admin',
        p_email_address                => '&emk_ws_admin_email',
        p_web_password                 => '&emk_ws_admin_pwd',
        p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_default_schema               => '&emk_app_schema',
        p_change_password_on_first_use => 'N'
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace and its administrator created.');
END;
/

UNDEFINE emk_ws_admin
UNDEFINE emk_ws_admin_email
UNDEFINE emk_ws_admin_pwd
