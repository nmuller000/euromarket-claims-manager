-- =============================================================================
-- 04_create_roles.sql
-- Creates the project roles if they do not exist and grants their privileges.
-- No default roles (CONNECT, RESOURCE, DBA) are used (ADR-005).
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
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

-- Developer role: privileges needed while developing in a PROXY session
-- (EMK_DEV[EMK_APP], EMK_DEV[EMK_INT]). In a proxy session the roles of the
-- target schema apply, so this role is granted to the schemas, not to EMK_DEV
-- (ADR-007). Debugging from SQL Developer for VS Code uses DBMS_DEBUG_JDWP;
-- the network permission (ACL "jdwp") is granted in 08_network_acl.sql.
-- Not intended for a production environment.
GRANT CREATE SESSION,
      DEBUG CONNECT SESSION
TO &emk_dev_role;
GRANT EXECUTE ON SYS.DBMS_DEBUG_JDWP TO &emk_dev_role;
GRANT DEBUG   ON SYS.DBMS_DEBUG_JDWP TO &emk_dev_role;

-- Read-only role: SELECT on analytical views is granted by the application
-- layer (NL-to-SQL, extension X2).
GRANT CREATE SESSION TO &emk_ro_role;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Role privileges granted.');
END;
/
