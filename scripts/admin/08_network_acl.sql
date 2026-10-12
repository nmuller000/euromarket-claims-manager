-- =============================================================================
-- 08_network_acl.sql
-- Outbound network access, granted by script only to the hosts each milestone
-- needs (ADR-005, SC-SEC-12). Idempotent: an entry is added only if missing.
--
-- M1a: PL/SQL debugging from SQL Developer for VS Code. The debugger uses
--      DBMS_DEBUG_JDWP, so the database session connects back to the debugger
--      on the developer's machine; this needs the ACL privilege "jdwp".
--      Granted to the schemas used in proxy sessions, for the local machine only.
-- M2:  SMTP host and port for e-mail alerts (to be added here).
--
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-07
-- =============================================================================

DECLARE
    PROCEDURE append_ace (p_host IN VARCHAR2, p_privilege IN VARCHAR2, p_principal IN VARCHAR2) IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_host_aces
        WHERE  LOWER(host)      = LOWER(p_host)
        AND    UPPER(principal) = UPPER(p_principal)
        AND    UPPER(privilege) = UPPER(p_privilege);   -- case-insensitive: stored case not assumed

        IF l_count = 0 THEN
            DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
                host => p_host,
                ace  => xs$ace_type(privilege_list => xs$name_list(p_privilege),
                                    principal_name => UPPER(p_principal),
                                    principal_type => xs_acl.ptype_db));
            DBMS_OUTPUT.PUT_LINE('ACL ' || p_privilege || ' on ' || p_host || ' granted to ' || p_principal || '.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('ACL ' || p_privilege || ' on ' || p_host || ' for ' || p_principal || ' already exists.');
        END IF;
    END append_ace;
BEGIN
    -- Debugger on the local machine only (all ports: the debugger chooses its port)
    append_ace('localhost', 'jdwp', '&emk_app_schema');
    append_ace('127.0.0.1', 'jdwp', '&emk_app_schema');
    append_ace('localhost', 'jdwp', '&emk_int_schema');
    append_ace('127.0.0.1', 'jdwp', '&emk_int_schema');
END;
/
