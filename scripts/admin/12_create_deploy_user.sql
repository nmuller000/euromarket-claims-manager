-- =============================================================================
-- 12_create_deploy_user.sql
-- Deployment account &emk_deploy_user (ADR-008): the only account that changes
-- objects in shared environments. It deploys with SCHEMA privileges limited to
-- the project schemas (GRANT ... ON SCHEMA, 23ai), never as an owner.
--   - created if missing (password asked only then, 12a);
--   - service profile &emk_deploy_profile (an expiry would stop deployments);
--   - own schema with quota &emk_deploy_quota for the Liquibase tables;
--   - schema privileges on &emk_data_schema, &emk_api_schema and &emk_int_schema
--     (&emk_ui_schema owns nothing; it only receives grants).
-- A privilege that cannot be granted ON SCHEMA is reported and stops the run,
-- so that a missing deployment right is found here and not in a release.
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

-- Ask for a password only when the account must be created
SET TERMOUT OFF
COLUMN next_step NEW_VALUE next_step NOPRINT
SELECT CASE WHEN COUNT(*) = 0 THEN '12a_create_deploy_account.sql'
            ELSE '00_noop.sql' END AS next_step
FROM   dba_users
WHERE  username = UPPER('&emk_deploy_user');
SET TERMOUT ON

@@&next_step

-- Desired state on every run
ALTER USER &emk_deploy_user
    PROFILE &emk_deploy_profile
    DEFAULT TABLESPACE &emk_data_ts
    QUOTA &emk_deploy_quota ON &emk_data_ts;

GRANT CREATE SESSION, CREATE TABLE TO &emk_deploy_user;   -- log in; own Liquibase tables

DECLARE
    l_missing PLS_INTEGER := 0;

    TYPE t_list IS TABLE OF VARCHAR2(40);
    -- Deployment rights inside a project schema (re-granting is harmless)
    c_privileges CONSTANT t_list := t_list(
        'CREATE ANY TABLE', 'ALTER ANY TABLE', 'DROP ANY TABLE', 'COMMENT ANY TABLE',
        'SELECT ANY TABLE', 'INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE',
        'CREATE ANY INDEX', 'ALTER ANY INDEX', 'DROP ANY INDEX',
        'CREATE ANY SEQUENCE', 'ALTER ANY SEQUENCE', 'DROP ANY SEQUENCE', 'SELECT ANY SEQUENCE',
        'CREATE ANY VIEW', 'DROP ANY VIEW',
        'CREATE ANY PROCEDURE', 'ALTER ANY PROCEDURE', 'DROP ANY PROCEDURE', 'EXECUTE ANY PROCEDURE',
        'CREATE ANY TRIGGER', 'ALTER ANY TRIGGER', 'DROP ANY TRIGGER',
        'CREATE ANY TYPE', 'ALTER ANY TYPE', 'DROP ANY TYPE', 'EXECUTE ANY TYPE',
        'GRANT ANY OBJECT PRIVILEGE');
    c_schemas CONSTANT t_list := t_list('&emk_data_schema', '&emk_api_schema', '&emk_int_schema');
BEGIN
    FOR s IN 1 .. c_schemas.COUNT LOOP
        FOR p IN 1 .. c_privileges.COUNT LOOP
            BEGIN
                EXECUTE IMMEDIATE 'GRANT ' || c_privileges(p) || ' ON SCHEMA ' || c_schemas(s)
                               || ' TO &emk_deploy_user';
            EXCEPTION
                WHEN OTHERS THEN
                    l_missing := l_missing + 1;
                    DBMS_OUTPUT.PUT_LINE('NOT GRANTED ' || c_privileges(p) || ' ON SCHEMA '
                                         || c_schemas(s) || ': ' || SQLERRM);
            END;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Schema privileges on ' || c_schemas(s) || ' granted to &emk_deploy_user.');
    END LOOP;

    IF l_missing > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, l_missing || ' schema privilege(s) could not be granted (see above).');
    END IF;
END;
/
