-- =============================================================================
-- 04_postcheck.sql - Migration phase M.1, step 4 (read only)
-- Checks the result of the restart: ARCHIVELOG, archived logs in the fast
-- recovery area, TDE parameters active, PDBs open, cold backup present.
--
-- Run from the repository root:
--   sqlplus / as sysdba @scripts/operations/04_postcheck.sql
-- Values: 00_config.sql. Output: <log folder>\04_postcheck.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
COLUMN check_name FORMAT A36
COLUMN value      FORMAT A70
COLUMN expected   FORMAT A48
COLUMN result     FORMAT A6
COLUMN name       FORMAT A80
@@00_config.sql
SPOOL &emk_log_dir\04_postcheck.log

PROMPT === Checks
WITH c AS (
    SELECT 'log mode' AS check_name, log_mode AS value, 'ARCHIVELOG' AS expected FROM v$database
    UNION ALL
    SELECT 'open mode', open_mode, 'READ WRITE' FROM v$database
    UNION ALL
    SELECT 'wallet_root', NVL(value, '(not set)'), '&emk_wallet_default'
    FROM v$parameter WHERE name = 'wallet_root'
    UNION ALL
    SELECT 'tablespace_encryption', NVL(value, '(not set)'), 'AUTO_ENABLE'
    FROM v$parameter WHERE name = 'tablespace_encryption'
    UNION ALL
    SELECT 'archive_lag_target', value, '&emk_archive_lag'
    FROM v$parameter WHERE name = 'archive_lag_target'
    UNION ALL
    SELECT 'PDBs not READ WRITE', TO_CHAR(COUNT(*)), '0'
    FROM v$pdbs WHERE name <> 'PDB$SEED' AND open_mode <> 'READ WRITE'
    UNION ALL
    SELECT 'archived logs in the FRA', TO_CHAR(COUNT(*)), '>= 1 (not compared)'
    FROM v$archived_log WHERE UPPER(name) LIKE '%FAST_RECOVERY_AREA%'
    UNION ALL
    SELECT 'cold backup pieces', TO_CHAR(COUNT(*)), '1+ after step 3, 0 after step 7 (not compared)'
    FROM v$backup_piece WHERE tag = 'COLD_NOARCHIVELOG' AND status = 'A'
)
SELECT check_name, value, expected,
       CASE WHEN expected LIKE '%(not compared)' THEN 'INFO'
            WHEN UPPER(value) = UPPER(expected) THEN 'PASS'
            ELSE 'FAIL' END AS result
FROM   c;

PROMPT
PROMPT === Fast recovery area usage
SELECT name, ROUND(space_limit / 1024 / 1024 / 1024, 1) AS limit_gb,
       ROUND(space_used / 1024 / 1024 / 1024, 2) AS used_gb
FROM   v$recovery_file_dest;

PROMPT
PROMPT === Latest archived logs
SELECT sequence#, first_time, next_time, name
FROM   (SELECT sequence#, first_time, next_time, name
        FROM   v$archived_log ORDER BY sequence# DESC)
WHERE  ROWNUM <= 5;

PROMPT
PROMPT === PDBs
SELECT con_id, name, open_mode FROM v$pdbs ORDER BY con_id;

PROMPT
PROMPT Next: start ORDS and open APEX.

SPOOL OFF
EXIT
