-- =============================================================================
-- 07_create_workspace.sql
-- APEX workspace &emk_workspace with primary schema &emk_app_schema.
-- Administrator name, email and password are asked only when the workspace
-- is created, and never stored.
-- Called by install_admin.sql (requires 00_config.sql).
-- =============================================================================

SET SQLFORMAT
COLUMN next_step NEW_VALUE next_step NOPRINT
SELECT CASE WHEN COUNT(*) = 0 THEN '07a_create_workspace_admin.sql'
            ELSE '00_noop.sql' END AS next_step
FROM   apex_workspaces
WHERE  workspace = UPPER('&emk_workspace');

@@&next_step

BEGIN
    DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace is present.');
END;
/
