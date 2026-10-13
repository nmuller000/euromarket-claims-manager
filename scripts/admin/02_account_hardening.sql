-- =============================================================================
-- 02_account_hardening.sql
-- Applies account best practices in the PDB of the environment (00_config.sql):
--   1. Locks PDBADMIN (installation admin account, not used).
--   2. Converts the proxy-only account APEX_PUBLIC_USER to schema-only (NO AUTHENTICATION):
--      no password, no expiry, no direct logins; ORDS proxy access still works.
--   3. Rotates the ORDS_PUBLIC_USER password (entered hidden, never stored or
--      shown, also if the change fails: 00_set_password.sql).
--
-- Run as SYS in the PDB of the environment with ORDS stopped (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/02_account_hardening.sql
--
-- Afterwards update ORDS with the same new password (command printed at the end).
--
-- Rollback (if an APEX workspace stops working):
--   ALTER USER <account> IDENTIFIED BY "<new password>";
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE
SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC or PROD): '
@@00_config.sql
@@00_check_context.sql

PROMPT
PROMPT === Step 1/3: lock PDBADMIN ===
ALTER USER PDBADMIN ACCOUNT LOCK;

PROMPT
PROMPT === Step 2/3: proxy-only accounts -> schema-only (NO AUTHENTICATION) ===
ALTER USER APEX_PUBLIC_USER NO AUTHENTICATION;

PROMPT
PROMPT === Step 3/3: rotate ORDS_PUBLIC_USER password ===
DEFINE emk_pwd_prompt    = "New password for ORDS_PUBLIC_USER"
DEFINE emk_pwd_stmt_head = "ALTER USER ORDS_PUBLIC_USER"
DEFINE emk_pwd_stmt_tail = ""
@@00_set_password.sql

SET SQLFORMAT ansiconsole
PROMPT
PROMPT === Result ===
SELECT username,
       account_status,
       TO_CHAR(expiry_date, 'YYYY-MM-DD') AS expiry_date,
       authentication_type
FROM   dba_users
WHERE  username IN ('PDBADMIN', 'APEX_PUBLIC_USER', 'ORDS_PUBLIC_USER')
ORDER  BY username;

PROMPT
PROMPT Next: &emk_ords_exe --config &emk_ords_config config secret db.password
PROMPT (same new password), then start ORDS. Store the password in the password manager.

SET SQLFORMAT
SET FEEDBACK ON
