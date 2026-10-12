-- =============================================================================
-- 06a_enable_bct.sql - Migration phase M.1, step 6a (ADR-010)
-- Enables block change tracking, so that incremental backups read only the
-- changed blocks. Idempotent: does nothing if it is already enabled.
--
-- Run from the repository root:
--   sqlplus / as sysdba "@scripts/operations/06a_enable_bct.sql"
-- Values: 00_config.sql (tracking file next to the CDB data files).
-- Output: <log folder>\06a_enable_bct.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON SERVEROUTPUT ON
COLUMN filename FORMAT A80
@@00_config.sql
WHENEVER SQLERROR EXIT FAILURE
SPOOL &emk_log_dir\06a_enable_bct.log

DECLARE
    l_status v$block_change_tracking.status%TYPE;
BEGIN
    SELECT status INTO l_status FROM v$block_change_tracking;
    IF l_status = 'ENABLED' THEN
        DBMS_OUTPUT.PUT_LINE('block change tracking already enabled: nothing to do');
    ELSE
        EXECUTE IMMEDIATE q'[ALTER DATABASE ENABLE BLOCK CHANGE TRACKING USING FILE '&emk_bct_file' REUSE]';
        DBMS_OUTPUT.PUT_LINE('block change tracking enabled');
    END IF;
END;
/

PROMPT === Expected: ENABLED
SELECT status, filename FROM v$block_change_tracking;

SPOOL OFF
EXIT
