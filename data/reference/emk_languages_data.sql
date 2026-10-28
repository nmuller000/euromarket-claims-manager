-- =============================================================================
-- emk_languages_data.sql
-- EMK_LANGUAGES: languages of Release 1 (D-68): English and German (UI
-- F-15, letters M4); a company always chooses one, there is no default (D-71). Source: ISO 639 (alpha-2 code, English name).
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql
-- before the name tables, which refer to it.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-18 (M1a step 7.6)
-- =============================================================================

MERGE INTO emk_data.emk_languages t
USING (VALUES
        ('de', 'German',  CAST(NULL AS DATE)),
        ('en', 'English', CAST(NULL AS DATE))
      ) s (language_code, name, valid_to)
ON (t.language_code = s.language_code)
WHEN NOT MATCHED THEN INSERT
    (language_code, name, valid_to)
VALUES
    (s.language_code, s.name, s.valid_to);

COMMIT;
