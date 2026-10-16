-- =============================================================================
-- tests/emk_data/install.sql
-- Test packages of EMK_DATA (unit tests of tables, constraints, triggers and journals), in installation order.
-- Called by tests/install_tests.sql when connected to EMK_DATA; not run alone.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-16
-- =============================================================================

@@test_emk_reference_data.sql
@@test_emk_shipments.sql
@@test_emk_claims.sql
@@test_emk_exchange_rates.sql
@@test_emk_journals.sql
