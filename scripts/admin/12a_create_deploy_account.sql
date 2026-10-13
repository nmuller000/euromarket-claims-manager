-- =============================================================================
-- 12a_create_deploy_account.sql
-- Called by 12_create_deploy_user.sql only when &emk_deploy_user does not exist.
-- The password is entered hidden, never stored, and never shown even if the
-- statement fails (00_set_password.sql). In a company it is kept in the secret
-- store of the deployment pipeline; here in the password manager.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

-- Pause the install log during the prompt (the masked input would reveal the length)
SPOOL OFF

DEFINE emk_pwd_prompt    = "Password for &emk_deploy_user"
DEFINE emk_pwd_stmt_head = "CREATE USER &emk_deploy_user"
DEFINE emk_pwd_stmt_tail = " DEFAULT TABLESPACE &emk_data_ts TEMPORARY TABLESPACE &emk_temp_ts PROFILE &emk_deploy_profile"
@@00_set_password.sql

-- Resume this run's install log only after the password is gone
SPOOL &emk_log_file APPEND

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_deploy_user created.');
END;
/
