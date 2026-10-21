-- =============================================================================
-- emk_claim_types_data.sql
-- EMK_CLAIM_TYPES: kinds of CMR claims (D-68, spec v1.5). Total and partial
-- loss have different limitation rules (spec §5); the apparent-damage flag
-- applies to partial loss and damage only (EMK_CLAIMS_APPARENT_CK, CMR
-- Art. 30). Types are program logic: added or retired only together with a
-- code change. Source: CMR Convention (UNECE), Art. 17, 19, 20, 30, 32.
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

MERGE INTO emk_data.emk_claim_types t
USING (VALUES
        ('TOTAL_LOSS',   'Total loss',   'The goods were not delivered (CMR Art. 17, 20)', 10, CAST(NULL AS DATE)),
        ('PARTIAL_LOSS', 'Partial loss', 'Part of the goods is missing (CMR Art. 17, 30)', 20, CAST(NULL AS DATE)),
        ('DAMAGE',       'Damage',       'The goods arrived damaged (CMR Art. 17, 30)', 30, CAST(NULL AS DATE)),
        ('DELAY',        'Delay',        'Delivery after the agreed time-limit (CMR Art. 19, 30(3))', 40, CAST(NULL AS DATE))
      ) s (claim_type, name, description, sort_order, valid_to)
ON (t.claim_type = s.claim_type)
WHEN NOT MATCHED THEN INSERT
    (claim_type, name, description, sort_order, valid_to)
VALUES
    (s.claim_type, s.name, s.description, s.sort_order, s.valid_to);

COMMIT;
