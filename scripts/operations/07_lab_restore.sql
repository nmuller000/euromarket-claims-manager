-- =============================================================================
-- 07_lab_restore.sql - Migration phase M.1, step 7 (DEV only, lab objects only)
-- 1. Checks that the level 0 backup pieces are encrypted.
-- 2. T-M1-35 (visible proof): a known text is readable in the data file of an
--    unencrypted tablespace and not in the data file of an encrypted one.
-- 3. Small restore drill: the lab tablespace is backed up, its data file deleted,
--    restored and recovered by RMAN; all lab rows must come back.
-- 4. Removes the lab objects, the lab backup and the unencrypted cold backup.
-- Never touches project objects: only the lab tablespace, the lab user, and one
-- lab table in the unencrypted USERS tablespace of the PDB.
--
-- Run from the repository root (ORDS may stay up):
--   sqlplus / as sysdba "@scripts/operations/07_lab_restore.sql"
-- Values: 00_config.sql. Output: <log folder>\07_lab_restore.log, 07a_lab_backup.log, 07b_lab_restore.log
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON SERVEROUTPUT ON
COLUMN tag             FORMAT A24
COLUMN tablespace_name FORMAT A16
COLUMN result          FORMAT A40
@@00_config.sql
WHENEVER SQLERROR EXIT FAILURE
HOST mkdir &emk_lab_dir 2>NUL
SPOOL &emk_log_dir\07_lab_restore.log

PROMPT === 1. Backup pieces and their encryption (expected: LEVEL0 and LEVEL0_ARCH ENCRYPTED = YES)
SELECT tag, encrypted, COUNT(*) AS pieces
FROM   v$backup_piece
WHERE  tag IN ('LEVEL0', 'LEVEL0_ARCH', 'COLD_NOARCHIVELOG') AND status = 'A'
GROUP  BY tag, encrypted
ORDER  BY tag;

PROMPT
PROMPT === 2. Lab objects in &emk_pdb
ALTER SESSION SET CONTAINER = &emk_pdb;

CREATE TABLESPACE &emk_lab_ts DATAFILE '&emk_lab_dir\&emk_lab_ts.01.DBF' SIZE 20M
  ENCRYPTION USING '&emk_tde_algorithm' ENCRYPT;
CREATE USER &emk_lab_user NO AUTHENTICATION DEFAULT TABLESPACE &emk_lab_ts
  QUOTA UNLIMITED ON &emk_lab_ts QUOTA 10M ON users;

-- Encrypted: lab rows with a known text
CREATE TABLE &emk_lab_user..lab_rows TABLESPACE &emk_lab_ts AS
SELECT LEVEL AS id, 'PRUEBA-CIFRADO-12345' AS marker, SYSTIMESTAMP AS created_at
FROM   dual CONNECT BY LEVEL <= &emk_lab_rows;
-- Not encrypted (USERS was created before AUTO_ENABLE): the same text, for comparison
CREATE TABLE &emk_lab_user..lab_plain TABLESPACE users AS
SELECT 'PRUEBA-CIFRADO-12345' AS marker FROM dual;
-- CREATE TABLE AS SELECT writes the blocks directly to the data files (direct path)

SELECT tablespace_name, encrypted FROM dba_tablespaces
WHERE  tablespace_name IN (UPPER('&emk_lab_ts'), 'USERS') ORDER BY tablespace_name;

-- data file of USERS in this PDB (derived, no fixed path)
COLUMN cfg_users_file NEW_VALUE emk_users_file NOPRINT
SET FEEDBACK OFF
SELECT file_name AS cfg_users_file FROM dba_data_files WHERE tablespace_name = 'USERS' AND ROWNUM = 1;
SET FEEDBACK ON

PROMPT
PROMPT === 3. T-M1-35 part 1: unencrypted USERS (the open file is copied with Oracle's ocopy)
PROMPT --- expected: the name of the copy is printed (text found = readable without the database)
HOST ocopy &emk_users_file &emk_lab_dir\USERS_COPY.DBF
HOST findstr /m /c:"PRUEBA-CIFRADO-12345" &emk_lab_dir\USERS_COPY.DBF
HOST del &emk_lab_dir\USERS_COPY.DBF

PROMPT
PROMPT === 4. Restore drill: backup of the lab tablespace
SELECT TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS') AS start_time FROM dual;
HOST rman target / log=&emk_log_dir\07a_lab_backup.log cmdfile=scripts\operations\07a_lab_backup.rman using &emk_pdb &emk_lab_ts

PROMPT === 5. Lab tablespace offline (its file is now closed)
ALTER TABLESPACE &emk_lab_ts OFFLINE IMMEDIATE;
PROMPT --- T-M1-35 part 2: encrypted lab tablespace; expected: NOTHING printed (text not readable)
HOST findstr /m /c:"PRUEBA-CIFRADO-12345" &emk_lab_dir\&emk_lab_ts.01.DBF
PROMPT --- end of T-M1-35
PROMPT === Simulated loss: data file deleted
HOST del &emk_lab_dir\&emk_lab_ts.01.DBF
HOST if exist &emk_lab_dir\&emk_lab_ts.01.DBF (echo FILE STILL EXISTS) else (echo data file deleted)

PROMPT === 6. RMAN restore and recover of the lab tablespace
HOST rman target / log=&emk_log_dir\07b_lab_restore.log cmdfile=scripts\operations\07b_lab_restore.rman using &emk_pdb &emk_lab_ts

ALTER TABLESPACE &emk_lab_ts ONLINE;
SELECT TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS') AS end_time FROM dual;

PROMPT === 7. Result (expected: &emk_lab_rows rows, PASS)
SELECT COUNT(*) AS rows_back,
       CASE WHEN COUNT(*) = &emk_lab_rows THEN 'PASS: restore drill succeeded'
            ELSE 'FAIL' END AS result
FROM   &emk_lab_user..lab_rows;

PROMPT
PROMPT === 8. Clean-up of the lab objects
DROP USER &emk_lab_user CASCADE;
DROP TABLESPACE &emk_lab_ts INCLUDING CONTENTS AND DATAFILES;

SPOOL OFF
EXIT
