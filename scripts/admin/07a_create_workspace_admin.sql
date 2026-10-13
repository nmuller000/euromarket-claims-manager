-- =============================================================================
-- 07a_create_workspace_admin.sql
-- Called by 07_create_workspace.sql only when &emk_workspace does not exist.
-- Creates the workspace (primary schema &emk_ui_schema, ADR-008) and its
-- administrator. The values entered (name, email: personal data; password) are
-- never written to the log and never shown, even if the creation fails: the
-- block that holds them never ends in an error (same fail-safe pattern as
-- 00_set_password.sql); a second block without the values stops the run.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

-- Pause the install log so that the values typed below are not logged
SPOOL OFF

VARIABLE emk_ws_ok NUMBER
ACCEPT emk_ws_admin       CHAR PROMPT 'Workspace administrator user name: '
ACCEPT emk_ws_admin_email CHAR PROMPT 'Workspace administrator email: '
PROMPT APEX password rules: upper and lower case, digit, symbol. Do not use quotes, the
PROMPT ampersand or the tilde. Copy it from the password manager when the prompt appears.
ACCEPT emk_ws_admin_pwd   CHAR PROMPT 'Workspace administrator password: ' HIDE

DECLARE
    l_admin VARCHAR2(255)  := q'~&emk_ws_admin~';
    l_email VARCHAR2(255)  := q'~&emk_ws_admin_email~';
    l_pwd   VARCHAR2(255)  := q'~&emk_ws_admin_pwd~';
BEGIN
    :emk_ws_ok := 0;

    -- Run as the APEX instance (INTERNAL workspace) to create a workspace
    APEX_UTIL.SET_SECURITY_GROUP_ID(p_security_group_id => 10);
    APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
        p_workspace      => '&emk_workspace',
        p_primary_schema => '&emk_ui_schema'
    );

    -- Switch to the new workspace to create its administrator
    APEX_UTIL.SET_WORKSPACE(p_workspace => '&emk_workspace');
    APEX_UTIL.CREATE_USER(
        p_user_name                    => l_admin,
        p_email_address                => l_email,
        p_web_password                 => l_pwd,
        p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
        p_default_schema               => '&emk_ui_schema',
        p_change_password_on_first_use => 'N'
    );

    COMMIT;
    :emk_ws_ok := 1;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Workspace not created: ' || SQLERRM);
END;
/
UNDEFINE emk_ws_admin
UNDEFINE emk_ws_admin_email
UNDEFINE emk_ws_admin_pwd

-- Resume this run's install log (file name set by install_admin.sql)
SPOOL &emk_log_file APPEND

BEGIN
    IF :emk_ws_ok <> 1 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Workspace &emk_workspace not created (reason above).');
    END IF;
    DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace and its administrator created.');
END;
/
