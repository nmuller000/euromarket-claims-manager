-- =============================================================================
-- 02_set_params.sql - Migration phase M.1, step 2
-- Prepares the maintenance restart (ADR-010, ADR-011): fast recovery area,
-- archive lag target, keystore location and automatic tablespace encryption.
-- The two static parameters (WALLET_ROOT, TABLESPACE_ENCRYPTION) take effect
-- only after the restart of step 3. Idempotent: running it again sets the same
-- values. The database stays open; users are not affected yet.
--
-- Run from the repository root:
--   sqlplus / as sysdba @scripts/operations/02_set_params.sql
-- Values: 00_config.sql. Output: <log folder>\02_set_params.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN name         FORMAT A40
COLUMN memory_value FORMAT A60
COLUMN spfile_value FORMAT A60
@@00_config.sql
SPOOL &emk_log_dir\02_set_params.log
WHENEVER SQLERROR EXIT FAILURE

PROMPT === Context check: SYS in CDB$ROOT, SPFILE in use
BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'SYS'
       OR SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT'
    THEN
        RAISE_APPLICATION_ERROR(-20000, 'Run as SYS in CDB$ROOT (sqlplus / as sysdba).');
    END IF;
    FOR r IN (SELECT value FROM v$parameter WHERE name = 'spfile') LOOP
        IF r.value IS NULL THEN
            RAISE_APPLICATION_ERROR(-20000, 'No SPFILE in use: SCOPE = SPFILE would fail.');
        END IF;
    END LOOP;
END;
/

PROMPT === Folders (created if missing; WALLET_ROOT must exist before the keystore, ORA-46693)
HOST mkdir &emk_fra_dir 2>NUL
HOST mkdir &emk_wallet_root 2>NUL

PROMPT === Fast recovery area: size first, then location (setup.md section 1.1: internal FRA about 28 GB expected)
ALTER SYSTEM SET db_recovery_file_dest_size = &emk_fra_size SCOPE = BOTH;
ALTER SYSTEM SET db_recovery_file_dest = '&emk_fra_dir' SCOPE = BOTH;

PROMPT === Log switch at least every 30 minutes (ADR-010; effective once in ARCHIVELOG)
ALTER SYSTEM SET archive_lag_target = &emk_archive_lag SCOPE = BOTH;

PROMPT === Static parameters for TDE (ADR-011), effective after the restart
ALTER SYSTEM SET wallet_root = '&emk_wallet_root' SCOPE = SPFILE;
ALTER SYSTEM SET tablespace_encryption = AUTO_ENABLE SCOPE = SPFILE;

PROMPT === Result: value now (memory) and value after the restart (SPFILE)
SELECT p.name,
       NVL(p.value, '(not set)')  AS memory_value,
       NVL(s.value, '(not set)')  AS spfile_value
FROM   v$parameter p
LEFT JOIN v$spparameter s ON s.name = p.name AND s.sid = '*'
WHERE  p.name IN ('db_recovery_file_dest', 'db_recovery_file_dest_size',
                  'archive_lag_target', 'log_archive_dest_1',
                  'wallet_root', 'tablespace_encryption')
ORDER  BY p.name;

PROMPT
PROMPT Expected before the first restart: wallet_root and tablespace_encryption differ
PROMPT (new value only in the SPFILE column); after it, both columns are equal.
PROMPT log_archive_dest_1 must be "(not set)": archived logs then go to the fast recovery area.
PROMPT First run only: stop ORDS (Ctrl+C in its window), then run step 3 with RMAN.

SPOOL OFF
EXIT
