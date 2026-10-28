-- =============================================================================
-- emk_claim_statuses_data.sql
-- EMK_CLAIM_STATUSES: the statuses of the claim state machine (D-68,
-- spec §4). RESOLVED, REJECTED and ESCALATED are final. The transitions are
-- program logic of EMK_CLAIM_API (BR-01): a status is added or retired only
-- together with a code change.
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

MERGE INTO emk_data.emk_claim_statuses t
USING (VALUES
        ('DRAFT',        'Draft',        'Registered, not yet submitted to the carrier', 10, 'N', CAST(NULL AS DATE)),
        ('SUBMITTED',    'Submitted',    'Written claim sent to the carrier', 20, 'N', CAST(NULL AS DATE)),
        ('UNDER_REVIEW', 'Under review', 'The carrier is reviewing the claim', 30, 'N', CAST(NULL AS DATE)),
        ('NEGOTIATION',  'Negotiation',  'Amount under negotiation with the carrier', 40, 'N', CAST(NULL AS DATE)),
        ('RESOLVED',     'Resolved',     'Accepted in full or settled by agreement', 50, 'Y', CAST(NULL AS DATE)),
        ('REJECTED',     'Rejected',     'Rejected by the carrier', 60, 'Y', CAST(NULL AS DATE)),
        ('ESCALATED',    'Escalated',    'Handed over to legal handling', 70, 'Y', CAST(NULL AS DATE))
      ) s (status_code, name, description, sort_order, final_yn, valid_to)
ON (t.status_code = s.status_code)
WHEN NOT MATCHED THEN INSERT
    (status_code, name, description, sort_order, final_yn, valid_to)
VALUES
    (s.status_code, s.name, s.description, s.sort_order, s.final_yn, s.valid_to);

COMMIT;
