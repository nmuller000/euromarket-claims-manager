-- =============================================================================
-- 01_vector_memory_verify.sql
-- Called by 01_vector_memory.sql. Ensures FREEPDB1 is open and reopens after
-- each restart, then verifies VECTOR_MEMORY_SIZE. Do not run directly.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT
PROMPT === FREEPDB1: open and keep open after restarts ===
BEGIN
  FOR r IN (SELECT open_mode FROM v$pdbs WHERE name = 'FREEPDB1') LOOP
    IF r.open_mode <> 'READ WRITE' THEN
      EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE FREEPDB1 OPEN';
    END IF;
  END LOOP;
END;
/
ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;

SET SQLFORMAT ansiconsole

SELECT name, open_mode FROM v$pdbs WHERE name = 'FREEPDB1';

PROMPT
PROMPT === Vector memory ===
SHOW PARAMETER vector_memory_size

SELECT pool,
       ROUND(alloc_bytes / 1024 / 1024) AS alloc_mb,
       ROUND(used_bytes  / 1024 / 1024) AS used_mb,
       con_id
FROM   v$vector_memory_pool;

PROMPT
PROMPT === Result ===
SELECT CASE
         WHEN TO_NUMBER(value) = &target_mb * 1024 * 1024
         THEN 'OK: VECTOR_MEMORY_SIZE = &target_mb.M is active'
         ELSE 'PENDING: value not active yet - run the script again from an Administrator PowerShell'
       END AS result
FROM   v$parameter
WHERE  name = 'vector_memory_size';

SET SQLFORMAT
