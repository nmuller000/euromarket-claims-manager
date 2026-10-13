-- =============================================================================
-- 04_create_roles.sql
-- Creates the project roles if they do not exist and grants their privileges.
-- No default roles (CONNECT, RESOURCE, DBA) are used (ADR-005).
-- The developer role exists only where developer access is allowed (DEV,
-- ADR-009): &emk_dev_access = Y.
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
    create_role('&emk_ro_role');
    IF '&emk_dev_access' = 'Y' THEN
        create_role('&emk_dev_role');
    END IF;
END;
/

-- Owner role: privileges to create objects in a proxy session (DEV). In shared
-- environments only EMK_DEPLOY creates objects, with schema privileges (ADR-008).
-- Re-granting an existing privilege is harmless, so these GRANTs are idempotent.
GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE TYPE,
      CREATE MATERIALIZED VIEW,
      CREATE JOB,
      CREATE MINING MODEL
TO &emk_owner_role;

-- No synonyms in the project (ADR-008: schema-qualified names); removed from
-- the role if an earlier version granted it. Existing synonyms are not touched.
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO l_count FROM dba_sys_privs
    WHERE  grantee = UPPER('&emk_owner_role') AND privilege = 'CREATE SYNONYM';
    IF l_count > 0 THEN
        EXECUTE IMMEDIATE 'REVOKE CREATE SYNONYM FROM &emk_owner_role';
        DBMS_OUTPUT.PUT_LINE('CREATE SYNONYM revoked from &emk_owner_role.');
    END IF;
END;
/

-- Developer role (DEV only): privileges needed while developing in a PROXY session
-- (EMK_DEV[EMK_DATA], EMK_DEV[EMK_API], EMK_DEV[EMK_INT]). In a proxy session the roles of the
-- target schema apply, so this role is granted to the schemas, not to EMK_DEV
-- (ADR-007). Debugging from SQL Developer for VS Code uses DBMS_DEBUG_JDWP;
-- the network permission (ACL "jdwp") is granted in 08_network_acl.sql.
-- Not intended for a production environment.
BEGIN
    IF '&emk_dev_access' = 'Y' THEN
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION, DEBUG CONNECT SESSION TO &emk_dev_role';
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON SYS.DBMS_DEBUG_JDWP TO &emk_dev_role';
        EXECUTE IMMEDIATE 'GRANT DEBUG   ON SYS.DBMS_DEBUG_JDWP TO &emk_dev_role';
    END IF;
END;
/

-- Read-only role: SELECT on analytical views is granted by the application
-- layer (NL-to-SQL, extension X2).
GRANT CREATE SESSION TO &emk_ro_role;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Role privileges granted.');
END;
/
