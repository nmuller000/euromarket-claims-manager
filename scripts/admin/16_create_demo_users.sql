-- =============================================================================
-- 16_create_demo_users.sql
-- Creates one demo user per role of application &emk_apex_app_id (step 7.8),
-- so that every page can be shown and tested with the rights of each role:
-- DEMO_<role static id>, e.g. DEMO_CLAIMS_HANDLER, with that role assigned in
-- Application Access Control (APEX_ACL). The roles are read from the
-- application (APEX_APPL_ACL_ROLES), so a new role gets its demo user without
-- changing this script. End users only: no developer rights, no email (no
-- personal data). Never in PROD.
-- One password for all demo users, entered hidden and never shown or stored,
-- even if the creation fails (same fail-safe pattern as 07a): the block that
-- holds it never ends in an error; a second block without it stops the run.
-- Idempotent: an existing user is kept (its password is not changed) and an
-- existing role assignment is kept.
--
-- Run from the repository root as SYS in the PDB of the environment, e.g. DEV:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/16_create_demo_users.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-22
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

-- PROD is not offered: demo users never exist there; the check below still refuses it.
ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST or ACC): '
@@00_config.sql
@@00_check_context.sql

BEGIN
    IF '&emk_env' = 'PROD' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Demo users are never created in PROD.');
    END IF;
END;
/

VARIABLE emk_demo_ok NUMBER
PROMPT
PROMPT APEX password rules: upper and lower case, digit, symbol. Do not use quotes, the
PROMPT ampersand or the tilde. Copy it from the password manager when the prompt appears.
ACCEPT emk_demo_pwd CHAR PROMPT 'Password of the demo users: ' HIDE

DECLARE
    l_pwd     VARCHAR2(255) := q'~&emk_demo_pwd~';
    l_user    VARCHAR2(255);
    l_count   PLS_INTEGER;
    l_created PLS_INTEGER := 0;
    l_roles   PLS_INTEGER := 0;
BEGIN
    :emk_demo_ok := 0;
    APEX_UTIL.SET_WORKSPACE(p_workspace => '&emk_workspace');

    FOR r IN (SELECT role_static_id
              FROM   apex_appl_acl_roles
              WHERE  application_id = &emk_apex_app_id
              ORDER  BY role_static_id) LOOP
        l_user := 'DEMO_' || r.role_static_id;

        SELECT COUNT(*) INTO l_count
        FROM   apex_workspace_apex_users
        WHERE  workspace_name = '&emk_workspace' AND user_name = l_user;
        IF l_count = 0 THEN
            APEX_UTIL.CREATE_USER(
                p_user_name                    => l_user,
                p_web_password                 => l_pwd,
                p_developer_privs              => NULL,   -- end user of the application only
                p_change_password_on_first_use => 'N'
            );
            l_created := l_created + 1;
        END IF;

        IF NOT APEX_ACL.HAS_USER_ROLE(p_application_id => &emk_apex_app_id, p_user_name => l_user,
                                      p_role_static_id => r.role_static_id) THEN
            APEX_ACL.ADD_USER_ROLE(p_application_id => &emk_apex_app_id, p_user_name => l_user,
                                   p_role_static_id => r.role_static_id);
            l_roles := l_roles + 1;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Demo user ' || l_user || ': role ' || r.role_static_id);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Demo users created: ' || l_created || '; roles assigned: ' || l_roles);
    :emk_demo_ok := 1;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Demo users not created: ' || SQLERRM);
END;
/
UNDEFINE emk_demo_pwd

BEGIN
    IF :emk_demo_ok <> 1 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Demo users not created (reason above).');
    END IF;
END;
/

PROMPT
PROMPT === Demo users and their roles ===
SET SQLFORMAT ansiconsole
SELECT user_name, role_static_id
FROM   apex_appl_acl_user_roles
WHERE  application_id = &emk_apex_app_id AND user_name LIKE 'DEMO\_%' ESCAPE '\'
ORDER  BY user_name;
SET SQLFORMAT

EXIT
