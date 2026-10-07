-- =============================================================================
-- 06a_create_dev_account.sql
-- Called by 06_create_dev_user.sql only when &emk_dev_user does not exist.
-- The password is entered hidden and is never stored.
-- =============================================================================

-- Pause the install log during the prompt (the masked input would reveal the length)
SPOOL OFF
PROMPT Use a strong password (16+ characters). Avoid double quotes, single quotes and the ampersand character.
ACCEPT emk_dev_pwd CHAR PROMPT 'Password for &emk_dev_user: ' HIDE

-- Resume this run's install log (file name set by install_admin.sql)
SPOOL &emk_log_file APPEND

-- The profile is set here (not only in 06) so that its password verify
-- function also checks this first password (ADR-007)
CREATE USER &emk_dev_user IDENTIFIED BY "&emk_dev_pwd"
    DEFAULT TABLESPACE &emk_dev_default_ts
    TEMPORARY TABLESPACE &emk_temp_ts
    PROFILE &emk_dev_profile;

UNDEFINE emk_dev_pwd

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_dev_user created.');
END;
/
