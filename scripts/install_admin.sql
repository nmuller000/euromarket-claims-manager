-- =============================================================================
-- install_admin.sql
-- Orchestrator for the admin layer (ADR-005, ADR-008, ADR-009). Calls admin
-- scripts only. Idempotent: running it again reports "already exists" and
-- changes nothing.
--
-- Run from the repository root as SYS in the PDB of the environment (SQLcl,
-- thin driver), e.g. DEV:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/install_admin.sql
-- The environment (DEV, TEST, ACC, PROD) is asked first; 00_config.sql derives
-- the PDB, the data folder and whether developer access is created (DEV only).
--
-- Passwords and personal data (EMK_DEV and EMK_DEPLOY passwords, workspace
-- administrator) are asked only when the object is created, and never stored.
-- Prerequisite: the TDE keystore is open (scripts/operations, migration M.1).
-- Not included: 01_vector_memory.sql and 02_account_hardening.sql
-- (environment hardening, run separately; see docs/setup.md).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC or PROD): '

-- One log per run (logs/install_admin_<ENV>_YYYYMMDD_HH24MISS.log), so earlier runs are kept
SET TERMOUT OFF
COLUMN log_file NEW_VALUE emk_log_file NOPRINT
SELECT 'logs/install_admin_' || UPPER(TRIM('&emk_env')) || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log'
       AS log_file FROM dual;
SET TERMOUT ON
SPOOL &emk_log_file

@@admin/00_config.sql
@@admin/00_check_context.sql

COLUMN next_step NEW_VALUE next_step NOPRINT

PROMPT
PROMPT === 1/8 Roles ===
@@admin/04_create_roles.sql

PROMPT
PROMPT === 2/8 Tablespaces (encrypted; M1a single-schema tablespaces in DEV until M.4) ===
SET TERMOUT OFF
SELECT CASE '&emk_dev_access' WHEN 'Y' THEN 'admin/03_create_tablespace.sql' ELSE 'admin/00_noop.sql' END AS next_step FROM dual;
SET TERMOUT ON
@@&next_step
@@admin/10_create_encrypted_ts.sql

PROMPT
PROMPT === 3/8 Schemas (separated; M1a single schema in DEV until M.4) ===
SET TERMOUT OFF
SELECT CASE '&emk_dev_access' WHEN 'Y' THEN 'admin/05_create_schema.sql' ELSE 'admin/00_noop.sql' END AS next_step FROM dual;
SET TERMOUT ON
@@&next_step
@@admin/11_create_separated_schemas.sql

PROMPT
PROMPT === 4/8 Deployment account ===
@@admin/12_create_deploy_user.sql

PROMPT
PROMPT === 5/8 Developer account and proxies (DEV only) ===
SET TERMOUT OFF
SELECT CASE '&emk_dev_access' WHEN 'Y' THEN 'admin/06_create_dev_user.sql' ELSE 'admin/00_noop.sql' END AS next_step FROM dual;
SET TERMOUT ON
@@&next_step

PROMPT
PROMPT === 6/8 APEX workspace ===
@@admin/07_create_workspace.sql
@@admin/15_workspace_schemas.sql

PROMPT
PROMPT === 7/8 Network access (ACL) ===
@@admin/08_network_acl.sql

PROMPT
PROMPT === 8/8 Database auditing ===
@@admin/14_audit_policies.sql

PROMPT
PROMPT === Verification ===
@@admin/verify_admin.sql

SPOOL OFF
