-- =============================================================================
-- emk_file_types_data.sql
-- EMK_FILE_TYPES: allowlist of file types for claim documents (D-68, BR-18;
-- OWASP ASVS 5.0 V5.1.1, V5.2.2): only the types the business needs, each
-- with the signature (first bytes) that its content must start with.
-- Sources: IANA media types (RFC 8118 for application/pdf); signatures:
--   application/pdf  %PDF-      25 50 44 46 2D           ISO 32000-2 §7.5.2 (file header)
--   image/jpeg       SOI + FF   FF D8 FF                 ITU-T T.81 Annex B (SOI marker X'FFD8',
--                                                         then the next marker, which starts with X'FF')
--   image/png        PNG sig.   89 50 4E 47 0D 0A 1A 0A  W3C PNG Specification §5.2
-- Catalog (D-72): a developer adds a type with documented criteria (business
-- need, official signature, passive format, not a container), reviewed in a
-- pull request; a new type is inserted with valid_from NULL (not allowed) and
-- the administrator allows it in the master data pages. The three initial
-- types are allowed from the start (valid_from 1900-01-01, as other lists).
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql
-- before emk_file_extensions_data.sql.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-18 (M1a step 7.6)
-- =============================================================================

MERGE INTO emk_data.emk_file_types t
USING (VALUES
        ('application/pdf', 'PDF document', HEXTORAW('255044462D'),       DATE '1900-01-01'),
        ('image/jpeg',      'JPEG image',   HEXTORAW('FFD8FF'),           DATE '1900-01-01'),
        ('image/png',       'PNG image',    HEXTORAW('89504E470D0A1A0A'), DATE '1900-01-01')
      ) s (mime_type, name, signature, valid_from)
ON (t.mime_type = s.mime_type)
WHEN NOT MATCHED THEN INSERT
    (mime_type, name, signature, valid_from)
VALUES
    (s.mime_type, s.name, s.signature, s.valid_from);

COMMIT;
