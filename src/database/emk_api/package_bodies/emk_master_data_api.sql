create or replace package body emk_api.emk_master_data_api as
    /**
     * Implementation of EMK_MASTER_DATA_API; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Private helpers -----------------------------------------------------------

    -- Administrator only (D-82, decision 22); EMK_SECURITY_PKG logs a refusal
    procedure assert_administrator is
    begin
        emk_security_pkg.assert_role(emk_security_pkg.c_administrator);
    end assert_administrator;

    -- Logs an attempt to bypass a business rule (ASVS V16.3.3) and raises the error
    procedure reject (
        in_error_code in pls_integer,
        in_message    in varchar2,
        in_context    in varchar2
    ) is
    begin
        emk_log_pkg.log_warn('Master data change rejected: ' || in_message, in_context);
        raise_application_error(in_error_code, in_message);
    end reject;

    -- A required value is never defaulted here: the page proposes one (D-82)
    procedure require (
        in_value in varchar2,
        in_what  in varchar2
    ) is
    begin
        if trim(in_value) is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, in_what || ' is required');
        end if;
    end require;

    procedure require (
        in_value in number,
        in_what  in varchar2
    ) is
    begin
        if in_value is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, in_what || ' is required');
        end if;
    end require;

    procedure require (
        in_value in date,
        in_what  in varchar2
    ) is
    begin
        if in_value is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, in_what || ' is required');
        end if;
    end require;

    -- Optimistic locking (D-43): the version the caller read is the current one
    procedure check_version (
        in_expected_updated_at in timestamp with time zone,
        in_updated_at          in timestamp with time zone,
        in_created_at          in timestamp with time zone,
        in_what                in varchar2
    ) is
    begin
        if in_expected_updated_at is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'The version read (row_version) is required');
        end if;
        if nvl(in_updated_at, in_created_at) <> in_expected_updated_at then
            raise_application_error(emk_errors_pkg.c_record_changed, in_what || ' was changed by another user: reload it');
        end if;

    end check_version;

    -- Lock helpers: the row (NOWAIT) and its version -----------------------------

    procedure lock_role_type (
        in_role_code           in emk_data.emk_party_role_types.role_code%type,
        in_expected_updated_at in emk_data.emk_party_role_types.updated_at%type,
        out_row                out emk_data.emk_party_role_types%rowtype
    ) is
    begin
        select
            *
        into out_row
        from
            emk_data.emk_party_role_types
        where
            role_code = in_role_code
        for update nowait;

        check_version(in_expected_updated_at, out_row.updated_at, out_row.created_at, 'Role ' || in_role_code);
    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Role '
                                                                || in_role_code
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'Role '
                                                                    || in_role_code
                                                                    || ' is being changed by another user: try again');
    end lock_role_type;

    procedure lock_claim_status (
        in_status_code         in emk_data.emk_claim_statuses.status_code%type,
        in_expected_updated_at in emk_data.emk_claim_statuses.updated_at%type,
        out_row                out emk_data.emk_claim_statuses%rowtype
    ) is
    begin
        select
            *
        into out_row
        from
            emk_data.emk_claim_statuses
        where
            status_code = in_status_code
        for update nowait;

        check_version(in_expected_updated_at, out_row.updated_at, out_row.created_at, 'Claim status ' || in_status_code);
    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Claim status '
                                                                || in_status_code
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'Claim status '
                                                                    || in_status_code
                                                                    || ' is being changed by another user: try again');
    end lock_claim_status;

    procedure lock_claim_type (
        in_claim_type          in emk_data.emk_claim_types.claim_type%type,
        in_expected_updated_at in emk_data.emk_claim_types.updated_at%type,
        out_row                out emk_data.emk_claim_types%rowtype
    ) is
    begin
        select
            *
        into out_row
        from
            emk_data.emk_claim_types
        where
            claim_type = in_claim_type
        for update nowait;

        check_version(in_expected_updated_at, out_row.updated_at, out_row.created_at, 'Claim type ' || in_claim_type);
    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Claim type '
                                                                || in_claim_type
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'Claim type '
                                                                    || in_claim_type
                                                                    || ' is being changed by another user: try again');
    end lock_claim_type;

    procedure lock_document_type (
        in_doc_type            in emk_data.emk_document_types.doc_type%type,
        in_expected_updated_at in emk_data.emk_document_types.updated_at%type,
        out_row                out emk_data.emk_document_types%rowtype
    ) is
    begin
        select
            *
        into out_row
        from
            emk_data.emk_document_types
        where
            doc_type = in_doc_type
        for update nowait;

        check_version(in_expected_updated_at, out_row.updated_at, out_row.created_at, 'Document type ' || in_doc_type);
    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Document type '
                                                                || in_doc_type
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'Document type '
                                                                    || in_doc_type
                                                                    || ' is being changed by another user: try again');
    end lock_document_type;

    procedure lock_file_type (
        in_mime_type           in emk_data.emk_file_types.mime_type%type,
        in_expected_updated_at in emk_data.emk_file_types.updated_at%type,
        out_row                out emk_data.emk_file_types%rowtype
    ) is
    begin
        select
            *
        into out_row
        from
            emk_data.emk_file_types
        where
            mime_type = in_mime_type
        for update nowait;

        check_version(in_expected_updated_at, out_row.updated_at, out_row.created_at, 'File type ' || in_mime_type);
    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'File type '
                                                                || in_mime_type
                                                                || ' is not in the catalog');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'File type '
                                                                    || in_mime_type
                                                                    || ' is being changed by another user: try again');
    end lock_file_type;

    -- Party role types ------------------------------------------------------------

    procedure create_role_type (
        in_role_code   in emk_data.emk_party_role_types.role_code%type,
        in_name        in emk_data.emk_party_role_types.name%type,
        in_description in emk_data.emk_party_role_types.description%type,
        in_sort_order  in emk_data.emk_party_role_types.sort_order%type,
        in_valid_from  in emk_data.emk_party_role_types.valid_from%type
    ) is
        l_code varchar2(4000 char) := upper(trim(in_role_code));   -- any length: no ORA-06502; the column checks it
    begin
        assert_administrator;
        require(l_code, 'The code');
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        require(in_valid_from, 'The start of validity');
        insert into emk_data.emk_party_role_types (
            role_code,
            name,
            description,
            sort_order,
            valid_from
        ) values ( l_code,
                   trim(in_name),
                   trim(in_description),
                   in_sort_order,
                   trunc(in_valid_from) );

    exception
        when dup_val_on_index then
            raise_application_error(emk_errors_pkg.c_code_exists, 'Role '
                                                                  || l_code
                                                                  || ' already exists, also if retired: change its validity instead')
                                                                  ;
    end create_role_type;

    procedure update_role_type (
        in_role_code           in emk_data.emk_party_role_types.role_code%type,
        in_expected_updated_at in emk_data.emk_party_role_types.updated_at%type,
        in_name                in emk_data.emk_party_role_types.name%type,
        in_description         in emk_data.emk_party_role_types.description%type,
        in_sort_order          in emk_data.emk_party_role_types.sort_order%type,
        in_valid_from          in emk_data.emk_party_role_types.valid_from%type,
        in_valid_to            in emk_data.emk_party_role_types.valid_to%type
    ) is

        l_row        emk_data.emk_party_role_types%rowtype;
        l_valid_from emk_data.emk_party_role_types.valid_from%type := trunc(in_valid_from);
        l_valid_to   emk_data.emk_party_role_types.valid_to%type := trunc(in_valid_to);
    begin
        assert_administrator;
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        require(l_valid_from, 'The start of validity');
        lock_role_type(in_role_code, in_expected_updated_at, l_row);
        if
            emk_codes_pkg.is_protected_role(l_row.role_code)
            and ( l_valid_to is not null
                  or l_valid_from > trunc(sysdate) )
        then
            reject(emk_errors_pkg.c_code_protected,
                   'Role '
                   || l_row.role_code
                   || ' is used by the rules of the program and cannot be retired',
                   json_object(
                    'list' value 'EMK_PARTY_ROLE_TYPES',
                    'code' value l_row.role_code
                )
            );
        end if;

        if not ( emk_utilities_pkg.is_changed(l_row.name,
                                              trim(in_name))
        or emk_utilities_pkg.is_changed(l_row.description,
                                        trim(in_description))
        or emk_utilities_pkg.is_changed(l_row.sort_order, in_sort_order)
        or emk_utilities_pkg.is_changed(l_row.valid_from, l_valid_from)
        or emk_utilities_pkg.is_changed(l_row.valid_to, l_valid_to) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_party_role_types
        set
            name = trim(in_name),
            description = trim(in_description),
            sort_order = in_sort_order,
            valid_from = l_valid_from,
            valid_to = l_valid_to
        where
            role_code = l_row.role_code;

    end update_role_type;

    -- Claim statuses and claim types: name, description and order only ------------

    procedure update_claim_status (
        in_status_code         in emk_data.emk_claim_statuses.status_code%type,
        in_expected_updated_at in emk_data.emk_claim_statuses.updated_at%type,
        in_name                in emk_data.emk_claim_statuses.name%type,
        in_description         in emk_data.emk_claim_statuses.description%type,
        in_sort_order          in emk_data.emk_claim_statuses.sort_order%type
    ) is
        l_row emk_data.emk_claim_statuses%rowtype;
    begin
        assert_administrator;
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        lock_claim_status(in_status_code, in_expected_updated_at, l_row);
        if not ( emk_utilities_pkg.is_changed(l_row.name,
                                              trim(in_name))
        or emk_utilities_pkg.is_changed(l_row.description,
                                        trim(in_description))
        or emk_utilities_pkg.is_changed(l_row.sort_order, in_sort_order) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_claim_statuses
        set
            name = trim(in_name),
            description = trim(in_description),
            sort_order = in_sort_order
        where
            status_code = l_row.status_code;

    end update_claim_status;

    procedure update_claim_type (
        in_claim_type          in emk_data.emk_claim_types.claim_type%type,
        in_expected_updated_at in emk_data.emk_claim_types.updated_at%type,
        in_name                in emk_data.emk_claim_types.name%type,
        in_description         in emk_data.emk_claim_types.description%type,
        in_sort_order          in emk_data.emk_claim_types.sort_order%type
    ) is
        l_row emk_data.emk_claim_types%rowtype;
    begin
        assert_administrator;
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        lock_claim_type(in_claim_type, in_expected_updated_at, l_row);
        if not ( emk_utilities_pkg.is_changed(l_row.name,
                                              trim(in_name))
        or emk_utilities_pkg.is_changed(l_row.description,
                                        trim(in_description))
        or emk_utilities_pkg.is_changed(l_row.sort_order, in_sort_order) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_claim_types
        set
            name = trim(in_name),
            description = trim(in_description),
            sort_order = in_sort_order
        where
            claim_type = l_row.claim_type;

    end update_claim_type;

    -- Document types --------------------------------------------------------------

    procedure create_document_type (
        in_doc_type    in emk_data.emk_document_types.doc_type%type,
        in_name        in emk_data.emk_document_types.name%type,
        in_description in emk_data.emk_document_types.description%type,
        in_sort_order  in emk_data.emk_document_types.sort_order%type,
        in_valid_from  in emk_data.emk_document_types.valid_from%type
    ) is
        l_code varchar2(4000 char) := upper(trim(in_doc_type));   -- any length: no ORA-06502; the column checks it
    begin
        assert_administrator;
        require(l_code, 'The code');
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        require(in_valid_from, 'The start of validity');
        insert into emk_data.emk_document_types (
            doc_type,
            name,
            description,
            sort_order,
            valid_from
        ) values ( l_code,
                   trim(in_name),
                   trim(in_description),
                   in_sort_order,
                   trunc(in_valid_from) );

    exception
        when dup_val_on_index then
            raise_application_error(emk_errors_pkg.c_code_exists, 'Document type '
                                                                  || l_code
                                                                  || ' already exists, also if retired: change its validity instead')
                                                                  ;
    end create_document_type;

    procedure update_document_type (
        in_doc_type            in emk_data.emk_document_types.doc_type%type,
        in_expected_updated_at in emk_data.emk_document_types.updated_at%type,
        in_name                in emk_data.emk_document_types.name%type,
        in_description         in emk_data.emk_document_types.description%type,
        in_sort_order          in emk_data.emk_document_types.sort_order%type,
        in_valid_from          in emk_data.emk_document_types.valid_from%type,
        in_valid_to            in emk_data.emk_document_types.valid_to%type
    ) is

        l_row        emk_data.emk_document_types%rowtype;
        l_valid_from emk_data.emk_document_types.valid_from%type := trunc(in_valid_from);
        l_valid_to   emk_data.emk_document_types.valid_to%type := trunc(in_valid_to);
    begin
        assert_administrator;
        require(in_name, 'The name');
        require(in_sort_order, 'The order');
        require(l_valid_from, 'The start of validity');
        lock_document_type(in_doc_type, in_expected_updated_at, l_row);
        if not ( emk_utilities_pkg.is_changed(l_row.name,
                                              trim(in_name))
        or emk_utilities_pkg.is_changed(l_row.description,
                                        trim(in_description))
        or emk_utilities_pkg.is_changed(l_row.sort_order, in_sort_order)
        or emk_utilities_pkg.is_changed(l_row.valid_from, l_valid_from)
        or emk_utilities_pkg.is_changed(l_row.valid_to, l_valid_to) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_document_types
        set
            name = trim(in_name),
            description = trim(in_description),
            sort_order = in_sort_order,
            valid_from = l_valid_from,
            valid_to = l_valid_to
        where
            doc_type = l_row.doc_type;

    end update_document_type;

    -- File types: the allowed period only (the catalog belongs to the developer) ----

    procedure allow_file_type (
        in_mime_type           in emk_data.emk_file_types.mime_type%type,
        in_expected_updated_at in emk_data.emk_file_types.updated_at%type,
        in_valid_from          in emk_data.emk_file_types.valid_from%type
    ) is

        l_row        emk_data.emk_file_types%rowtype;
        l_valid_from emk_data.emk_file_types.valid_from%type := trunc(in_valid_from);
    begin
        assert_administrator;
        require(l_valid_from, 'The first day uploads are allowed');
        lock_file_type(in_mime_type, in_expected_updated_at, l_row);
        if
            not emk_utilities_pkg.is_changed(l_row.valid_from, l_valid_from)
            and l_row.valid_to is null
        then
            return;   -- already allowed from that day, with no end
        end if;

        update emk_data.emk_file_types
        set
            valid_from = l_valid_from,
            valid_to = null   -- allowed again after a retirement
        where
            mime_type = l_row.mime_type;

    end allow_file_type;

    procedure retire_file_type (
        in_mime_type           in emk_data.emk_file_types.mime_type%type,
        in_expected_updated_at in emk_data.emk_file_types.updated_at%type,
        in_valid_to            in emk_data.emk_file_types.valid_to%type
    ) is

        l_row      emk_data.emk_file_types%rowtype;
        l_valid_to emk_data.emk_file_types.valid_to%type := trunc(in_valid_to);
    begin
        assert_administrator;
        require(l_valid_to, 'The last day uploads are allowed');
        lock_file_type(in_mime_type, in_expected_updated_at, l_row);
        if l_row.valid_from is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'File type '
                                                                       || l_row.mime_type
                                                                       || ' is not allowed: there is nothing to retire');
        end if;

        if not emk_utilities_pkg.is_changed(l_row.valid_to, l_valid_to) then
            return;   -- already retired on that day
        end if;
        update emk_data.emk_file_types
        set
            valid_to = l_valid_to   -- before valid_from: EMK_FILE_TYPES_VALID_CK
        where
            mime_type = l_row.mime_type;

    end retire_file_type;

end emk_master_data_api;
/


-- sqlcl_snapshot {"hash":"9e145899618cea4bf14a867fdebd8a0da54a3b48","type":"PACKAGE_BODY","name":"EMK_MASTER_DATA_API","schemaName":"EMK_API","sxml":""}