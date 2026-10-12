-- =============================================================================
-- 02_account_hardening.sql
-- Applies account best practices in FREEPDB1:
--   1. Locks PDBADMIN (installation admin account, not used).
--   2. Converts the proxy-only account APEX_PUBLIC_USER to schema-only (NO AUTHENTICATION):
--      no password, no expiry, no direct logins; ORDS proxy access still works.
--   3. Rotates the ORDS_PUBLIC_USER password (entered hidden, never stored).
--
-- Run as SYS in FREEPDB1 with ORDS stopped (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/02_account_hardening.sql
--
-- Afterwards update ORDS with the same new password:
--   C:\ords\bin\ords.exe --config C:\ords\config config secret db.password
--
-- Rollback (if an APEX workspace stops working):
--   ALTER USER <account> IDENTIFIED BY "<new password>";
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF
SET FEEDBACK OFF

PROMPT
PROMPT === Step 1/3: lock PDBADMIN ===
ALTER USER PDBADMIN ACCOUNT LOCK;

PROMPT
PROMPT === Step 2/3: proxy-only accounts -> schema-only (NO AUTHENTICATION) ===
ALTER USER APEX_PUBLIC_USER NO AUTHENTICATION;

PROMPT
PROMPT === Step 3/3: rotate ORDS_PUBLIC_USER password ===
PROMPT Use a new strong password (16+ characters). Avoid double quotes, single quotes and the ampersand character.
ACCEPT ords_pwd CHAR PROMPT 'New password for ORDS_PUBLIC_USER: ' HIDE
ALTER USER ORDS_PUBLIC_USER IDENTIFIED BY "&ords_pwd";
UNDEFINE ords_pwd

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

SET SQLFORMAT
SET FEEDBACK ON
