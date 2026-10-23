create or replace package body emk_api.emk_party_api as
    /**
     * Implementation of EMK_PARTY_API; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Private helpers -----------------------------------------------------------

    -- Active shipments that use the company in any role (delete_party, is_deletable)
    function count_active_shipments (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return pls_integer is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
            emk_data.emk_shipments
        where
                deleted_yn = 'N'
            and in_party_id in ( sender_id, carrier_id, consignee_id );

        return l_count;
    end count_active_shipments;

    -- Shipments, also deleted ones, that use the company in the role: they keep
    -- referring to it (remove_role, get_roles_in_use)
    function count_role_uses (
        in_party_id in emk_data.emk_parties.party_id%type,
        in_role     in varchar2
    ) return pls_integer is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
            emk_data.emk_shipments
        where
            ( in_role = emk_codes_pkg.c_role_sender
              and sender_id = in_party_id )
            or ( in_role = emk_codes_pkg.c_role_carrier
                 and carrier_id = in_party_id )
            or ( in_role = emk_codes_pkg.c_role_consignee
                 and consignee_id = in_party_id );

        return l_count;
    end count_role_uses;

    -- Normalised language code; a company always has one (D-71)
    function require_language (
        in_language_code in varchar2
    ) return varchar2 is
        l_language varchar2(4000 char) := lower(trim(in_language_code));   -- any length: no ORA-06502
    begin
        if l_language is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'The language is required');
        end if;
        return l_language;
    end require_language;

    -- Roles of a colon-separated list (an APEX checkbox value), upper case, without empty entries;
    -- at least one (D-71)
    function split_roles (
        in_role_codes in varchar2
    ) return sys.odcivarchar2list is
        l_roles sys.odcivarchar2list := sys.odcivarchar2list();
    begin
        for i in 1..nvl(
            regexp_count(in_role_codes, '[^:]+'),
            0
        ) loop
            if trim(regexp_substr(in_role_codes, '[^:]+', 1, i)) is not null then   -- a NULL would empty NOT IN
                l_roles.extend;
                l_roles(l_roles.count) := upper(trim(regexp_substr(in_role_codes, '[^:]+', 1, i)));

            end if;
        end loop;

        if l_roles.count = 0 then
            raise_application_error(emk_errors_pkg.c_party_role_required, 'A company needs at least one role');
        end if;

        return l_roles;
    end split_roles;

    -- Upper case without spaces; NULL if nothing is left
    function normalise_vat (
        in_vat_number in varchar2
    ) return varchar2 is
    begin
        return upper(replace(in_vat_number, ' '));
    end normalise_vat;

    -- Country exists (and, if asked, is valid today); returns its EU VAT prefix (NULL outside the EU).
    -- An update checks the validity only when the country changes: a company keeps a retired country (D-68)
    procedure check_country (
        in_country_code   in emk_data.emk_countries.country_code%type,
        out_eu_vat_prefix out emk_data.emk_countries.eu_vat_prefix%type,
        in_require_valid  in boolean default true
    ) is
        l_valid_from emk_data.emk_countries.valid_from%type;
        l_valid_to   emk_data.emk_countries.valid_to%type;
    begin
        select
            eu_vat_prefix,
            valid_from,
            valid_to
        into
            out_eu_vat_prefix,
            l_valid_from,
            l_valid_to
        from
            emk_data.emk_countries
        where
            country_code = in_country_code;

        if
            in_require_valid
            and not emk_utilities_pkg.is_valid_on(l_valid_from,
                                                  l_valid_to,
                                                  trunc(sysdate))
        then
            raise no_data_found;   -- same message as an unknown country
        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_reference_not_valid, 'Country '
                                                                          || in_country_code
                                                                          || ' is unknown or not valid today');
    end check_country;

    -- Language exists and is valid today (code list, D-68)
    procedure check_language (
        in_language_code in emk_data.emk_languages.language_code%type
    ) is
        l_valid_from emk_data.emk_languages.valid_from%type;
        l_valid_to   emk_data.emk_languages.valid_to%type;
    begin
        select
            valid_from,
            valid_to
        into
            l_valid_from,
            l_valid_to
        from
            emk_data.emk_languages
        where
            language_code = in_language_code;

        if not emk_utilities_pkg.is_valid_on(l_valid_from,
                                             l_valid_to,
                                             trunc(sysdate)) then
            raise no_data_found;   -- same message as an unknown language
        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_reference_not_valid, 'Language '
                                                                          || in_language_code
                                                                          || ' is unknown or not valid today');
    end check_language;

    -- Role exists and is valid today (code list, D-68)
    procedure check_role_type (
        in_role_code in emk_data.emk_party_role_types.role_code%type
    ) is
        l_valid_from emk_data.emk_party_role_types.valid_from%type;
        l_valid_to   emk_data.emk_party_role_types.valid_to%type;
    begin
        select
            valid_from,
            valid_to
        into
            l_valid_from,
            l_valid_to
        from
            emk_data.emk_party_role_types
        where
            role_code = in_role_code;

        if not emk_utilities_pkg.is_valid_on(l_valid_from,
                                             l_valid_to,
                                             trunc(sysdate)) then
            raise no_data_found;   -- same message as an unknown role
        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_reference_not_valid, 'Role '
                                                                          || in_role_code
                                                                          || ' is unknown or not valid today');
    end check_role_type;

    -- VAT prefix matches the country (XI also for GB); the number is not used by another party
    procedure check_vat (
        in_vat_number    in emk_data.emk_parties.vat_number%type,
        in_country_code  in emk_data.emk_parties.country_code%type,
        in_eu_vat_prefix in emk_data.emk_countries.eu_vat_prefix%type,
        in_party_id      in emk_data.emk_parties.party_id%type
    ) is
        l_deleted_yn emk_data.emk_parties.deleted_yn%type;
    begin
        if in_vat_number is null then
            return;
        end if;

        -- NVL: outside the EU the prefix is NULL, and a comparison with NULL is never TRUE
        if not ( substr(in_vat_number, 1, 2) = nvl(in_eu_vat_prefix, '-')
        or (
            in_country_code = emk_codes_pkg.c_country_gb
            and substr(in_vat_number, 1, 2) = emk_codes_pkg.c_vat_prefix_northern_ireland
        ) ) then
            raise_application_error(emk_errors_pkg.c_vat_country_mismatch, 'The VAT number does not belong to country '
                                                                           || in_country_code
                                                                           ||
                case
                    when in_eu_vat_prefix is null
                         and in_country_code <> emk_codes_pkg.c_country_gb then
                        ' (EU VAT numbers only)'
                end
            );

        end if;

        select
            max(deleted_yn)
        into l_deleted_yn
        from
            emk_data.emk_parties
        where
                vat_number = in_vat_number
            and party_id <> nvl(in_party_id, -1);

        if l_deleted_yn = 'Y' then
            raise_application_error(emk_errors_pkg.c_duplicate_vat, 'The VAT number belongs to a deleted company: restore that company instead'
            );
        elsif l_deleted_yn = 'N' then
            raise_application_error(emk_errors_pkg.c_duplicate_vat, 'The VAT number is already used by another company');
        end if;

    end check_vat;

    -- Locks a party (NOWAIT), checks that it is active and, if given, its version
    procedure lock_party (
        in_party_id            in emk_data.emk_parties.party_id%type,
        in_expected_updated_at in emk_data.emk_parties.updated_at%type,
        in_check_version       in boolean,
        out_party              out emk_data.emk_parties%rowtype
    ) is
    begin
        if
            in_check_version
            and in_expected_updated_at is null
        then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'The version read (row_version) is required');
        end if;

        select
            *
        into out_party
        from
            emk_data.emk_parties
        where
            party_id = in_party_id
        for update nowait;

        if in_check_version then
            if out_party.deleted_yn = 'Y' then
                raise_application_error(emk_errors_pkg.c_not_found, 'Company '
                                                                    || in_party_id
                                                                    || ' is deleted');
            end if;

            if nvl(out_party.updated_at, out_party.created_at) <> in_expected_updated_at then
                raise_application_error(emk_errors_pkg.c_record_changed, 'The company was changed by another user: reload it');
            end if;

        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Company '
                                                                || in_party_id
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'The company is being changed by another user: try again');
    end lock_party;

    -- Locks a contact (NOWAIT), checks that it is active and, if given, its version
    procedure lock_contact (
        in_contact_id          in emk_data.emk_contacts.contact_id%type,
        in_expected_updated_at in emk_data.emk_contacts.updated_at%type,
        in_check_version       in boolean,
        out_contact            out emk_data.emk_contacts%rowtype
    ) is
    begin
        if
            in_check_version
            and in_expected_updated_at is null
        then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'The version read (row_version) is required');
        end if;

        select
            *
        into out_contact
        from
            emk_data.emk_contacts
        where
            contact_id = in_contact_id
        for update nowait;

        if in_check_version then
            if out_contact.deleted_yn = 'Y' then
                raise_application_error(emk_errors_pkg.c_not_found, 'Contact '
                                                                    || in_contact_id
                                                                    || ' is deleted');
            end if;

            if nvl(out_contact.updated_at, out_contact.created_at) <> in_expected_updated_at then
                raise_application_error(emk_errors_pkg.c_record_changed, 'The contact was changed by another user: reload it');
            end if;

        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Contact '
                                                                || in_contact_id
                                                                || ' does not exist');
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'The contact is being changed by another user: try again');
    end lock_contact;

    -- The party exists and is not deleted
    procedure check_party_active (
        in_party_id in emk_data.emk_parties.party_id%type
    ) is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
            emk_data.emk_parties
        where
                party_id = in_party_id
            and deleted_yn = 'N';

        if l_count = 0 then
            raise_application_error(emk_errors_pkg.c_not_found, 'Company '
                                                                || in_party_id
                                                                || ' does not exist or is deleted');
        end if;

    end check_party_active;

    -- Locks the role rows of a company (one role, or all if in_role_code is NULL) without waiting:
    -- a shipment being saved holds them (lock_role), so a removal or a delete answers "try again"
    -- instead of passing its checks before that shipment is committed (D-73)
    procedure lock_party_roles (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in varchar2
    ) is
    begin
        for r in ( select
                                  null
                              from
                                  emk_data.emk_party_roles
                   where
                           party_id = in_party_id
                       and ( in_role_code is null
                             or role_code = in_role_code )
        for update nowait ) loop
            null;
        end loop;
    exception
        when emk_utilities_pkg.e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'A shipment with this company is being saved by another user: try again'
            );
    end lock_party_roles;

    -- Parties ----------------------------------------------------------------

    procedure create_party (
        in_name          in emk_data.emk_parties.name%type,
        in_vat_number    in emk_data.emk_parties.vat_number%type,
        in_country_code  in emk_data.emk_parties.country_code%type,
        in_street        in emk_data.emk_parties.street%type,
        in_postal_code   in emk_data.emk_parties.postal_code%type,
        in_city          in emk_data.emk_parties.city%type,
        in_language_code in emk_data.emk_parties.language_code%type,
        in_role_codes    in varchar2,
        out_party_id     out emk_data.emk_parties.party_id%type
    ) is

        l_country    emk_data.emk_parties.country_code%type := upper(trim(in_country_code));
        l_vat_number emk_data.emk_parties.vat_number%type := normalise_vat(in_vat_number);
        l_language   varchar2(4000 char) := require_language(in_language_code);   -- checked before it is stored
        l_roles      sys.odcivarchar2list := split_roles(in_role_codes);
        l_vat_prefix emk_data.emk_countries.eu_vat_prefix%type;
    begin
        check_country(l_country, l_vat_prefix);
        check_vat(l_vat_number, l_country, l_vat_prefix, null);
        check_language(l_language);
        insert into emk_data.emk_parties (
            name,
            vat_number,
            country_code,
            street,
            postal_code,
            city,
            language_code
        ) values ( trim(in_name),
                   l_vat_number,
                   l_country,
                   trim(in_street),
                   trim(in_postal_code),
                   trim(in_city),
                   l_language ) returning party_id into out_party_id;

        for i in 1..l_roles.count loop
            add_role(out_party_id,
                     l_roles(i));   -- checks that each role is valid today
        end loop;

    exception
        when dup_val_on_index then   -- another session used the VAT number in the meantime
            raise_application_error(emk_errors_pkg.c_duplicate_vat, 'The VAT number is already used by another company');
    end create_party;

    procedure update_party (
        in_party_id            in emk_data.emk_parties.party_id%type,
        in_expected_updated_at in emk_data.emk_parties.updated_at%type,
        in_name                in emk_data.emk_parties.name%type,
        in_vat_number          in emk_data.emk_parties.vat_number%type,
        in_country_code        in emk_data.emk_parties.country_code%type,
        in_street              in emk_data.emk_parties.street%type,
        in_postal_code         in emk_data.emk_parties.postal_code%type,
        in_city                in emk_data.emk_parties.city%type,
        in_language_code       in emk_data.emk_parties.language_code%type
    ) is

        l_party      emk_data.emk_parties%rowtype;
        l_country    emk_data.emk_parties.country_code%type := upper(trim(in_country_code));
        l_vat_number emk_data.emk_parties.vat_number%type := normalise_vat(in_vat_number);
        l_language   varchar2(4000 char) := require_language(in_language_code);   -- checked before it is stored
        l_vat_prefix emk_data.emk_countries.eu_vat_prefix%type;
    begin
        lock_party(in_party_id, in_expected_updated_at, true, l_party);
        check_country(l_country,
                      l_vat_prefix,
                      emk_utilities_pkg.is_changed(l_party.country_code, l_country));
        check_vat(l_vat_number, l_country, l_vat_prefix, in_party_id);
        if emk_utilities_pkg.is_changed(l_party.language_code, l_language) then
            check_language(l_language);   -- a company keeps a language that was retired
        end if;

        if not ( emk_utilities_pkg.is_changed(l_party.name,
                                              trim(in_name))
        or emk_utilities_pkg.is_changed(l_party.vat_number, l_vat_number)
        or emk_utilities_pkg.is_changed(l_party.country_code, l_country)
        or emk_utilities_pkg.is_changed(l_party.street,
                                        trim(in_street))
        or emk_utilities_pkg.is_changed(l_party.postal_code,
                                        trim(in_postal_code))
        or emk_utilities_pkg.is_changed(l_party.city,
                                        trim(in_city))
        or emk_utilities_pkg.is_changed(l_party.language_code, l_language) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_parties
        set
            name = trim(in_name),
            vat_number = l_vat_number,
            country_code = l_country,
            street = trim(in_street),
            postal_code = trim(in_postal_code),
            city = trim(in_city),
            language_code = l_language
        where
            party_id = in_party_id;

    exception
        when dup_val_on_index then
            raise_application_error(emk_errors_pkg.c_duplicate_vat, 'The VAT number is already used by another company');
    end update_party;

    procedure delete_party (
        in_party_id            in emk_data.emk_parties.party_id%type,
        in_expected_updated_at in emk_data.emk_parties.updated_at%type
    ) is

        l_party emk_data.emk_parties%rowtype;
        l_count pls_integer;
        l_user  emk_data.emk_parties.deleted_by%type := emk_utilities_pkg.get_current_user;
    begin
        lock_party(in_party_id, in_expected_updated_at, true, l_party);
        lock_party_roles(in_party_id, null);   -- D-73: no shipment with this company is being saved
        l_count := count_active_shipments(in_party_id);
        if l_count > 0 then
            raise_application_error(emk_errors_pkg.c_party_in_use, 'The company is used by '
                                                                   || l_count
                                                                   || ' active shipment(s)');
        end if;

        update emk_data.emk_parties
        set
            deleted_yn = 'Y',
            deleted_by = l_user,
            deleted_at = systimestamp
        where
            party_id = in_party_id;

        update emk_data.emk_contacts
        set
            deleted_yn = 'Y',
            deleted_by = l_user,
            deleted_at = systimestamp
        where
                party_id = in_party_id
            and deleted_yn = 'N';

    end delete_party;

    procedure restore_party (
        in_party_id in emk_data.emk_parties.party_id%type
    ) is
        l_party emk_data.emk_parties%rowtype;
    begin
        lock_party(in_party_id, null, false, l_party);
        if l_party.deleted_yn = 'N' then
            return;
        end if;
        update emk_data.emk_parties
        set
            deleted_yn = 'N',
            deleted_by = null,
            deleted_at = null
        where
            party_id = in_party_id;

    end restore_party;

    -- Roles (BR-16) ----------------------------------------------------------

    procedure add_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) is
        l_role  varchar2(4000 char) := upper(trim(in_role_code));   -- any length: an unknown role is a business error
        l_count pls_integer;
    begin
        if l_role is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'A role is required');
        end if;
        check_party_active(in_party_id);
        select
            count(*)
        into l_count
        from
            emk_data.emk_party_roles
        where
                party_id = in_party_id
            and role_code = l_role;

        if l_count > 0 then
            return;   -- the company has the role already, also one that was retired since (D-68)
        end if;
        check_role_type(l_role);
        insert into emk_data.emk_party_roles (
            party_id,
            role_code
        ) values ( in_party_id,
                   l_role );

    exception
        when dup_val_on_index then
            null;   -- added by another session in the meantime: the result is the same
    end add_role;

    procedure remove_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) is

        l_role     varchar2(4000 char) := upper(trim(in_role_code));   -- any length: compared only
        l_count    pls_integer;
        l_has_role pls_integer;
    begin
        check_party_active(in_party_id);
        lock_party_roles(in_party_id, l_role);   -- D-73: no shipment that needs the role is being saved

        -- Every shipment counts, also a deleted one: it keeps referring to the party in that role
        l_count := count_role_uses(in_party_id, l_role);
        if l_count > 0 then
            raise_application_error(emk_errors_pkg.c_party_role_in_use, 'Role '
                                                                        || l_role
                                                                        || ' is used by '
                                                                        || l_count
                                                                        || ' shipment(s)');
        end if;

        -- D-71: a company keeps at least one role
        select
            count(*),
            count(
                case
                    when role_code = l_role then
                        1
                end
            )
        into
            l_count,
            l_has_role
        from
            emk_data.emk_party_roles
        where
            party_id = in_party_id;

        if
            l_has_role > 0
            and l_count = 1
        then
            raise_application_error(emk_errors_pkg.c_party_role_required, 'Role '
                                                                          || l_role
                                                                          || ' is the last role of the company: a company needs at least one role'
                                                                          );
        end if;

        delete from emk_data.emk_party_roles
        where
                party_id = in_party_id
            and role_code = l_role;

    end remove_role;

    procedure set_roles (
        in_party_id   in emk_data.emk_party_roles.party_id%type,
        in_role_codes in varchar2
    ) is
        l_roles sys.odcivarchar2list := split_roles(in_role_codes);
    begin
        check_party_active(in_party_id);

        -- Add first, so that the company never passes through "no role" (D-71); an error undoes
        -- the whole call (statement-level rollback)
        for i in 1..l_roles.count loop
            add_role(in_party_id,
                     l_roles(i));   -- does nothing for a role the company already has
        end loop;

        -- Only roles valid today are removed: a retired role is kept, and removed only by
        -- remove_role (D-86: the page offers valid roles only and must not delete one silently)
        for r in (
            select
                pr.role_code
            from
                     emk_data.emk_party_roles pr
                join emk_data.emk_party_role_types rt on rt.role_code = pr.role_code
            where
                    pr.party_id = in_party_id
                and rt.valid_from <= trunc(sysdate)
                and ( rt.valid_to is null
                      or rt.valid_to >= trunc(sysdate) )
                and pr.role_code not in (
                    select
                        column_value
                    from
                        table ( l_roles )
                )
        ) loop
            remove_role(in_party_id, r.role_code);
        end loop;

    end set_roles;

    procedure lock_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) is
        l_found pls_integer;
    begin
        select
            1
        into l_found
        from
            emk_data.emk_party_roles
        where
                party_id = in_party_id
            and role_code = upper(trim(in_role_code))
        for update wait 3;

    exception
        when no_data_found then
            null;   -- no such role: has_role rejects it
        when emk_utilities_pkg.e_resource_busy or emk_utilities_pkg.e_lock_timeout then
            raise_application_error(emk_errors_pkg.c_record_locked, 'The company is being changed by another user: try again');
    end lock_role;

    function has_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) return boolean is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
                 emk_data.emk_party_roles r
            join emk_data.emk_parties p on p.party_id = r.party_id
        where
                r.party_id = in_party_id
            and r.role_code = upper(trim(in_role_code))
            and p.deleted_yn = 'N';

        return l_count > 0;
    end has_role;

    function get_roles_in_use (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return varchar2 is

        l_roles varchar2(100 char);

        -- Adds the role if a shipment uses the company in it; alphabetical order by the calls below
        procedure add_if_used (
            in_role in varchar2
        ) is
        begin
            if count_role_uses(in_party_id, in_role) > 0 then
                l_roles := l_roles
                           ||
                    case
                        when l_roles is not null then
                            ':'
                    end
                           || in_role;

            end if;
        end add_if_used;

    begin
        add_if_used(emk_codes_pkg.c_role_carrier);
        add_if_used(emk_codes_pkg.c_role_consignee);
        add_if_used(emk_codes_pkg.c_role_sender);
        return l_roles;
    end get_roles_in_use;

    function is_deletable (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return boolean is
    begin
        return count_active_shipments(in_party_id) = 0;
    end is_deletable;

    -- Contacts ---------------------------------------------------------------

    procedure create_contact (
        in_party_id    in emk_data.emk_contacts.party_id%type,
        in_full_name   in emk_data.emk_contacts.full_name%type,
        in_email       in emk_data.emk_contacts.email%type,
        in_phone       in emk_data.emk_contacts.phone%type,
        out_contact_id out emk_data.emk_contacts.contact_id%type
    ) is
    begin
        check_party_active(in_party_id);
        insert into emk_data.emk_contacts (
            party_id,
            full_name,
            email,
            phone
        ) values ( in_party_id,
                   trim(in_full_name),
                   trim(in_email),
                   replace(in_phone, ' ') ) returning contact_id into out_contact_id;

    end create_contact;

    procedure update_contact (
        in_contact_id          in emk_data.emk_contacts.contact_id%type,
        in_expected_updated_at in emk_data.emk_contacts.updated_at%type,
        in_full_name           in emk_data.emk_contacts.full_name%type,
        in_email               in emk_data.emk_contacts.email%type,
        in_phone               in emk_data.emk_contacts.phone%type
    ) is
        l_contact emk_data.emk_contacts%rowtype;
    begin
        lock_contact(in_contact_id, in_expected_updated_at, true, l_contact);
        if not ( emk_utilities_pkg.is_changed(l_contact.full_name,
                                              trim(in_full_name))
        or emk_utilities_pkg.is_changed(l_contact.email,
                                        trim(in_email))
        or emk_utilities_pkg.is_changed(l_contact.phone,
                                        replace(in_phone, ' ')) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_contacts
        set
            full_name = trim(in_full_name),
            email = trim(in_email),
            phone = replace(in_phone, ' ')
        where
            contact_id = in_contact_id;

    end update_contact;

    procedure delete_contact (
        in_contact_id          in emk_data.emk_contacts.contact_id%type,
        in_expected_updated_at in emk_data.emk_contacts.updated_at%type
    ) is

        l_contact emk_data.emk_contacts%rowtype;
        l_user    emk_data.emk_contacts.deleted_by%type := emk_utilities_pkg.get_current_user;   -- read once, before the statement
    begin
        lock_contact(in_contact_id, in_expected_updated_at, true, l_contact);
        update emk_data.emk_contacts
        set
            deleted_yn = 'Y',
            deleted_by = l_user,
            deleted_at = systimestamp
        where
            contact_id = in_contact_id;

    end delete_contact;

    procedure restore_contact (
        in_contact_id in emk_data.emk_contacts.contact_id%type
    ) is
        l_contact emk_data.emk_contacts%rowtype;
    begin
        lock_contact(in_contact_id, null, false, l_contact);
        if l_contact.deleted_yn = 'N' then
            return;
        end if;
        check_party_active(l_contact.party_id);   -- restore the company first

        update emk_data.emk_contacts
        set
            deleted_yn = 'N',
            deleted_by = null,
            deleted_at = null
        where
            contact_id = in_contact_id;

    end restore_contact;

end emk_party_api;
/


-- sqlcl_snapshot {"hash":"5ea79202ec231248630390faa77ce78db4bc008a","type":"PACKAGE_BODY","name":"EMK_PARTY_API","schemaName":"EMK_API","sxml":""}