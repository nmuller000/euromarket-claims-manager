-- =============================================================================
-- 01_vector_memory.sql
-- Configures the vector memory pool (VECTOR_MEMORY_SIZE) required by HNSW
-- in-memory vector indexes. See docs/adr/ADR-001.
--
-- Idempotent: if the target value is already active, it only verifies.
--
-- Requirements:
--   * Oracle AI Database 26ai Free on Windows (service OracleServiceFREE).
--   * PowerShell opened "as Administrator" (needed to restart the service).
--   * Run from the repository root with SQLcl and the thin driver:
--       sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/01_vector_memory.sql
--   * The SYS password is requested again after the restart (never stored).
--
-- Impact: the database restarts (1-2 min). All sessions (SQLcl, VS Code,
-- ORDS, APEX) are disconnected; uncommitted work is rolled back.
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF
SET FEEDBACK OFF
SET SQLFORMAT

DEFINE target_mb = 128

SPOOL logs/01_vector_memory.log

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT
PROMPT === Current state ===
SHOW PARAMETER vector_memory_size

COLUMN next_script NEW_VALUE next_script NOPRINT
SELECT CASE
         WHEN TO_NUMBER(value) = &target_mb * 1024 * 1024
         THEN '01_vector_memory_verify.sql'
         ELSE '01_vector_memory_apply.sql'
       END AS next_script
FROM   v$parameter
WHERE  name = 'vector_memory_size';

@@&next_script

SPOOL OFF
