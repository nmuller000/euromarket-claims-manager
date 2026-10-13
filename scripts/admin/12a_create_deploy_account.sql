-- =============================================================================
-- 12a_create_deploy_account.sql
-- Called by 12_create_deploy_user.sql only when &emk_deploy_user does not exist.
-- The password is entered hidden and is never stored. In a company it is kept
-- in the secret store of the deployment pipeline; here in the password manager.
-- CREATE USER runs inside PL/SQL: if it fails (e.g. password rules), the error
-- shows no statement text, so the password never reaches the screen or the log.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

-- Pause the install log during the prompt (the masked input would reveal the length)
SPOOL OFF
PROMPT Password for the deployment account: generate it in the password manager first
PROMPT (16+ characters, letters and digits only) and copy it only when the prompt appears.
ACCEPT emk_deploy_pwd CHAR PROMPT 'Password for &emk_deploy_user: ' HIDE

DECLARE
    l_pwd VARCHAR2(200) := q'~&emk_deploy_pwd~';
BEGIN
    IF NVL(LENGTH(l_pwd), 0) < 16 OR INSTR(l_pwd, '"') > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Use 16+ characters and no double quotes: account not created.');
    END IF;
    EXECUTE IMMEDIATE 'CREATE USER &emk_deploy_user IDENTIFIED BY "' || l_pwd || '"'
                   || ' DEFAULT TABLESPACE &emk_data_ts'
                   || ' TEMPORARY TABLESPACE &emk_temp_ts'
                   || ' PROFILE &emk_deploy_profile';
END;
/
UNDEFINE emk_deploy_pwd

-- Resume this run's install log only after the password is gone
SPOOL &emk_log_file APPEND

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_deploy_user created.');
END;
/
