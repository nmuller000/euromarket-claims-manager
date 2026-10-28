create or replace package emk_api.emk_master_data_api as
    /**
     * Master data API: the code lists the administrator maintains in the
     * Master Data menu (D-82, step 7.7; api-design.md §5, decisions 22 and 23;
     * data-model-reference.md §6). The only way to change these lists from
     * the application; the connect user EMK_UI has EXECUTE on this package
     * and no privilege on the tables (ADR-008).
     *
     * Rules:
     *   - Administrator only: every subprogram first calls
     *     EMK_SECURITY_PKG.assert_role(c_administrator); a refusal is logged
     *     as WARN (OWASP ASVS 5.0 V8.2.1, V8.3.1, V16.3.2).
     *   - A value is never deleted and its code never changes: it is retired
     *     with valid_to. Records that have it keep it; the lists of values no
     *     longer offer it (ISO 3166 and ISO 4217 practice).
     *   - What the administrator may change, per list: party role types and
     *     document types: name, description, order and validity (and they
     *     can be added); claim statuses and claim types: name, description
     *     and order only (a new one needs code: the state machine, the
     *     deadline rules); file types: the allowed period only (the catalog,
     *     with signatures and extensions, is maintained by the developer).
     *   - A code named in EMK_CODES_PKG cannot be retired: its validity
     *     cannot end or start in the future (c_code_protected); the attempt
     *     is logged as WARN (ASVS V16.3.3, attempt to bypass a business rule).
     *   - Optimistic locking (D-43): updates receive the version the caller
     *     read, NVL(updated_at, created_at) (column row_version of the
     *     views); rows are locked with FOR UPDATE NOWAIT.
     *   - Required values are never defaulted here: a missing one raises
     *     c_invalid_argument (the page proposes a value the user can change).
     *   - Values are normalised: codes upper case and trimmed, names and
     *     descriptions trimmed, dates without time. Format rules are check
     *     constraints of the tables; their errors reach the caller unchanged.
     *   - An update that changes nothing writes nothing (no journal row).
     *   - Every change is kept in the journal <TABLE>_JN by its trigger
     *     (previous row, user, time).
     *   - No COMMIT: the caller ends the transaction.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Party role types (EMK_PARTY_ROLE_TYPES) ---------------------------------

    /**
     * Adds a role a company can play.
     *
     * @param  in_role_code   code, upper case letters and underscores (stored upper case, trimmed)
     * @param  in_name        display name (trimmed, required)
     * @param  in_description description
     * @param  in_sort_order  position in the lists (required)
     * @param  in_valid_from  first day the role is offered (required; the page proposes today)
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_invalid_argument code, name, order or valid_from missing
     * @throws emk_errors_pkg.e_code_exists      the code exists, also if retired: change its
     *                                           validity instead (a code is never reused)
     */
    procedure create_role_type (
        in_role_code   in emk_data.emk_party_role_types.role_code%type,
        in_name        in emk_data.emk_party_role_types.name%type,
        in_description in emk_data.emk_party_role_types.description%type,
        in_sort_order  in emk_data.emk_party_role_types.sort_order%type,
        in_valid_from  in emk_data.emk_party_role_types.valid_from%type
    );

    /**
     * Changes the name, description, order or validity of a role. Retiring
     * a role (valid_to) does not remove it from the companies that have it.
     *
     * @param  in_role_code            code of the role (never changes)
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_name                 display name (trimmed, required)
     * @param  in_description          description
     * @param  in_sort_order           position in the lists (required)
     * @param  in_valid_from           first day the role is offered (required)
     * @param  in_valid_to             last day; NULL = still valid
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        unknown role
     * @throws emk_errors_pkg.e_invalid_argument name, order or valid_from missing
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     * @throws emk_errors_pkg.e_code_protected   a role named in EMK_CODES_PKG would stop being valid
     */
    procedure update_role_type (
        in_role_code           in emk_data.emk_party_role_types.role_code%type,
        in_expected_updated_at in emk_data.emk_party_role_types.updated_at%type,
        in_name                in emk_data.emk_party_role_types.name%type,
        in_description         in emk_data.emk_party_role_types.description%type,
        in_sort_order          in emk_data.emk_party_role_types.sort_order%type,
        in_valid_from          in emk_data.emk_party_role_types.valid_from%type,
        in_valid_to            in emk_data.emk_party_role_types.valid_to%type
    );

    -- Claim statuses (EMK_CLAIM_STATUSES) -------------------------------------

    /**
     * Changes the name, description or order of a claim status. Its code,
     * final_yn and validity belong to the state machine and never change here.
     *
     * @param  in_status_code          code of the status
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_name                 display name (trimmed, required)
     * @param  in_description          description
     * @param  in_sort_order           position in the lists (required)
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        unknown status
     * @throws emk_errors_pkg.e_invalid_argument name or order missing
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure update_claim_status (
        in_status_code         in emk_data.emk_claim_statuses.status_code%type,
        in_expected_updated_at in emk_data.emk_claim_statuses.updated_at%type,
        in_name                in emk_data.emk_claim_statuses.name%type,
        in_description         in emk_data.emk_claim_statuses.description%type,
        in_sort_order          in emk_data.emk_claim_statuses.sort_order%type
    );

    -- Claim types (EMK_CLAIM_TYPES) --------------------------------------------

    /**
     * Changes the name, description or order of a claim type. Its code and
     * validity belong to the deadline rules and never change here.
     *
     * @param  in_claim_type           code of the claim type
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_name                 display name (trimmed, required)
     * @param  in_description          description
     * @param  in_sort_order           position in the lists (required)
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        unknown claim type
     * @throws emk_errors_pkg.e_invalid_argument name or order missing
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure update_claim_type (
        in_claim_type          in emk_data.emk_claim_types.claim_type%type,
        in_expected_updated_at in emk_data.emk_claim_types.updated_at%type,
        in_name                in emk_data.emk_claim_types.name%type,
        in_description         in emk_data.emk_claim_types.description%type,
        in_sort_order          in emk_data.emk_claim_types.sort_order%type
    );

    -- Document types (EMK_DOCUMENT_TYPES) --------------------------------------

    /**
     * Adds a type of claim document.
     *
     * @param  in_doc_type    code, upper case letters and underscores (stored upper case, trimmed)
     * @param  in_name        display name (trimmed, required)
     * @param  in_description description
     * @param  in_sort_order  position in the lists (required)
     * @param  in_valid_from  first day the type is offered (required; the page proposes today)
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_invalid_argument code, name, order or valid_from missing
     * @throws emk_errors_pkg.e_code_exists      the code exists, also if retired
     */
    procedure create_document_type (
        in_doc_type    in emk_data.emk_document_types.doc_type%type,
        in_name        in emk_data.emk_document_types.name%type,
        in_description in emk_data.emk_document_types.description%type,
        in_sort_order  in emk_data.emk_document_types.sort_order%type,
        in_valid_from  in emk_data.emk_document_types.valid_from%type
    );

    /**
     * Changes the name, description, order or validity of a document type.
     * Retiring it does not change the documents that have it.
     *
     * @param  in_doc_type             code of the document type (never changes)
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_name                 display name (trimmed, required)
     * @param  in_description          description
     * @param  in_sort_order           position in the lists (required)
     * @param  in_valid_from           first day the type is offered (required)
     * @param  in_valid_to             last day; NULL = still valid
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        unknown document type
     * @throws emk_errors_pkg.e_invalid_argument name, order or valid_from missing
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure update_document_type (
        in_doc_type            in emk_data.emk_document_types.doc_type%type,
        in_expected_updated_at in emk_data.emk_document_types.updated_at%type,
        in_name                in emk_data.emk_document_types.name%type,
        in_description         in emk_data.emk_document_types.description%type,
        in_sort_order          in emk_data.emk_document_types.sort_order%type,
        in_valid_from          in emk_data.emk_document_types.valid_from%type,
        in_valid_to            in emk_data.emk_document_types.valid_to%type
    );

    -- File types (EMK_FILE_TYPES) ----------------------------------------------

    /**
     * Allows uploads of a file type of the catalog (BR-18) from a date, with
     * no end; also allows again a type that was retired. Type, name,
     * signature and extensions are maintained by the developer with a data
     * script (D-72); a type of the catalog without valid_from is not allowed.
     *
     * @param  in_mime_type            media type of the catalog, e.g. application/pdf
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_valid_from           first day uploads are allowed (required; the page proposes today)
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        type not in the catalog
     * @throws emk_errors_pkg.e_invalid_argument valid_from missing
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure allow_file_type (
        in_mime_type           in emk_data.emk_file_types.mime_type%type,
        in_expected_updated_at in emk_data.emk_file_types.updated_at%type,
        in_valid_from          in emk_data.emk_file_types.valid_from%type
    );

    /**
     * Retires an allowed file type: no upload of the type after the given
     * day. Documents already stored keep their type (D-72).
     *
     * @param  in_mime_type            media type of the catalog, e.g. application/pdf
     * @param  in_expected_updated_at  version read by the caller (row_version)
     * @param  in_valid_to             last day uploads are allowed (required; the page proposes today),
     *                                 not before valid_from
     * @throws emk_errors_pkg.e_not_authorized   the user is not an administrator
     * @throws emk_errors_pkg.e_not_found        type not in the catalog
     * @throws emk_errors_pkg.e_invalid_argument valid_to missing, or the type is not allowed
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure retire_file_type (
        in_mime_type           in emk_data.emk_file_types.mime_type%type,
        in_expected_updated_at in emk_data.emk_file_types.updated_at%type,
        in_valid_to            in emk_data.emk_file_types.valid_to%type
    );

end emk_master_data_api;
/


-- sqlcl_snapshot {"hash":"db4853e17f70955b7339cd4a507d1fd3d95410ba","type":"PACKAGE_SPEC","name":"EMK_MASTER_DATA_API","schemaName":"EMK_API","sxml":""}