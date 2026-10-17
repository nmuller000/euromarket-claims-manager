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

    e_resource_busy exception;          -- ORA-00054: row locked, NOWAIT
    pragma exception_init ( e_resource_busy, -54 );
    e_check_violation exception;        -- ORA-02290: check constraint violated
    pragma exception_init ( e_check_violation, -2290 );
    c_shipper   constant emk_data.emk_party_roles.role_code%type := 'SHIPPER';
    c_carrier   constant emk_data.emk_party_roles.role_code%type := 'CARRIER';
    c_consignee constant emk_data.emk_party_roles.role_code%type := 'CONSIGNEE';

    -- Private helpers -----------------------------------------------------------

    -- The person behind the change, as in the audit defaults of the tables
    function get_current_user return varchar2 is
    begin
        return coalesce(
            sys_context('APEX$SESSION', 'APP_USER'),
            sys_context('USERENV', 'PROXY_USER'),
            sys_context('USERENV', 'SESSION_USER')
        );
    end get_current_user;

    -- TRUE if two values differ; NULL and NULL count as equal. Never returns NULL:
    -- a NULL here would turn the whole "nothing changed" condition into NULL
    function is_changed (
        in_old in varchar2,
        in_new in varchar2
    ) return boolean is
    begin
        if
            in_old is null
            and in_new is null
        then
            return false;
        elsif in_old is null
              or in_new is null then
            return true;
        else
            return in_old <> in_new;
        end if;
    end is_changed;

    -- Upper case without spaces; NULL if nothing is left
    function normalise_vat (
        in_vat_number in varchar2
    ) return varchar2 is
    begin
        return upper(replace(in_vat_number, ' '));
    end normalise_vat;

    -- Country exists and is valid today; returns its EU VAT prefix (NULL outside the EU)
    procedure check_country (
        in_country_code   in emk_data.emk_countries.country_code%type,
        out_eu_vat_prefix out emk_data.emk_countries.eu_vat_prefix%type
    ) is
    begin
        select
            eu_vat_prefix
        into out_eu_vat_prefix
        from
            emk_data.emk_countries
        where
                country_code = in_country_code
            and valid_from <= trunc(sysdate)
            and ( valid_to is null
                  or valid_to >= trunc(sysdate) );

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_reference_not_valid, 'Country '
                                                                          || in_country_code
                                                                          || ' is unknown or not valid today');
    end check_country;

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
            in_country_code = 'GB'
            and substr(in_vat_number, 1, 2) = 'XI'
        ) ) then
            raise_application_error(emk_errors_pkg.c_vat_country_mismatch, 'The VAT number does not belong to country '
                                                                           || in_country_code
                                                                           ||
                case
                    when in_eu_vat_prefix is null
                         and in_country_code <> 'GB' then
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
        when e_resource_busy then
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
        when e_resource_busy then
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

    -- Parties ----------------------------------------------------------------

    procedure create_party (
        in_name          in emk_data.emk_parties.name%type,
        in_vat_number    in emk_data.emk_parties.vat_number%type,
        in_country_code  in emk_data.emk_parties.country_code%type,
        in_street        in emk_data.emk_parties.street%type,
        in_postal_code   in emk_data.emk_parties.postal_code%type,
        in_city          in emk_data.emk_parties.city%type,
        in_language_code in emk_data.emk_parties.language_code%type,
        out_party_id     out emk_data.emk_parties.party_id%type
    ) is

        l_country    emk_data.emk_parties.country_code%type := upper(trim(in_country_code));
        l_vat_number emk_data.emk_parties.vat_number%type := normalise_vat(in_vat_number);
        l_vat_prefix emk_data.emk_countries.eu_vat_prefix%type;
    begin
        check_country(l_country, l_vat_prefix);
        check_vat(l_vat_number, l_country, l_vat_prefix, null);
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
                   lower(trim(in_language_code)) ) returning party_id into out_party_id;

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
        l_language   emk_data.emk_parties.language_code%type := nvl(
            lower(trim(in_language_code)),
            'en'
        );
        l_vat_prefix emk_data.emk_countries.eu_vat_prefix%type;
    begin
        lock_party(in_party_id, in_expected_updated_at, true, l_party);
        check_country(l_country, l_vat_prefix);
        check_vat(l_vat_number, l_country, l_vat_prefix, in_party_id);
        if not ( is_changed(l_party.name,
                            trim(in_name))
        or is_changed(l_party.vat_number, l_vat_number)
        or is_changed(l_party.country_code, l_country)
        or is_changed(l_party.street,
                      trim(in_street))
        or is_changed(l_party.postal_code,
                      trim(in_postal_code))
        or is_changed(l_party.city,
                      trim(in_city))
        or is_changed(l_party.language_code, l_language) ) then
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
        l_user  emk_data.emk_parties.deleted_by%type := get_current_user;
    begin
        lock_party(in_party_id, in_expected_updated_at, true, l_party);
        select
            count(*)
        into l_count
        from
            emk_data.emk_shipments
        where
                deleted_yn = 'N'
            and in_party_id in ( shipper_id, carrier_id, consignee_id );

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
        l_role emk_data.emk_party_roles.role_code%type := upper(trim(in_role_code));
    begin
        if l_role is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'A role is required');
        end if;
        check_party_active(in_party_id);
        insert into emk_data.emk_party_roles (
            party_id,
            role_code
        )
            select
                in_party_id,
                l_role
            from
                dual
            where
                not exists (
                    select
                        null
                    from
                        emk_data.emk_party_roles
                    where
                            party_id = in_party_id
                        and role_code = l_role
                );

    exception
        when e_check_violation then
            raise_application_error(emk_errors_pkg.c_invalid_argument,
                                    'Unknown role: '
                                    || substr(in_role_code, 1, 20));
        when dup_val_on_index then
            null;   -- added by another session in the meantime: the result is the same
    end add_role;

    procedure remove_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) is

        l_role  emk_data.emk_party_roles.role_code%type := upper(trim(in_role_code));
        l_count pls_integer;
    begin
        check_party_active(in_party_id);

        -- Every shipment counts, also a deleted one: it keeps referring to the party in that role
        select
            count(*)
        into l_count
        from
            emk_data.emk_shipments
        where
            ( l_role = c_shipper
              and shipper_id = in_party_id )
            or ( l_role = c_carrier
                 and carrier_id = in_party_id )
            or ( l_role = c_consignee
                 and consignee_id = in_party_id );

        if l_count > 0 then
            raise_application_error(emk_errors_pkg.c_party_role_in_use, 'Role '
                                                                        || l_role
                                                                        || ' is used by '
                                                                        || l_count
                                                                        || ' shipment(s)');
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
        l_roles sys.odcivarchar2list := sys.odcivarchar2list();
    begin
        check_party_active(in_party_id);

        -- Requested roles without empty entries (NULL or '' = no role)
        for i in 1..nvl(
            regexp_count(in_role_codes, '[^:]+'),
            0
        ) loop
            if trim(regexp_substr(in_role_codes, '[^:]+', 1, i)) is not null then   -- a NULL would empty NOT IN
                l_roles.extend;
                l_roles(l_roles.count) := upper(trim(regexp_substr(in_role_codes, '[^:]+', 1, i)));

            end if;
        end loop;

        -- Remove first, so that a refused removal stops before anything is added
        for r in (
            select
                role_code
            from
                emk_data.emk_party_roles
            where
                    party_id = in_party_id
                and role_code not in (
                    select
                        column_value
                    from
                        table ( l_roles )
                )
        ) loop
            remove_role(in_party_id, r.role_code);
        end loop;

        for i in 1..l_roles.count loop
            add_role(in_party_id,
                     l_roles(i));   -- does nothing for a role the company already has
        end loop;

    end set_roles;

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
        if not ( is_changed(l_contact.full_name,
                            trim(in_full_name))
        or is_changed(l_contact.email,
                      trim(in_email))
        or is_changed(l_contact.phone,
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
        l_user    emk_data.emk_contacts.deleted_by%type := get_current_user;   -- a private function cannot be called in SQL
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


-- sqlcl_snapshot {"hash":"98c7acf4bece89575bf3b72c8c88091eb7e472f9","type":"PACKAGE_BODY","name":"EMK_PARTY_API","schemaName":"EMK_API","sxml":""}