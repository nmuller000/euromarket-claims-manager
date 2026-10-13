-- =============================================================================
-- 06a_create_dev_account.sql
-- Called by 06_create_dev_user.sql only when &emk_dev_user does not exist.
-- The password is entered hidden, never stored, and never shown even if the
-- statement fails (00_set_password.sql). The profile is set at creation so that
-- its password rules also check this first password (ADR-007).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

-- Pause the install log during the prompt (the masked input would reveal the length)
SPOOL OFF

DEFINE emk_pwd_prompt    = "Password for &emk_dev_user"
DEFINE emk_pwd_stmt_head = "CREATE USER &emk_dev_user"
DEFINE emk_pwd_stmt_tail = " DEFAULT TABLESPACE &emk_dev_default_ts TEMPORARY TABLESPACE &emk_temp_ts PROFILE &emk_dev_profile"
@@00_set_password.sql

-- Resume this run's install log only after the password is gone
SPOOL &emk_log_file APPEND

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_dev_user created.');
END;
/
