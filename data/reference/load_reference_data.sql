-- =============================================================================
-- data/reference/load_reference_data.sql
-- Loads the reference data of EMK_DATA with the four idempotent MERGE scripts
-- of this folder (D-37) and shows the row counts. Running it again changes
-- nothing. Used to fill DEV after its tables are created; a release adds the
-- same scripts with `project stage add-custom` (M1 plan, open point 6).
--
-- Run from the repository root (DEV: through the proxy of the owner):
--   sql -thin "EMK_DEV[EMK_DATA]@localhost:1521/FREEPDB1" @data/reference/load_reference_data.sql
-- Output: logs\data\load_reference_data_<YYYYMMDD_HH24MISS>.log
-- Expected: countries 60, country names 60, currencies 32, currency names 32.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-16
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON

HOST powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'logs\data' | Out-Null"
SET TERMOUT OFF
COLUMN cfg_log NEW_VALUE emk_log_file
SELECT 'logs\data\load_reference_data_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.log' AS cfg_log FROM dual;
SET TERMOUT ON
SPOOL &emk_log_file
PROMPT Log of this run: &emk_log_file

ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST, ACC, PROD): '
@@../../scripts/admin/00_config.sql

BEGIN
    IF SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') NOT IN (UPPER('&emk_data_schema'), UPPER('&emk_deploy_user')) THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect as &emk_data_schema (DEV: EMK_DEV[&emk_data_schema]) or &emk_deploy_user; '
                                        || 'current schema is ' || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') || '.');
    END IF;
END;
/

PROMPT === Reference data (MERGE, idempotent)
SET FEEDBACK ON
@@emk_countries_data.sql
@@emk_country_names_data.sql
@@emk_currencies_data.sql
@@emk_currency_names_data.sql
SET FEEDBACK OFF

PROMPT === Row counts (expected 60, 60, 32, 32)
SELECT (SELECT COUNT(*) FROM &emk_data_schema..emk_countries)      AS countries,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_country_names)  AS country_names,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_currencies)     AS currencies,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_currency_names) AS currency_names
FROM   dual;

SPOOL OFF
EXIT
