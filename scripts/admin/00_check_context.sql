-- =============================================================================
-- 00_check_context.sql
-- Stops the run unless connected as SYS to the target PDB (&emk_pdb).
--
-- Author: Natalia Müller
-- Since:  2026-10-06
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'SYS'
       OR SYS_CONTEXT('USERENV', 'CON_NAME') <> UPPER('&emk_pdb')
    THEN
        RAISE_APPLICATION_ERROR(-20000,
            'Run as SYS connected to &emk_pdb (current: '
            || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' in '
            || SYS_CONTEXT('USERENV', 'CON_NAME') || ').');
    END IF;
END;
/
