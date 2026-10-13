-- =============================================================================
-- 10a_create_data_folder.sql
-- Called by 10_create_encrypted_ts.sql only when the client runs on the
-- database server: creates the data folder of the environment if missing.
-- Do not run directly.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

HOST mkdir "&emk_datafile_dir" 2>NUL
PROMPT Data folder &emk_datafile_dir is present.
