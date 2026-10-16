-- =============================================================================
-- 05_create_keystore.sql - Migration phase M.1, step 5 (ADR-011)
-- Creates the TDE software keystore of the CDB in united mode: keystore,
-- master keys for the root and the open PDBs (with a keystore backup), and the
-- local auto-login keystore. Runs once: stops if a keystore already exists.
--
-- The password is asked twice, hidden, and never written: VERIFY and ECHO are
-- off, the key commands run in PL/SQL (an error shows no statement text), and
-- nothing is spooled while the password is in use.
-- Password: generate it in the password manager (24+ characters, letters and
-- digits only) and store it there BEFORE running this script. The password
-- manager may clear the clipboard after a few seconds: copy the password only
-- when the prompt appears.
-- Right after the script: verify the STORED password with orapki (printed at the
-- end); a keystore whose stored password does not open it cannot be managed (P-24).
--
-- Run from the repository root:
--   sqlplus / as sysdba "@scripts/operations/05_create_keystore.sql"
-- Values: 00_config.sql. Output: <log folder>\05_create_keystore.log (no password)
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-12
-- =============================================================================

SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF ECHO OFF TRIMSPOOL ON SERVEROUTPUT ON
COLUMN wrl_parameter FORMAT A50
COLUMN status        FORMAT A22
COLUMN wallet_type   FORMAT A16
COLUMN keystore_mode FORMAT A10
COLUMN name          FORMAT A10
@@00_config.sql
WHENEVER SQLERROR EXIT FAILURE

SPOOL &emk_log_dir\05_create_keystore.log
PROMPT === 1. Context: SYS in CDB$ROOT, WALLET_ROOT set, no keystore yet
BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'SYS'
       OR SYS_CONTEXT('USERENV', 'CON_NAME') <> 'CDB$ROOT'
    THEN
        RAISE_APPLICATION_ERROR(-20000, 'Run as SYS in CDB$ROOT (sqlplus / as sysdba).');
    END IF;
    FOR r IN (SELECT value FROM v$parameter WHERE name = 'wallet_root') LOOP
        IF r.value IS NULL THEN
            RAISE_APPLICATION_ERROR(-20000, 'WALLET_ROOT is not set: run steps 2 and 3 first.');
        END IF;
    END LOOP;
END;
/

ALTER SYSTEM SET tde_configuration = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;

DECLARE
    l_status v$encryption_wallet.status%TYPE;
BEGIN
    SELECT status INTO l_status FROM v$encryption_wallet WHERE con_id = 1;
    IF l_status <> 'NOT_AVAILABLE' THEN
        RAISE_APPLICATION_ERROR(-20000,
            'A keystore already exists (status ' || l_status || '): nothing created.');
    END IF;
END;
/
SPOOL OFF

PROMPT
PROMPT Copy the keystore password from the password manager NOW.
ACCEPT keystore_pwd  CHAR PROMPT 'Keystore password: ' HIDE
ACCEPT keystore_pwd2 CHAR PROMPT 'Repeat the password: ' HIDE

PROMPT === 2. Creating the keystore, opening it, setting the master keys, auto-login
DECLARE
    l_pwd  VARCHAR2(200) := q'~&keystore_pwd~';
    l_pwd2 VARCHAR2(200) := q'~&keystore_pwd2~';
BEGIN
    IF l_pwd IS NULL OR l_pwd <> l_pwd2 THEN
        RAISE_APPLICATION_ERROR(-20000, 'The two passwords are empty or differ: nothing created.');
    END IF;
    IF LENGTH(l_pwd) < 16 OR INSTR(l_pwd, '"') > 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'Use 16+ characters and no double quotes: nothing created.');
    END IF;

    -- 1. The safe
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "' || l_pwd || '"';
    DBMS_OUTPUT.PUT_LINE('keystore created');
    -- 2. Open it for the root and all PDBs
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "' || l_pwd
                   || '" CONTAINER = ALL';
    DBMS_OUTPUT.PUT_LINE('keystore open');
    -- 3. Master keys (root and open PDBs) and a backup of the keystore
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT SET KEY USING TAG ''INITIAL'' IDENTIFIED BY "'
                   || l_pwd || '" WITH BACKUP USING ''INITIAL'' CONTAINER = ALL';
    DBMS_OUTPUT.PUT_LINE('master keys set, keystore backed up');
    -- 4. Automatic opening, valid only on this computer
    EXECUTE IMMEDIATE 'ADMINISTER KEY MANAGEMENT CREATE LOCAL AUTO_LOGIN KEYSTORE FROM KEYSTORE IDENTIFIED BY "'
                   || l_pwd || '"';
    DBMS_OUTPUT.PUT_LINE('local auto-login keystore created');
END;
/
UNDEFINE keystore_pwd
UNDEFINE keystore_pwd2

SPOOL &emk_log_dir\05_create_keystore.log APPEND
PROMPT
PROMPT === 3. Result (expected: OPEN for CDB$ROOT and &emk_pdb)
SELECT c.name, w.status, w.wallet_type, w.keystore_mode, w.wrl_parameter
FROM   v$encryption_wallet w JOIN v$containers c ON c.con_id = w.con_id
ORDER  BY w.con_id;

PROMPT
PROMPT === 4. Master keys
SELECT con_id, tag, creation_time, key_use
FROM   v$encryption_keys
ORDER  BY con_id;

PROMPT
PROMPT === 5. Keystore files (ewallet.p12 = safe, ewallet_*_INITIAL.p12 = backup, cwallet.sso = auto-login)
HOST dir /b &emk_tde_dir

PROMPT
PROMPT MANDATORY now: verify that the password stored in the password manager opens the keystore:
PROMPT   orapki wallet display -wallet &emk_tde_dir
PROMPT   (expected: Oracle Secret Store entries ORACLE.SECURITY.DB.ENCRYPTION...)
PROMPT
PROMPT Then (golden rule 1 - keys never with the data):
PROMPT   attach ewallet.p12 (NOT cwallet.sso, NOT *.lck) to the password manager entry,
PROMPT   save, and copy the password database to its off-disk copies
SPOOL OFF
EXIT
