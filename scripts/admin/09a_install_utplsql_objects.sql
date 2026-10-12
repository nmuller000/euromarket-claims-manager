-- =============================================================================
-- 09a_install_utplsql_objects.sql
-- Called by 09_install_utplsql.sql only when the framework is not installed.
-- Runs the official install.sql into &emk_ut3_schema (as SYS, through
-- ALTER SESSION SET CURRENT_SCHEMA: the owner never logs in). install.sql writes
-- its own install.log in the current folder and stops on any error; that log is
-- then moved to logs/install_utplsql_<timestamp>_official.log.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

PROMPT Installing utPLSQL from &emk_utplsql_src (takes a few minutes)...
SPOOL OFF
@&emk_utplsql_src/install.sql &emk_ut3_schema
@@09b_reset_session.sql

-- Move the official log out of the repository root
HOST powershell -NoProfile -Command "Move-Item -Path 'install.log' -Destination '&emk_official_file' -Force"

SPOOL &emk_log_file APPEND
PROMPT Official installer log: &emk_official_file
