-- =============================================================================
-- verify_admin.sql
-- Read-only checks of the admin layer for the environment of 00_config.sql
-- (M0 tests T-M0-02 and T-M0-03; M1 tests T-M1-23 (ADR-007) and T-M1-35
-- (encrypted tablespaces, ADR-011); separated schemas and deployment account
-- (ADR-008); developer access in DEV only (ADR-009); audit policies (ADR-010);
-- ORDS AutoREST). Prints PASS/FAIL per check and stops with an error if any
-- check fails.
-- Run standalone (asks for the environment); install_admin.sql runs the same
-- checks (verify_admin_checks.sql) at the end of an install:
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/verify_admin.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK OFF
@@00_config.sql

@@verify_admin_checks.sql

EXIT
