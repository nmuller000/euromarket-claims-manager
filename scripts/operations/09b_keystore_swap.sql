-- =============================================================================
-- 09b_keystore_swap.sql - Recovery runbook S7, step 2 of 2 (two restarts)
-- Replaces the keystore with an unknown password by the merged keystore of 09a:
--   1. Restart with the folders swapped: tde -> tde_old, tde_new -> tde.
--   2. Open the keystore with the new password, recreate the local auto-login.
--   3. Restart: keystore OPEN / LOCAL_AUTOLOGIN without password.
--   4. RMAN validation of the existing encrypted backups: same master keys, so
--      they still decrypt.
-- Afterwards: copy the new ewallet.p12 to the key copies, delete tde_old.
-- Before: 09a done and orapki shows the keys in tde_new; ORDS stopped.
-- Fallback before step 2 succeeds: SHUTDOWN, move the folders back, STARTUP.
--
-- Run from the repository root:
--   sqlplus / as sysdba "@scripts/operations/09b_keystore_swap.sql"
-- Values: 00_config.sql. Output: <log folder>\09b_keystore_swap.log, 09b_validate.log (no password)
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF ECHO OFF TRIMSPOOL ON SERVEROUTPUT ON
COLUMN name        FORMAT A10
COLUMN status      FORMAT A22
COLUMN wallet_type FORMAT A16
@@00_config.sql
WHENEVER SQLERROR EXIT FAILURE

PROMPT This script restarts the CDB. ORDS must be stopped first (Ctrl+C in its window).
ACCEPT ords_stopped CHAR PROMPT 'Is ORDS stopped? (Y/N): '
BEGIN
    IF UPPER('&ords_stopped') <> 'Y' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Stop ORDS first, then run the script again. Nothing changed.');
    END IF;
END;
/

SPOOL &emk_log_dir\09b_keystore_swap.log
PROMPT === 1. Restart with the keystore folders swapped
SHUTDOWN IMMEDIATE
HOST move &emk_tde_dir &emk_tde_old_dir
HOST move &emk_tde_new_dir &emk_tde_dir
HOST dir /b &emk_wallet_root
HOST dir /b &emk_tde_dir
STARTUP
PROMPT --- expected: CLOSED (no auto-login file in the new folder yet)
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;
SPOOL OFF

PROMPT
PROMPT Copy the NEW keystore password from the password manager NOW.
ACCEPT keystore_pwd CHAR PROMPT 'Keystore password: ' HIDE
DECLARE
    l_pwd VARCHAR2(200) := q'~&keystore_pwd~';
BEGIN
    IF NVL(LENGTH(l_pwd), 0) < 8 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Password empty or too short ('
            || NVL(LENGTH(l_pwd), 0) || ' characters): the clipboard may be empty. Nothing changed.');
    END IF;
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "' || l_pwd
                   || '" CONTAINER = ALL';
    DBMS_OUTPUT.PUT_LINE('2. keystore open with the new password');
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "'
                   || l_pwd || '"';
    DBMS_OUTPUT.PUT_LINE('2. local auto-login keystore created');
END;
/
UNDEFINE keystore_pwd

SPOOL &emk_log_dir\09b_keystore_swap.log APPEND
PROMPT === 2. Keystore open with the new password, auto-login created
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;

PROMPT
PROMPT === 3. Restart: the keystore must open by itself, no password (expected: OPEN / LOCAL_AUTOLOGIN)
SHUTDOWN IMMEDIATE
STARTUP
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;

PROMPT
PROMPT === 4. The existing encrypted backups still decrypt (see 09b_validate.log)
HOST rman target / log=&emk_log_dir\09b_validate.log cmdfile=scripts\operations\09b_validate.rman
HOST findstr /c:"ORA-" /c:"RMAN-0" /c:"terminado" /c:"complete" &emk_log_dir\09b_validate.log
HOST dir /b &emk_tde_dir

PROMPT
PROMPT Next: start ORDS; attach the new ewallet.p12 to the password manager entry;
PROMPT copy the password database off-disk; then delete the old keystore folder:
PROMPT   &emk_tde_old_dir
SPOOL OFF
EXIT
