-- =============================================================================
-- install_admin.sql
-- Orchestrator for the admin layer (ADR-005). Calls admin scripts only.
-- Idempotent: running it again reports "already exists" and changes nothing.
--
-- Run from the repository root as SYS in FREEPDB1 (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/install_admin.sql
--
-- Passwords and personal data (EMK_DEV password, workspace administrator)
-- are asked only when the object is created, and never stored.
-- Not included: 01_vector_memory.sql and 02_account_hardening.sql
-- (environment hardening, run separately; see docs/setup.md).
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

-- One log per run (logs/install_admin_YYYYMMDD_HH24MISS.log), so earlier runs are kept
COLUMN log_file NEW_VALUE emk_log_file NOPRINT
SELECT 'logs/install_admin_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS log_file FROM dual;
SPOOL &emk_log_file

@@admin/00_config.sql
@@admin/00_check_context.sql

PROMPT
PROMPT === 1/6 Tablespaces ===
@@admin/03_create_tablespace.sql

PROMPT
PROMPT === 2/6 Roles ===
@@admin/04_create_roles.sql

PROMPT
PROMPT === 3/6 Schemas (application and integration) ===
@@admin/05_create_schema.sql

PROMPT
PROMPT === 4/6 Developer account ===
@@admin/06_create_dev_user.sql

PROMPT
PROMPT === 5/6 APEX workspace ===
@@admin/07_create_workspace.sql

PROMPT
PROMPT === 6/6 Network access (ACL) ===
@@admin/08_network_acl.sql

PROMPT
PROMPT === Verification ===
@@admin/verify_admin.sql

SPOOL OFF
