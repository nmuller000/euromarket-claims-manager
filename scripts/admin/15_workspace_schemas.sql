-- =============================================================================
-- 15_workspace_schemas.sql
-- Assigns &emk_ui_schema to the APEX workspace &emk_workspace (ADR-008: the
-- parsing schema of application &emk_apex_app_id). A new workspace already has
-- it as primary schema (07a); this keeps the assignment if it was removed.
-- Idempotent. Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

DECLARE
    l_schemas VARCHAR2(4000);
BEGIN
    l_schemas := APEX_INSTANCE_ADMIN.GET_SCHEMAS(p_workspace => '&emk_workspace');
    IF REGEXP_LIKE(UPPER(l_schemas), '(^|[^A-Z0-9_$#])' || UPPER('&emk_ui_schema') || '([^A-Z0-9_$#]|$)') THEN
        DBMS_OUTPUT.PUT_LINE('Workspace &emk_workspace already uses &emk_ui_schema.');
    ELSE
        APEX_INSTANCE_ADMIN.ADD_SCHEMA(p_workspace => '&emk_workspace', p_schema => '&emk_ui_schema');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Schema &emk_ui_schema added to workspace &emk_workspace.');
    END IF;
END;
/
