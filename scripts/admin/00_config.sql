-- =============================================================================
-- 00_config.sql
-- Single place for names, paths and sizes used by the admin scripts (ADR-005).
-- No secrets here: passwords are always entered at run time.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

-- Target pluggable database
DEFINE emk_pdb          = FREEPDB1

-- Tablespace
DEFINE emk_tablespace   = EMK_DATA
DEFINE emk_datafile_dir = C:\db_files\ia_apex_project
DEFINE emk_datafile     = emk_data01.dbf
DEFINE emk_ts_initial   = 100M
DEFINE emk_ts_next      = 50M
DEFINE emk_ts_max       = 2G
DEFINE emk_temp_ts      = TEMP

-- Schemas and accounts
DEFINE emk_app_schema   = EMK_APP
DEFINE emk_dev_user     = EMK_DEV
DEFINE emk_dev_default_ts = USERS

-- Roles
DEFINE emk_owner_role   = EMK_OWNER_ROLE
DEFINE emk_dev_role     = EMK_DEVELOPER_ROLE
DEFINE emk_ro_role      = EMK_READONLY_ROLE

-- Integration schema and its tablespace (ADR-007)
DEFINE emk_int_schema     = EMK_INT
DEFINE emk_int_tablespace = EMK_INT_DATA
DEFINE emk_int_datafile   = emk_int_data01.dbf
DEFINE emk_int_ts_initial = 50M
DEFINE emk_int_ts_next    = 50M
DEFINE emk_int_ts_max     = 1G

-- Password profile for people (ADR-007; Oracle-supplied CIS baseline)
DEFINE emk_dev_profile  = ORA_CIS_PROFILE

-- APEX
DEFINE emk_workspace    = EMK_CLAIMS

-- utPLSQL (09_install_utplsql.sql; installer extracted from the release ZIP)
DEFINE emk_ut3_schema   = UT3
DEFINE emk_ut3_ts       = USERS
DEFINE emk_utplsql_src  = data/tools/utPLSQL/source
