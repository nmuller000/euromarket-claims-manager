-- =============================================================================
-- data/reference/load_reference_data.sql
-- Loads the reference data of EMK_DATA with the idempotent MERGE scripts of
-- this folder (D-37; code lists D-68) and shows the row counts. Running it
-- again changes nothing. Order: a list before the tables that refer to it
-- (languages before the name tables, countries before VAT and postcode
-- formats, file types before extensions). Used to fill DEV after its tables
-- are created; a release adds the same scripts with `project stage
-- add-custom` (M1 plan, open point 6).
--
-- Run from the repository root (DEV: through the proxy of the owner):
--   sql -thin "EMK_DEV[EMK_DATA]@localhost:1521/FREEPDB1" @data/reference/load_reference_data.sql
-- Output: logs\data\load_reference_data_<YYYYMMDD_HH24MISS>.log
-- Expected: countries 60, VAT formats 28, postcode formats 60, country
-- names 60, currencies 32, currency names 32; languages 2, party role
-- types 6, claim statuses 7, claim types 4, document types 6, file types 3,
-- file extensions 4.
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
@@emk_languages_data.sql
@@emk_countries_data.sql
@@emk_vat_formats_data.sql
@@emk_postal_formats_data.sql
@@emk_country_names_data.sql
@@emk_currencies_data.sql
@@emk_currency_names_data.sql
@@emk_party_role_types_data.sql
@@emk_claim_statuses_data.sql
@@emk_claim_types_data.sql
@@emk_document_types_data.sql
@@emk_file_types_data.sql
@@emk_file_extensions_data.sql
SET FEEDBACK OFF

PROMPT === Row counts (expected 60, 28, 60, 60, 32, 32)
SELECT (SELECT COUNT(*) FROM &emk_data_schema..emk_countries)      AS countries,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_vat_formats)    AS vat_formats,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_postal_formats) AS postal_formats,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_country_names)  AS country_names,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_currencies)     AS currencies,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_currency_names) AS currency_names
FROM   dual;

PROMPT === Code lists (expected 2, 6, 7, 4, 6, 3, 4)
SELECT (SELECT COUNT(*) FROM &emk_data_schema..emk_languages)        AS languages,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_party_role_types) AS role_types,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_claim_statuses)   AS claim_statuses,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_claim_types)      AS claim_types,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_document_types)   AS document_types,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_file_types)       AS file_types,
       (SELECT COUNT(*) FROM &emk_data_schema..emk_file_extensions)  AS file_extensions
FROM   dual;

SPOOL OFF
EXIT
