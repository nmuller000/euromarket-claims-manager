-- =============================================================================
-- rotate_password.sql
-- Changes the password of an account of the project that has one:
--   &emk_dev_user (DEV, person), &emk_deploy_user (deployment), ORDS_PUBLIC_USER
--   (ORDS; its password is also stored in the ORDS configuration).
-- Run before the password expires (check_password_expiry.sql), or after it has
-- expired or the account was locked (the account is unlocked here as well).
-- The new password is entered hidden and never shown or stored, even if the
-- change fails (00_set_password.sql). The new password is then proved by
-- logging in with it. Replaces rotate_ords_password.sql.
--
-- Run from the repository root as SYS in the PDB of the environment, e.g. DEV:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/rotate_password.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04 (as rotate_ords_password.sql); all accounts since 2026-10-13
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC or PROD): '
@@00_config.sql
@@00_check_context.sql

PROMPT
PROMPT Accounts with a password: &emk_dev_user (DEV only), &emk_deploy_user, ORDS_PUBLIC_USER
ACCEPT emk_rot_user CHAR PROMPT 'Account: '
SET TERMOUT OFF
COLUMN cfg_rot NEW_VALUE emk_rot_user NOPRINT
SELECT UPPER(TRIM('&emk_rot_user')) AS cfg_rot FROM dual;
SET TERMOUT ON

DECLARE
    l_count PLS_INTEGER;
BEGIN
    IF '&emk_rot_user' NOT IN (UPPER('&emk_dev_user'), UPPER('&emk_deploy_user'), 'ORDS_PUBLIC_USER') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Account &emk_rot_user is not rotated by this script.');
    END IF;
    SELECT COUNT(*) INTO l_count FROM dba_users
    WHERE  username = '&emk_rot_user' AND authentication_type = 'PASSWORD';
    IF l_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Account &emk_rot_user does not exist in &emk_pdb or has no password.');
    END IF;
END;
/

SET SQLFORMAT ansiconsole
PROMPT
PROMPT === Before ===
SELECT username, account_status, TO_CHAR(expiry_date, 'YYYY-MM-DD') AS expiry_date,
       TRUNC(expiry_date - SYSDATE) AS days_left, profile
FROM   dba_users WHERE username = '&emk_rot_user';
SET SQLFORMAT

PROMPT
PROMPT === New password ===
DEFINE emk_pwd_prompt    = "New password for &emk_rot_user"
DEFINE emk_pwd_stmt_head = "ALTER USER &emk_rot_user"
DEFINE emk_pwd_stmt_tail = " ACCOUNT UNLOCK"
@@00_set_password.sql
PROMPT Password changed.

SET SQLFORMAT ansiconsole
PROMPT
PROMPT === After ===
SELECT username, account_status, TO_CHAR(expiry_date, 'YYYY-MM-DD') AS expiry_date,
       TRUNC(expiry_date - SYSDATE) AS days_left, profile
FROM   dba_users WHERE username = '&emk_rot_user';
SET SQLFORMAT

PROMPT
PROMPT === Verification: log in as &emk_rot_user with the new password ===
PROMPT Copy the new password from the password manager AGAIN NOW (the clipboard may
PROMPT have been cleared) and paste it at the prompt below.
WHENEVER SQLERROR CONTINUE
CONNECT &emk_rot_user@//&emk_db_address/&emk_pdb
SELECT 'OK: logged in as ' || USER AS verification FROM dual;
DISCONNECT
PROMPT
PROMPT Result of the verification:
PROMPT   "OK: logged in as &emk_rot_user"  -> the stored password works.
PROMPT   SP2-0640 or ORA-01017             -> NOT verified: the paste was empty or different.
PROMPT     Test it with:  sql -thin &emk_rot_user@&emk_db_address/&emk_pdb
PROMPT     If that fails too, run this script again with a new password.

PROMPT
PROMPT === Next steps for &emk_rot_user ===
PROMPT   ORDS_PUBLIC_USER: 1. stop ORDS (Ctrl+C in its window)
PROMPT                     2. &emk_ords_exe --config &emk_ords_config config secret db.password
PROMPT                        (enter the same new password)
PROMPT                     3. start ORDS and open APEX
PROMPT   &emk_deploy_user: update its secret (here the password manager; in a company the
PROMPT                     secret store of the deployment pipeline)
PROMPT   &emk_dev_user:    update the password manager and any saved connection (VS Code)
PROMPT   All:              store the new password in the password manager first, then copy
PROMPT                     the password database to its off-disk copies
PROMPT
EXIT
