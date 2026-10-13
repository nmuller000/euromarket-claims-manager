-- =============================================================================
-- 00_config.sql
-- Single place for names, paths and sizes used by the admin scripts (ADR-005,
-- ADR-008, ADR-009, ADR-010, ADR-011). No secrets here: passwords are always
-- entered at run time. No script contains a path: every location comes from
-- here, derived from the environment where possible.
--
-- The environment (DEV, TEST, ACC, PROD) is asked by install_admin.sql and
-- uninstall_admin.sql (ACCEPT emk_env); a standalone run of verify_admin.sql
-- asks for it through the substitution prompt.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Environment (ADR-009)
-- -----------------------------------------------------------------------------
SET TERMOUT OFF
COLUMN cfg_env NEW_VALUE emk_env NOPRINT
SELECT UPPER(TRIM('&emk_env')) AS cfg_env FROM dual;
SET TERMOUT ON

BEGIN
    IF '&emk_env' NOT IN ('DEV', 'TEST', 'ACC', 'PROD') THEN
        RAISE_APPLICATION_ERROR(-20000,
            'Unknown environment "&emk_env": use DEV, TEST, ACC or PROD.');
    END IF;
END;
/

SET TERMOUT OFF
-- Target pluggable database of each environment (PROD name fixed when PROD is built)
COLUMN cfg_pdb NEW_VALUE emk_pdb NOPRINT
SELECT CASE '&emk_env'
           WHEN 'DEV'  THEN 'FREEPDB1'
           WHEN 'TEST' THEN 'EMKTEST'
           WHEN 'ACC'  THEN 'EMKACC'
           ELSE             'EMKPROD'
       END AS cfg_pdb
FROM   dual;

-- Listener address of the database server (host:port), used by test scripts that connect
DEFINE emk_db_address = localhost:1521

-- Container database (CDB) of this PDB and its Windows service (derived; used for restarts)
COLUMN cfg_cdb NEW_VALUE emk_cdb_name NOPRINT
SELECT name AS cfg_cdb FROM v$database;
DEFINE emk_win_service = OracleService&emk_cdb_name

-- Developer access (personal accounts, proxies, developer role, debugger ACL): DEV only
COLUMN cfg_dev NEW_VALUE emk_dev_access NOPRINT
SELECT CASE '&emk_env' WHEN 'DEV' THEN 'Y' ELSE 'N' END AS cfg_dev FROM dual;
SET TERMOUT ON

-- -----------------------------------------------------------------------------
-- 2. Data files of the project (D-53)
-- -----------------------------------------------------------------------------
-- Root folder of the project data files, kept apart from the folders Oracle
-- manages (oradata). On the reference machine it is a folder on the only
-- disk available: a limit of the development hardware, not a design choice. In
-- a company installation this value points to a dedicated disk or volume, so
-- that growing application data never exhausts the space of SYSTEM and SYSAUX,
-- its I/O stays isolated, and its capacity and backups are managed on their own.
DEFINE emk_datafile_root = C:\db_files

-- One subfolder per environment: <root>\emk_dev, <root>\emk_test, ...
SET TERMOUT OFF
COLUMN cfg_dir NEW_VALUE emk_datafile_dir NOPRINT
SELECT '&emk_datafile_root\emk_' || LOWER('&emk_env') AS cfg_dir FROM dual;
SET TERMOUT ON

-- Tablespaces of the separated schemas (ADR-008), encrypted (ADR-011)
DEFINE emk_data_ts         = EMK_DATA_TS
DEFINE emk_data_ts_file    = emk_data_ts01.dbf
DEFINE emk_data_ts_initial = 100M
DEFINE emk_data_ts_next    = 50M
DEFINE emk_data_ts_max     = 2G
DEFINE emk_int_ts          = EMK_INT_TS
DEFINE emk_int_ts_file     = emk_int_ts01.dbf
DEFINE emk_int_ts_initial  = 50M
DEFINE emk_int_ts_next     = 50M
DEFINE emk_int_ts_max      = 1G
DEFINE emk_tde_algorithm   = AES256
DEFINE emk_temp_ts         = TEMP

-- -----------------------------------------------------------------------------
-- 3. Schemas and accounts (ADR-007, ADR-008)
-- -----------------------------------------------------------------------------
DEFINE emk_data_schema   = EMK_DATA
DEFINE emk_api_schema    = EMK_API
DEFINE emk_ui_schema     = EMK_UI
DEFINE emk_int_schema    = EMK_INT
DEFINE emk_deploy_user   = EMK_DEPLOY
-- Service account: DEFAULT profile (an expiry or lockout would stop deployments, ADR-007)
DEFINE emk_deploy_profile = DEFAULT
-- Own space of EMK_DEPLOY for the Liquibase tables of SQLcl project
DEFINE emk_deploy_quota  = 100M
DEFINE emk_dev_user      = EMK_DEV
DEFINE emk_dev_default_ts = USERS
-- Password profile for people (ADR-007; Oracle-supplied CIS baseline)
DEFINE emk_dev_profile   = ORA_CIS_PROFILE

-- Roles
DEFINE emk_owner_role    = EMK_OWNER_ROLE
DEFINE emk_dev_role      = EMK_DEVELOPER_ROLE
DEFINE emk_ro_role       = EMK_READONLY_ROLE

-- -----------------------------------------------------------------------------
-- 4. Database auditing (ADR-010 section 3)
-- -----------------------------------------------------------------------------
DEFINE emk_aud_ddl       = EMK_AUD_DDL
DEFINE emk_aud_grants    = EMK_AUD_GRANTS
DEFINE emk_aud_sessions  = EMK_AUD_SESSIONS
-- Data changes made by the deployment account (it can read and change data, ADR-008)
DEFINE emk_aud_deploy_dml = EMK_AUD_DEPLOY_DML
DEFINE emk_audited_users = "&emk_data_schema, &emk_api_schema, &emk_int_schema, &emk_deploy_user"

-- -----------------------------------------------------------------------------
-- 5. APEX and tools
-- -----------------------------------------------------------------------------
DEFINE emk_workspace     = EMK_CLAIMS
-- ORDS (standalone): program and configuration folder of this machine
DEFINE emk_ords_exe      = C:\ords\bin\ords.exe
DEFINE emk_ords_config   = C:\ords\config
-- Vector memory pool for HNSW indexes, in MB (ADR-001)
DEFINE emk_vector_memory_mb = 128
-- utPLSQL (09_install_utplsql.sql; installer extracted from the release ZIP)
DEFINE emk_ut3_schema    = UT3
DEFINE emk_ut3_ts        = USERS
DEFINE emk_utplsql_src   = data/tools/utPLSQL/source

-- -----------------------------------------------------------------------------
-- 6. Single-schema layout of M1a steps 0-6 (DEV only; retired in migration M.4)
-- -----------------------------------------------------------------------------
DEFINE emk_app_schema     = EMK_APP
DEFINE emk_tablespace     = EMK_DATA
DEFINE emk_datafile       = emk_data01.dbf
DEFINE emk_ts_initial     = 100M
DEFINE emk_ts_next        = 50M
DEFINE emk_ts_max         = 2G
DEFINE emk_int_tablespace = EMK_INT_DATA
DEFINE emk_int_datafile   = emk_int_data01.dbf
DEFINE emk_int_ts_initial_old = 50M
DEFINE emk_int_ts_next_old    = 50M
DEFINE emk_int_ts_max_old     = 1G
DEFINE emk_legacy_datafile_dir = &emk_datafile_root\ia_apex_project

PROMPT === Configuration: environment &emk_env, PDB &emk_pdb, data files &emk_datafile_dir, developer access &emk_dev_access
