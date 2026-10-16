-- =============================================================================
-- 11_create_separated_schemas.sql
-- Creates the schema-only accounts of the separated design (ADR-008) and keeps
-- them in the desired state on every run:
--   &emk_data_schema  tables, journals, triggers, sequences   (&emk_data_ts)
--   &emk_api_schema   business APIs, views, log               (&emk_data_ts)
--   &emk_ui_schema    APEX parsing schema, owns no objects    (no quota)
--   &emk_int_schema   inbound data and batch jobs (ADR-007)   (&emk_int_ts)
-- Schema-only: no password, nobody logs in directly. No system privileges for
-- object creation here: in shared environments only &emk_deploy_user creates
-- objects (12_create_deploy_user.sql); in DEV the proxy sessions get the owner
-- role (06_create_dev_user.sql). Privileges used by definer's-rights PL/SQL at
-- run time are granted directly (roles are not active there, ADR-008).
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

DECLARE
    PROCEDURE create_schema (p_name IN VARCHAR2, p_tablespace IN VARCHAR2) IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = UPPER(p_name);
        IF l_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE USER ' || p_name || ' NO AUTHENTICATION'
                || ' DEFAULT TABLESPACE ' || p_tablespace
                || ' TEMPORARY TABLESPACE &emk_temp_ts';
            DBMS_OUTPUT.PUT_LINE('Schema ' || p_name || ' created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Schema ' || p_name || ' already exists.');
        END IF;
    END create_schema;
BEGIN
    create_schema('&emk_data_schema', '&emk_data_ts');
    create_schema('&emk_api_schema',  '&emk_data_ts');
    create_schema('&emk_ui_schema',   '&emk_data_ts');
    create_schema('&emk_int_schema',  '&emk_int_ts');
END;
/

-- Desired state on every run
ALTER USER &emk_data_schema DEFAULT TABLESPACE &emk_data_ts QUOTA UNLIMITED ON &emk_data_ts;
ALTER USER &emk_api_schema  DEFAULT TABLESPACE &emk_data_ts QUOTA UNLIMITED ON &emk_data_ts;
ALTER USER &emk_ui_schema   DEFAULT TABLESPACE &emk_data_ts;
ALTER USER &emk_int_schema  DEFAULT TABLESPACE &emk_int_ts  QUOTA UNLIMITED ON &emk_int_ts;

-- Run-time privileges of definer's-rights code, granted directly
GRANT CREATE JOB TO &emk_int_schema;    -- job per inbound batch (ADR-007)

BEGIN
    DBMS_OUTPUT.PUT_LINE('Schemas &emk_data_schema, &emk_api_schema, &emk_ui_schema, &emk_int_schema: tablespaces and quotas set.');
END;
/
