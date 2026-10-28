-- =============================================================================
-- scripts/release/emk_data_column_grants.sql
-- Column privileges of EMK_API on the code lists the administrator maintains
-- (D-82, step 7.7; api-design decisions 22 and 23). EMK_API may change only
-- these columns, so that even a defect of the API cannot change a code,
-- final_yn, a signature or the name of a file type; no DELETE: a value is
-- retired, never deleted.
--
-- Why a script of its own: SQLcl project export writes the grants of
-- ALL_TAB_PRIVS (whole tables) and not those of ALL_COL_PRIVS (columns), so
-- these grants are not in src/database/emk_data/object_grants/. This file is
-- added to the first release with "project stage add-custom", like the
-- reference data scripts (M1 plan, §2). A new column privilege is added here
-- in the same change. Without these grants the body of EMK_MASTER_DATA_API
-- does not compile, and TEST_EMK_MASTER_DATA_API checks that the database
-- refuses every other column.
--
-- Idempotent: granting a privilege again changes nothing. Run as EMK_DATA
-- (DEV: EMK_DEV[EMK_DATA]); called with @@, so it does not end with EXIT.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-21
-- =============================================================================

-- Lists the administrator adds to and changes (the code is never updated)
grant insert (role_code, name, description, sort_order, valid_from) on emk_data.emk_party_role_types to emk_api;
grant update (name, description, sort_order, valid_from, valid_to)  on emk_data.emk_party_role_types to emk_api;
grant insert (doc_type, name, description, sort_order, valid_from)  on emk_data.emk_document_types to emk_api;
grant update (name, description, sort_order, valid_from, valid_to)  on emk_data.emk_document_types to emk_api;

-- Lists that come with code: name, description and order only
grant update (name, description, sort_order) on emk_data.emk_claim_statuses to emk_api;
grant update (name, description, sort_order) on emk_data.emk_claim_types    to emk_api;

-- File type catalog: the allowed period only
grant update (valid_from, valid_to) on emk_data.emk_file_types to emk_api;
