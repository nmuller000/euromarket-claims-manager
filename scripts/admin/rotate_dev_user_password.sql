-- =============================================================================
-- rotate_dev_user_password.sql
-- Rotates the DEV_USER password (personal development account).
-- DEV_USER is also the APEX workspace schema, but ORDS reaches it through
-- proxy authentication, so APEX and ORDS are not affected by this change.
--
-- Run as SYS in FREEPDB1 (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/rotate_dev_user_password.sql
--
-- The password is entered hidden, is never stored in files, logs or the
-- SQLcl history, and is verified by logging in as DEV_USER.
--
-- Afterwards:
--   1. Store the new password in your password manager.
--   2. Update the saved password of the DEV_USER connection in VS Code
--      (Oracle SQL Developer extension > Connections > Edit).
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
WHERE  username = 'DEV_USER';

PROMPT
PROMPT === New password ===
PROMPT Use a new strong password (16+ characters). Avoid the characters " and '
ACCEPT dev_pwd CHAR PROMPT 'New password for DEV_USER: ' HIDE
ALTER USER DEV_USER IDENTIFIED BY "&dev_pwd";
UNDEFINE dev_pwd
PROMPT Password changed.

PROMPT
PROMPT === After ===
SELECT username,
       account_status,
       TO_CHAR(expiry_date, 'YYYY-MM-DD')  AS expiry_date,
       TRUNC(expiry_date - SYSDATE)        AS days_left
FROM   dba_users
WHERE  username = 'DEV_USER';

PROMPT
PROMPT === Verification: log in as DEV_USER with the new password ===
PROMPT (Re-enter the new password. If the login fails, it was mistyped: run this script again.)
WHENEVER SQLERROR CONTINUE
CONNECT DEV_USER@localhost:1521/FREEPDB1
SELECT 'OK: logged in as ' || USER AS verification FROM dual;
DISCONNECT

PROMPT
PROMPT === Next steps ===
PROMPT   1. Store the new password in your password manager
PROMPT   2. Update the DEV_USER connection in VS Code (Oracle SQL Developer extension)
PROMPT

SET SQLFORMAT
SET FEEDBACK ON
