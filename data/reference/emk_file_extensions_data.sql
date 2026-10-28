-- =============================================================================
-- emk_file_extensions_data.sql
-- EMK_FILE_EXTENSIONS: file name extensions of each file type of the catalog
-- (D-68, D-72, BR-18; OWASP ASVS 5.0 V5.2.2: the extension must be an
-- expected one and the content must match its type). Lower case, without the
-- dot. Technical: added by developers, no validity; a type is allowed or
-- retired in EMK_FILE_TYPES.
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql
-- after emk_file_types_data.sql.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-18 (M1a step 7.6)
-- =============================================================================

MERGE INTO emk_data.emk_file_extensions t
USING (VALUES
        ('jpeg', 'image/jpeg'),
        ('jpg',  'image/jpeg'),
        ('pdf',  'application/pdf'),
        ('png',  'image/png')
      ) s (file_extension, mime_type)
ON (t.file_extension = s.file_extension)
WHEN NOT MATCHED THEN INSERT
    (file_extension, mime_type)
VALUES
    (s.file_extension, s.mime_type);

COMMIT;
