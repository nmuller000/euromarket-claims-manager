-- =============================================================================
-- 00_config.sql - Settings of the operations scripts (ADR-010, ADR-011)
-- Single place for every value the scripts use. No machine-specific path is
-- written here: paths are derived from the database at run time, so the same
-- scripts serve every environment (ADR-009).
-- Called first by each script (@@00_config.sql), connected as SYS in CDB$ROOT.
-- Read only: it changes nothing.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET VERIFY OFF FEEDBACK OFF

-- -----------------------------------------------------------------------------
-- 1. Settings (project decisions)
-- -----------------------------------------------------------------------------
-- PDB used for checks and lab objects
DEFINE emk_pdb           = FREEPDB1
-- Fast recovery area size (setup.md §1.1)
DEFINE emk_fra_size      = 30G
-- Seconds between forced log switches (ADR-010)
DEFINE emk_archive_lag   = 1800
-- Tablespace encryption algorithm (ADR-011)
DEFINE emk_tde_algorithm = AES256
-- Lab objects (drills only, dropped at the end of each drill)
DEFINE emk_lab_ts        = LAB_TS
DEFINE emk_lab_user      = LAB_OWNER
DEFINE emk_lab_rows      = 1000
-- Log folder, relative to the repository root (not versioned)
DEFINE emk_log_dir       = logs\operations

-- -----------------------------------------------------------------------------
-- 2. Derived from the database (no fixed paths)
-- -----------------------------------------------------------------------------
SET TERMOUT OFF
COLUMN cfg_oracle_base NEW_VALUE emk_oracle_base NOPRINT
COLUMN cfg_db_name     NEW_VALUE emk_db_name     NOPRINT
COLUMN cfg_data_dir    NEW_VALUE emk_cdb_data_dir NOPRINT
-- ORACLE_BASE = base of the Automatic Diagnostic Repository (diagnostic_dest)
SELECT value AS cfg_oracle_base FROM v$diag_info WHERE name = 'ADR Base';
SELECT name  AS cfg_db_name     FROM v$database;
-- folder of the CDB data files (from the first data file)
SELECT SUBSTR(name, 1, INSTR(name, '\', -1) - 1) AS cfg_data_dir FROM v$datafile WHERE file# = 1;

-- Oracle's default locations under ORACLE_BASE (used when the parameter is not set yet)
DEFINE emk_wallet_default = &emk_oracle_base\admin\&emk_db_name\wallet
DEFINE emk_fra_default    = &emk_oracle_base\fast_recovery_area

COLUMN cfg_wallet_root NEW_VALUE emk_wallet_root NOPRINT
COLUMN cfg_fra_dir     NEW_VALUE emk_fra_dir     NOPRINT
SELECT NVL((SELECT value FROM v$parameter WHERE name = 'wallet_root'),
           '&emk_wallet_default') AS cfg_wallet_root FROM dual;
SELECT NVL((SELECT value FROM v$parameter WHERE name = 'db_recovery_file_dest'),
           '&emk_fra_default') AS cfg_fra_dir FROM dual;

DEFINE emk_tde_dir     = &emk_wallet_root\tde
DEFINE emk_tde_new_dir = &emk_wallet_root\tde_new
DEFINE emk_tde_old_dir = &emk_wallet_root\tde_old
DEFINE emk_bct_file    = &emk_cdb_data_dir\&emk_db_name._BCT.CTF
DEFINE emk_lab_dir     = &emk_cdb_data_dir\lab
SET TERMOUT ON

HOST mkdir &emk_log_dir 2>NUL

PROMPT === Configuration (00_config.sql)
PROMPT   PDB ............... &emk_pdb
PROMPT   ORACLE_BASE ....... &emk_oracle_base
PROMPT   WALLET_ROOT ....... &emk_wallet_root
PROMPT   keystore folder ... &emk_tde_dir
PROMPT   recovery area ..... &emk_fra_dir (&emk_fra_size)
PROMPT   block tracking .... &emk_bct_file
PROMPT   lab folder ........ &emk_lab_dir
PROMPT   logs .............. &emk_log_dir
SET FEEDBACK ON
