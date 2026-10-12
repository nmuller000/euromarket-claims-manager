-- =============================================================================
-- 09a_keystore_merge.sql - Recovery runbook S7, step 1 of 2
-- Recovery of a keystore whose password is unknown (ADR-011, "password lost,
-- files present"): the master keys are copied from the working local
-- auto-login keystore (cwallet.sso in the keystore folder, no password needed)
-- into a new password keystore in the folder tde_new. The database keeps
-- running with the old keystore; nothing is swapped yet (09b).
--
-- Before (paths printed by 00_config.sql: "keystore folder" and its sibling tde_new):
--   orapki wallet create  -wallet <WALLET_ROOT>\tde_new
--   icacls <WALLET_ROOT>\tde_new\ewallet.p12 /reset
--   orapki wallet display -wallet <WALLET_ROOT>\tde_new
-- orapki leaves the file readable by its creator only; without icacls the
-- database service cannot read it (ORA-46626, P-25). The last command proves the
-- new password stored in the password manager.
-- The backup written by WITH BACKUP is a copy of the EMPTY target: after the
-- merge, the keys are in tde_new\ewallet.p12.
--
-- Run from the repository root:
--   sqlplus / as sysdba "@scripts/operations/09a_keystore_merge.sql"
-- Then check with orapki that tde_new contains the keys.
-- Values: 00_config.sql. Output: <log folder>\09a_keystore_merge.log (no password)
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
SPOOL &emk_log_dir\09a_keystore_merge.log

PROMPT === 0. Current keystore (expected: OPEN / LOCAL_AUTOLOGIN) and files
SELECT c.name, w.status, w.wallet_type
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;
HOST dir /b &emk_tde_dir
HOST dir /b &emk_tde_new_dir
SPOOL OFF

PROMPT
PROMPT Copy the NEW keystore password from the password manager NOW.
ACCEPT keystore_pwd CHAR PROMPT 'New keystore password: ' HIDE
DECLARE
    l_pwd VARCHAR2(200) := q'~&keystore_pwd~';
BEGIN
    IF NVL(LENGTH(l_pwd), 0) < 8 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Password empty or too short ('
            || NVL(LENGTH(l_pwd), 0) || ' characters): the clipboard may be empty. Nothing changed.');
    END IF;
    -- Source without IDENTIFIED BY = its auto-login keystore (cwallet.sso)
    EXECUTE IMMEDIATE q'[ADMINISTER KEY MANAGEMENT MERGE KEYSTORE '&emk_tde_dir' ]'
                   || q'[INTO EXISTING KEYSTORE '&emk_tde_new_dir' ]'
                   || 'IDENTIFIED BY "' || l_pwd || '" WITH BACKUP USING ''MERGE''';
    DBMS_OUTPUT.PUT_LINE('keys merged into tde_new');
END;
/
UNDEFINE keystore_pwd

SPOOL &emk_log_dir\09a_keystore_merge.log APPEND
PROMPT === 1. Keys merged into tde_new; files now:
HOST dir /b &emk_tde_new_dir
PROMPT
PROMPT Next: check with orapki (new password); expected: entries
PROMPT ORACLE.SECURITY.DB.ENCRYPTION... under "Oracle Secret Store entries":
PROMPT   orapki wallet display -wallet &emk_tde_new_dir
SPOOL OFF
EXIT
