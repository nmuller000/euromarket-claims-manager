-- =============================================================================
-- 08_test_autologin_loss.sql - Test T-M1-36 (two restarts, DEV, lab objects only)
-- Proves that losing the auto-login file (cwallet.sso) loses no data:
--   1. Lab table in an encrypted lab tablespace.
--   2. cwallet.sso renamed (simulated loss), database restarted.
--   3. Expected: keystore CLOSED, reading the table fails with ORA-28365.
--   4. Recovery: open the keystore WITH THE PASSWORD first, then recreate the
--      local auto-login. (Creating the auto-login while the keystore is closed
--      fails with ORA-46634 and an empty location - found on 2026-10-12, P-24.)
--   5. Restart: keystore OPEN / LOCAL_AUTOLOGIN without password, rows readable.
--   6. Clean-up of the lab objects and of the renamed file.
-- The same recovery (steps 4-5) applies in production when cwallet.sso is lost.
-- Fallback if step 4 fails: rename cwallet.sso.t36 back to cwallet.sso, restart.
--
-- Run from the repository root (ORDS stopped):
--   sqlplus / as sysdba "@scripts/operations/08_test_autologin_loss.sql"
-- Values: 00_config.sql. Output: <log folder>\08_test_autologin_loss.log (no password)
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF ECHO OFF TRIMSPOOL ON SERVEROUTPUT ON
COLUMN name        FORMAT A10
COLUMN status      FORMAT A22
COLUMN wallet_type FORMAT A16
COLUMN result      FORMAT A50
@@00_config.sql
WHENEVER SQLERROR EXIT FAILURE
HOST mkdir &emk_lab_dir 2>NUL

PROMPT This script restarts the CDB. ORDS must be stopped first (Ctrl+C in its window).
ACCEPT ords_stopped CHAR PROMPT 'Is ORDS stopped? (Y/N): '
BEGIN
    IF UPPER('&ords_stopped') <> 'Y' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Stop ORDS first, then run the script again. Nothing changed.');
    END IF;
END;
/

SPOOL &emk_log_dir\08_test_autologin_loss.log
PROMPT === 1. Lab table in an encrypted tablespace (&emk_pdb)
ALTER SESSION SET CONTAINER = &emk_pdb;
CREATE TABLESPACE &emk_lab_ts DATAFILE '&emk_lab_dir\&emk_lab_ts.01.DBF' SIZE 20M
  ENCRYPTION USING '&emk_tde_algorithm' ENCRYPT;
CREATE USER &emk_lab_user NO AUTHENTICATION DEFAULT TABLESPACE &emk_lab_ts QUOTA UNLIMITED ON &emk_lab_ts;
CREATE TABLE &emk_lab_user..lab_rows TABLESPACE &emk_lab_ts AS
SELECT LEVEL AS id FROM dual CONNECT BY LEVEL <= &emk_lab_rows;
ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT
PROMPT === 2. Simulated loss of cwallet.sso, restart
HOST ren &emk_tde_dir\cwallet.sso cwallet.sso.t36
HOST dir /b &emk_tde_dir
SHUTDOWN IMMEDIATE
STARTUP

PROMPT
PROMPT === 3. Expected: keystore CLOSED, reading fails with ORA-28365
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;
ALTER SESSION SET CONTAINER = &emk_pdb;
WHENEVER SQLERROR CONTINUE
PROMPT --- the next statement must fail with ORA-28365 (wallet is not open):
SELECT COUNT(*) AS rows_without_keystore FROM &emk_lab_user..lab_rows;
WHENEVER SQLERROR EXIT FAILURE
ALTER SESSION SET CONTAINER = CDB$ROOT;
SPOOL OFF

PROMPT
PROMPT === 4. Recovery: open with the password, then recreate the auto-login
PROMPT Copy the keystore password from the password manager NOW.
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
    DBMS_OUTPUT.PUT_LINE('keystore open with the password');
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "'
                   || l_pwd || '"';
    DBMS_OUTPUT.PUT_LINE('local auto-login keystore recreated');
END;
/
UNDEFINE keystore_pwd

SPOOL &emk_log_dir\08_test_autologin_loss.log APPEND
PROMPT === 4. Keystore open, auto-login recreated
HOST dir /b &emk_tde_dir

PROMPT
PROMPT === 5. Restart: the keystore must open by itself, no password
SHUTDOWN IMMEDIATE
STARTUP
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;
ALTER SESSION SET CONTAINER = &emk_pdb;
SELECT COUNT(*) AS rows_back,
       CASE WHEN COUNT(*) = &emk_lab_rows THEN 'PASS: T-M1-36, no data lost'
            ELSE 'FAIL' END AS result
FROM   &emk_lab_user..lab_rows;

PROMPT
PROMPT === 6. Clean-up
DROP USER &emk_lab_user CASCADE;
DROP TABLESPACE &emk_lab_ts INCLUDING CONTENTS AND DATAFILES;
HOST del &emk_tde_dir\cwallet.sso.t36
HOST dir /b &emk_tde_dir

PROMPT
PROMPT Next: start ORDS.
SPOOL OFF
EXIT
