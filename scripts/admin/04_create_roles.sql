-- =============================================================================
-- 04_create_roles.sql
-- Creates the project roles if they do not exist and grants their privileges.
-- No default roles (CONNECT, RESOURCE, DBA) are used (ADR-005).
-- Called by install_admin.sql (requires 00_config.sql).
-- =============================================================================

DECLARE
    PROCEDURE create_role (p_role IN VARCHAR2) IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = UPPER(p_role);
        IF l_count = 0 THEN
            EXECUTE IMMEDIATE 'CREATE ROLE ' || p_role;
            DBMS_OUTPUT.PUT_LINE('Role ' || p_role || ' created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Role ' || p_role || ' already exists.');
        END IF;
    END create_role;
BEGIN
    create_role('&emk_owner_role');
    create_role('&emk_dev_role');
    create_role('&emk_ro_role');
END;
/

-- Owner role: privileges to create the application objects in EMK_APP.
-- Re-granting an existing privilege is harmless, so these GRANTs are idempotent.
GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE TYPE,
      CREATE SYNONYM,
      CREATE MATERIALIZED VIEW,
      CREATE JOB,
      CREATE MINING MODEL
TO &emk_owner_role;

-- Developer role: session and PL/SQL debugging for developer accounts.
-- Read access to EMK_APP objects is granted by the application layer.
GRANT CREATE SESSION,
      DEBUG CONNECT SESSION
TO &emk_dev_role;

-- Read-only role: SELECT on analytical views is granted by the application
-- layer (NL-to-SQL, extension X2).
GRANT CREATE SESSION TO &emk_ro_role;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Role privileges granted.');
END;
/
