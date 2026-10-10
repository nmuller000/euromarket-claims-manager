-- =============================================================================
-- rotate_ords_password.sql
-- Rotates the ORDS_PUBLIC_USER password (the account ORDS uses to connect).
-- Run before the password expires (see check_password_expiry.sql).
--
-- Run as SYS in FREEPDB1 (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/rotate_ords_password.sql
--
-- The password is entered hidden, is never stored in files, logs or the
-- SQLcl history, and is verified by logging in as ORDS_PUBLIC_USER.
--
-- After this script, in PowerShell:
--   1. Stop ORDS (Ctrl + C in its window).
--   2. C:\ords\bin\ords.exe --config C:\ords\config config secret db.password
--      (enter the same new password)
--   3. Start ORDS (start_ords_apex.bat) and open APEX.
-- ORDS keeps working with its open connections until it is restarted.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF
SET FEEDBACK OFF
SET SQLFORMAT ansiconsole

PROMPT
PROMPT === Before ===
SELECT username,
       account_status,
       TO_CHAR(expiry_date, 'YYYY-MM-DD')  AS expiry_date,
       TRUNC(expiry_date - SYSDATE)        AS days_left
FROM   dba_users
WHERE  username = 'ORDS_PUBLIC_USER';

PROMPT
PROMPT === New password ===
PROMPT Use a new strong password (16+ characters). Avoid double quotes, single quotes and the ampersand character.
ACCEPT ords_pwd CHAR PROMPT 'New password for ORDS_PUBLIC_USER: ' HIDE
ALTER USER ORDS_PUBLIC_USER IDENTIFIED BY "&ords_pwd";
UNDEFINE ords_pwd
PROMPT Password changed.

PROMPT
PROMPT === After ===
SELECT username,
       account_status,
       TO_CHAR(expiry_date, 'YYYY-MM-DD')  AS expiry_date,
       TRUNC(expiry_date - SYSDATE)        AS days_left
FROM   dba_users
WHERE  username = 'ORDS_PUBLIC_USER';

PROMPT
PROMPT === Verification: log in as ORDS_PUBLIC_USER with the new password ===
PROMPT (Re-enter the new password. If the login fails, it was mistyped: run this script again.)
WHENEVER SQLERROR CONTINUE
CONNECT ORDS_PUBLIC_USER@localhost:1521/FREEPDB1
SELECT 'OK: logged in as ' || USER AS verification FROM dual;
DISCONNECT

PROMPT
PROMPT === Next steps (PowerShell) ===
PROMPT   1. Stop ORDS (Ctrl + C in its window)
PROMPT   2. C:\ords\bin\ords.exe --config C:\ords\config config secret db.password
PROMPT   3. Start ORDS (start_ords_apex.bat) and open APEX
PROMPT   4. Store the new password in your password manager
PROMPT

SET SQLFORMAT
SET FEEDBACK ON
