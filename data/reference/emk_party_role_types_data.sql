-- =============================================================================
-- emk_party_role_types_data.sql
-- EMK_PARTY_ROLE_TYPES: the roles a company can play (D-68, BR-16).
-- Sources: CMR Convention (UNECE) for sender, consignee and carrier;
-- UN/EDIFACT code list 3035 for the codes CZ, CN, CA, FW
-- (data-model-operational.md §2a). SENDER, CONSIGNEE and CARRIER are used by
-- the program (BR-16): they are retired only together with a code change.
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

MERGE INTO emk_data.emk_party_role_types t
USING (VALUES
        ('SENDER',    'Sender',    'Sender of the goods (CMR Art. 6(1)(b), 7)', 10, CAST(NULL AS DATE)),
        ('CONSIGNEE', 'Consignee', 'Receiver of the goods (CMR Art. 13, 30)', 20, CAST(NULL AS DATE)),
        ('CARRIER',   'Carrier',   'Carrier liable for loss, damage and delay (CMR Art. 17)', 30, CAST(NULL AS DATE)),
        ('FORWARDER', 'Forwarder', 'Freight forwarder that arranges the carriage', 40, CAST(NULL AS DATE)),
        ('INSURER',   'Insurer',   'Insurer of the goods or of the carrier''s liability', 50, CAST(NULL AS DATE)),
        ('SURVEYOR',  'Surveyor',  'Expert who inspects the damage (joint check, CMR Art. 30(2))', 60, CAST(NULL AS DATE))
      ) s (role_code, name, description, sort_order, valid_to)
ON (t.role_code = s.role_code)
WHEN NOT MATCHED THEN INSERT
    (role_code, name, description, sort_order, valid_to)
VALUES
    (s.role_code, s.name, s.description, s.sort_order, s.valid_to);

COMMIT;
