-- =============================================================================
-- 09b_reset_session.sql
-- Restores session settings after the official utPLSQL scripts, which change
-- them (heading, page size, current schema, error handling).
-- =============================================================================

ALTER SESSION SET CURRENT_SCHEMA = SYS;
SET TERMOUT ON
SET HEADING ON
SET PAGESIZE 100
SET LINESIZE 200
SET DEFINE ON
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON
SET SQLFORMAT DEFAULT
WHENEVER SQLERROR EXIT FAILURE
WHENEVER OSERROR CONTINUE
