-- =============================================================================
-- 14_audit_policies.sql
-- Unified Auditing of the project accounts (ADR-010 section 3): nothing that
-- happens inside the project schemas is audited by the Oracle default policies.
--   &emk_aud_ddl       CREATE / ALTER / DROP of the project object types, TRUNCATE, COMMENT
--   &emk_aud_grants    GRANT and REVOKE
--   &emk_aud_sessions  successful logons (failed logons: ORA_LOGIN_LOGOUT)
--   &emk_aud_deploy_dml INSERT, UPDATE, DELETE by &emk_deploy_user only: the deployment
--                      account can change data in the project schemas, so every data
--                      change it makes is recorded (to verify: how MERGE is recorded)
-- The first three are enabled BY &emk_audited_users. Proxy sessions are attributed to the person
-- (DBPROXY_USERNAME in UNIFIED_AUDIT_TRAIL). Idempotent: a policy is created
-- and enabled only if missing.
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

DECLARE
    l_count PLS_INTEGER;

    PROCEDURE create_policy (p_name IN VARCHAR2, p_actions IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO l_count FROM audit_unified_policies WHERE policy_name = UPPER(p_name);
        IF l_count = 0 THEN
            EXECUTE IMMEDIATE 'CREATE AUDIT POLICY ' || p_name || ' ACTIONS ' || p_actions;
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' already exists.');
        END IF;
    END create_policy;

    PROCEDURE enable_policy (p_name IN VARCHAR2, p_users IN VARCHAR2) IS
    BEGIN
        SELECT COUNT(*) INTO l_count FROM audit_unified_enabled_policies WHERE policy_name = UPPER(p_name);
        IF l_count = 0 THEN
            EXECUTE IMMEDIATE 'AUDIT POLICY ' || p_name || ' BY ' || p_users;
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' enabled for ' || p_users || '.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Audit policy ' || p_name || ' already enabled.');
        END IF;
    END enable_policy;
BEGIN
    create_policy('&emk_aud_ddl',
        'CREATE TABLE, ALTER TABLE, DROP TABLE, TRUNCATE TABLE, '
        || 'CREATE INDEX, ALTER INDEX, DROP INDEX, '
        || 'CREATE SEQUENCE, ALTER SEQUENCE, DROP SEQUENCE, '
        || 'CREATE VIEW, ALTER VIEW, DROP VIEW, '
        || 'CREATE PACKAGE, ALTER PACKAGE, DROP PACKAGE, '
        || 'CREATE PACKAGE BODY, ALTER PACKAGE BODY, DROP PACKAGE BODY, '
        || 'CREATE PROCEDURE, ALTER PROCEDURE, DROP PROCEDURE, '
        || 'CREATE FUNCTION, ALTER FUNCTION, DROP FUNCTION, '
        || 'CREATE TRIGGER, ALTER TRIGGER, DROP TRIGGER, '
        || 'CREATE TYPE, ALTER TYPE, DROP TYPE, CREATE TYPE BODY, DROP TYPE BODY, '
        || 'COMMENT');
    create_policy('&emk_aud_grants',   'GRANT, REVOKE');
    create_policy('&emk_aud_sessions', 'LOGON');
    create_policy('&emk_aud_deploy_dml', 'INSERT, UPDATE, DELETE');

    enable_policy('&emk_aud_ddl',        '&emk_audited_users');
    enable_policy('&emk_aud_grants',     '&emk_audited_users');
    enable_policy('&emk_aud_sessions',   '&emk_audited_users');
    enable_policy('&emk_aud_deploy_dml', '&emk_deploy_user');
END;
/
