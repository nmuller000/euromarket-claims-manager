-- =============================================================================
-- 06a_create_dev_account.sql
-- Called by 06_create_dev_user.sql only when &emk_dev_user does not exist.
-- The password is entered hidden and is never stored.
-- CREATE USER runs inside PL/SQL: if it fails (e.g. the CIS password rules),
-- the error shows no statement text, so the password never reaches the screen
-- or the log.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

-- Pause the install log during the prompt (the masked input would reveal the length)
SPOOL OFF
PROMPT Use a strong password (16+ characters, letters and digits). Copy it from the password manager only when the prompt appears.
ACCEPT emk_dev_pwd CHAR PROMPT 'Password for &emk_dev_user: ' HIDE

-- The profile is set here (not only in 06) so that its password verify
-- function also checks this first password (ADR-007)
DECLARE
    l_pwd VARCHAR2(200) := q'~&emk_dev_pwd~';
BEGIN
    IF NVL(LENGTH(l_pwd), 0) < 16 OR INSTR(l_pwd, '"') > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Use 16+ characters and no double quotes: account not created.');
    END IF;
    EXECUTE IMMEDIATE 'CREATE USER &emk_dev_user IDENTIFIED BY "' || l_pwd || '"'
                   || ' DEFAULT TABLESPACE &emk_dev_default_ts'
                   || ' TEMPORARY TABLESPACE &emk_temp_ts'
                   || ' PROFILE &emk_dev_profile';
END;
/
UNDEFINE emk_dev_pwd

-- Resume this run's install log only after the password is gone
SPOOL &emk_log_file APPEND

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_dev_user created.');
END;
/
