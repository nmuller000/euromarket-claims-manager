-- =============================================================================
-- 01_vector_memory_apply.sql
-- Called by 01_vector_memory.sql when VECTOR_MEMORY_SIZE is not yet active.
-- Do not run directly.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

PROMPT
PROMPT === Administrator check ===
HOST powershell -NoProfile -Command "if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'OK: running as Administrator' } else { Write-Host 'WARNING: not running as Administrator - the service restart will fail and the change will stay pending' }"

PROMPT
PROMPT === Step 1/3: backup of the current SPFILE ===
COLUMN pfile_backup NEW_VALUE pfile_backup NOPRINT
SELECT REGEXP_REPLACE(value, '[^\\/]+$', '')
       || 'pfile_before_vector_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.ora' AS pfile_backup
FROM   v$parameter
WHERE  name = 'spfile';

CREATE PFILE = '&pfile_backup' FROM SPFILE;
PROMPT Backup created: &pfile_backup

PROMPT
PROMPT === Step 2/3: set VECTOR_MEMORY_SIZE = &target_mb.M (applies on next startup) ===
ALTER SYSTEM SET vector_memory_size = &target_mb.M SCOPE = SPFILE;

PROMPT
PROMPT === Step 3/3: restart OracleServiceFREE and wait for the listener ===
DISCONNECT
HOST powershell -NoProfile -Command "Restart-Service -Name OracleServiceFREE -Force -ErrorAction Stop; for ($i = 0; $i -lt 36; $i++) { if ((lsnrctl status | Out-String) -match '\x22FREE\x22') { break }; Start-Sleep -Seconds 5 }; Start-Sleep -Seconds 10; Write-Host 'Service restarted'"

PROMPT
PROMPT === Reconnect: enter the SYS password ===
CONNECT sys@localhost:1521/FREE AS SYSDBA

@@01_vector_memory_verify.sql
