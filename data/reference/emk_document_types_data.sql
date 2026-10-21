-- =============================================================================
-- emk_document_types_data.sql
-- EMK_DOCUMENT_TYPES: kinds of documents attached to a claim (D-68).
-- A business list: a new kind (for example an expert opinion) is a new row,
-- a kind no longer used is closed with valid_to.
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-18 (M1a step 7.6)
-- =============================================================================

MERGE INTO emk_data.emk_document_types t
USING (VALUES
        ('CMR_NOTE',       'CMR consignment note', 'The consignment note with any reservations (CMR Art. 4-9)', 10, CAST(NULL AS DATE)),
        ('DAMAGE_REPORT',  'Damage report',        'Report of the joint check or of a surveyor (CMR Art. 30)', 20, CAST(NULL AS DATE)),
        ('PHOTO',          'Photo',                'Photo of the goods or of the damage', 30, CAST(NULL AS DATE)),
        ('INVOICE',        'Invoice',              'Commercial invoice: value of the goods (CMR Art. 23(1))', 40, CAST(NULL AS DATE)),
        ('CORRESPONDENCE', 'Correspondence',       'Reservations, written claim, answer of the carrier (CMR Art. 30, 32)', 50, CAST(NULL AS DATE)),
        ('OTHER',          'Other',                'Any other document', 90, CAST(NULL AS DATE))
      ) s (doc_type, name, description, sort_order, valid_to)
ON (t.doc_type = s.doc_type)
WHEN NOT MATCHED THEN INSERT
    (doc_type, name, description, sort_order, valid_to)
VALUES
    (s.doc_type, s.name, s.description, s.sort_order, s.valid_to);

COMMIT;
