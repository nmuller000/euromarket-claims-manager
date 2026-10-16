-- =============================================================================
-- 01_precheck.sql - Migration phase M.1, step 1 (read only)
-- Checks before the maintenance restart: OS authentication, SPFILE, log mode,
-- recovery area, TDE parameters, redo logs, PDBs and data size. Changes nothing.
--
-- Run from the repository root, connected to the CDB root with OS authentication
-- (this also proves that a stopped instance can be started without a password):
--   sqlplus / as sysdba @scripts/operations/01_precheck.sql
-- Values: 00_config.sql. Output: <log folder>\01_precheck.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
COLUMN check_name FORMAT A34
COLUMN value      FORMAT A90
COLUMN expected   FORMAT A60
@@00_config.sql
SPOOL &emk_log_dir\01_precheck.log

PROMPT === 1. Session (expected: SYS in CDB$ROOT through OS authentication)
SELECT 'session user'          AS check_name, SYS_CONTEXT('USERENV', 'SESSION_USER')          AS value FROM dual
UNION ALL
SELECT 'container',                           SYS_CONTEXT('USERENV', 'CON_NAME')                       FROM dual
UNION ALL
SELECT 'authentication method',               SYS_CONTEXT('USERENV', 'AUTHENTICATION_METHOD')          FROM dual
UNION ALL
SELECT 'OS user',                             SYS_CONTEXT('USERENV', 'OS_USER')                        FROM dual;

PROMPT
PROMPT === 2. Database (record the DBID in the record of the database, recovery runbook section 3)
SELECT 'name / DBID'           AS check_name, name || ' / ' || dbid AS value FROM v$database
UNION ALL
SELECT 'log mode',        log_mode                        FROM v$database
UNION ALL
SELECT 'open mode',                           open_mode                       FROM v$database
UNION ALL
SELECT 'flashback on',                        flashback_on                    FROM v$database
UNION ALL
SELECT 'version',                             version_full                    FROM v$instance;

PROMPT
PROMPT === 3. Parameters (SPFILE must be set: ALTER SYSTEM ... SCOPE = SPFILE needs it)
SELECT name AS check_name, NVL(value, '(not set)') AS value
FROM   v$parameter
WHERE  name IN ('spfile', 'compatible',
                'db_recovery_file_dest', 'db_recovery_file_dest_size',
                'archive_lag_target', 'log_archive_dest_1',
                'wallet_root', 'tde_configuration',
                'tablespace_encryption', 'tablespace_encryption_default_algorithm')
ORDER  BY name;

PROMPT
PROMPT === 4. Keystore (before M.1: NOT_AVAILABLE; after: OPEN / LOCAL_AUTOLOGIN)
SELECT con_id, wrl_type, wrl_parameter, status, wallet_type
FROM   v$encryption_wallet
ORDER  BY con_id;

PROMPT
PROMPT === 5. Online redo logs (size and members)
SELECT l.group#, l.thread#, ROUND(l.bytes / 1024 / 1024) AS size_mb, l.members, l.status
FROM   v$log l
ORDER  BY l.group#;
SELECT group#, member FROM v$logfile ORDER BY group#;

PROMPT
PROMPT === 6. Control files
SELECT name FROM v$controlfile;

PROMPT
PROMPT === 7. Containers: open mode and saved state (PDBs must reopen after the restart)
SELECT p.con_id, p.name, p.open_mode,
       NVL((SELECT s.state FROM dba_pdb_saved_states s WHERE s.con_name = p.name), '(no saved state)') AS saved_state
FROM   v$pdbs p
ORDER  BY p.con_id;

PROMPT
PROMPT === 8. Size of data files per container (GB) - basis for the backup size
SELECT c.name AS container, ROUND(SUM(d.bytes) / 1024 / 1024 / 1024, 2) AS files_gb
FROM   v$datafile d JOIN v$containers c ON c.con_id = d.con_id
GROUP  BY c.name
ORDER  BY c.name;

PROMPT
PROMPT === 9. Block change tracking (before M.1: DISABLED; after: ENABLED)
SELECT status, filename FROM v$block_change_tracking;

PROMPT
PROMPT === 10. Next: check free disk space in PowerShell
PROMPT     Get-PSDrive C | Select-Object Used, Free
PROMPT     (M.1 needs about 10 GB for the cold backup and the first level 0)

SPOOL OFF
EXIT
