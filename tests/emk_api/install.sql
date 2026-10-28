-- =============================================================================
-- tests/emk_api/install.sql
-- Test packages of EMK_API (unit tests of the packages), in installation order.
-- Called by tests/install_tests.sql when connected to EMK_API; not run alone.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-16
-- =============================================================================

@@test_emk_log_pkg.sql
@@test_emk_security_pkg.sql
@@test_emk_errors_pkg.sql
@@test_emk_utilities_pkg.sql
@@test_emk_row_version_pkg.sql
@@test_emk_codes_pkg.sql
@@test_emk_party_api.sql
@@test_emk_shipment_api.sql
@@test_emk_views.sql
@@test_emk_master_data_api.sql
