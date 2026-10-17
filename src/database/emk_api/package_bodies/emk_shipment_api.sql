create or replace package body emk_api.emk_shipment_api as
    /**
     * Implementation of EMK_SHIPMENT_API; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    e_resource_busy exception;          -- ORA-00054: row locked, NOWAIT
    pragma exception_init ( e_resource_busy, -54 );
    c_shipper   constant emk_data.emk_party_roles.role_code%type := 'SHIPPER';
    c_carrier   constant emk_data.emk_party_roles.role_code%type := 'CARRIER';
    c_consignee constant emk_data.emk_party_roles.role_code%type := 'CONSIGNEE';
    c_euro      constant emk_data.emk_currencies.currency_code%type := 'EUR';

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

    -- TRUE if two values differ; NULL and NULL count as equal. Never returns NULL.
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

    function is_changed (
        in_old in number,
        in_new in number
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

    function is_changed (
        in_old in date,
        in_new in date
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

    -- Rejects a request and records it as WARN with ids only (D-64)
    procedure reject (
        in_error_code in pls_integer,
        in_message    in varchar2,
        in_context    in varchar2
    ) is
    begin
        emk_log_pkg.log_warn('Shipment rejected: ' || in_message, in_context);
        raise_application_error(in_error_code, in_message);
    end reject;

    -- CMR Art. 1(1) and BR-16: a third-party carrier; every company active with its role
    procedure check_parties (
        in_shipment_id  in emk_data.emk_shipments.shipment_id%type,
        in_shipper_id   in emk_data.emk_shipments.shipper_id%type,
        in_carrier_id   in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id in emk_data.emk_shipments.consignee_id%type
    ) is

        l_context varchar2(4000 char) :=
            json_object(
                'shipment_id' value in_shipment_id,
                'shipper_id' value in_shipper_id,
                'carrier_id' value in_carrier_id,
                'consignee_id' value in_consignee_id
            );
    begin
        if in_carrier_id = in_shipper_id
        or in_carrier_id = in_consignee_id then
            raise_application_error(emk_errors_pkg.c_carrier_not_third_party, 'The carrier must be another company than the shipper and the consignee ' || '(CMR: carriage for reward, not on own account)'
            );
        end if;

        if not emk_party_api.has_role(in_shipper_id, c_shipper) then
            reject(emk_errors_pkg.c_party_role_missing, 'The shipper is not an active company with the role SHIPPER', l_context);
        end if;

        if not emk_party_api.has_role(in_carrier_id, c_carrier) then
            reject(emk_errors_pkg.c_party_role_missing, 'The carrier is not an active company with the role CARRIER', l_context);
        end if;

        if not emk_party_api.has_role(in_consignee_id, c_consignee) then
            reject(emk_errors_pkg.c_party_role_missing, 'The consignee is not an active company with the role CONSIGNEE', l_context);
        end if;

    end check_parties;

    -- A country exists and is valid on a date (D-64)
    procedure check_country (
        in_country_code in emk_data.emk_countries.country_code%type,
        in_on_date      in date
    ) is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
            emk_data.emk_countries
        where
                country_code = in_country_code
            and valid_from <= in_on_date
            and ( valid_to is null
                  or valid_to >= in_on_date );

        if l_count = 0 then
            raise_application_error(emk_errors_pkg.c_reference_not_valid,
                                    'Country '
                                    || in_country_code
                                    || ' is unknown or not valid on '
                                    || to_char(in_on_date, 'YYYY-MM-DD'));

        end if;

    end check_country;

    -- The currency is EUR or has an ECB rate, and is valid on a date (BR-12, D-64)
    procedure check_currency (
        in_currency_code in emk_data.emk_currencies.currency_code%type,
        in_on_date       in date
    ) is
        l_count pls_integer;
    begin
        if in_currency_code is null then
            return;   -- no carriage charges; the table checks that both are empty together
        end if;
        select
            count(*)
        into l_count
        from
            emk_data.emk_currencies
        where
                currency_code = in_currency_code
            and ( currency_code = c_euro
                  or ecb_rate_yn = 'Y' )
            and valid_from <= in_on_date
            and ( valid_to is null
                  or valid_to >= in_on_date );

        if l_count = 0 then
            raise_application_error(emk_errors_pkg.c_reference_not_valid,
                                    'Currency '
                                    || in_currency_code
                                    || ' is unknown, has no ECB rate or is not valid on '
                                    || to_char(in_on_date, 'YYYY-MM-DD'));
        end if;

    end check_currency;

    -- BR-17: the origin or the destination is a CMR party on the pickup date
    procedure check_cmr (
        in_shipment_id         in emk_data.emk_shipments.shipment_id%type,
        in_origin_country      in emk_data.emk_shipments.origin_country%type,
        in_destination_country in emk_data.emk_shipments.destination_country%type,
        in_pickup_date         in emk_data.emk_shipments.pickup_date%type
    ) is
        l_count pls_integer;
    begin
        select
            count(*)
        into l_count
        from
            emk_data.emk_countries
        where
            country_code in ( in_origin_country, in_destination_country )
            and cmr_party_since <= in_pickup_date;

        if l_count = 0 then
            reject(emk_errors_pkg.c_cmr_not_applicable,
                   'Neither '
                   || in_origin_country
                   || ' nor '
                   || in_destination_country
                   || ' is a CMR party on '
                   || to_char(in_pickup_date, 'YYYY-MM-DD'),
                   json_object(
                    'shipment_id' value in_shipment_id,
                               'origin_country' value in_origin_country,
                               'destination_country' value in_destination_country,
                               'pickup_date' value to_char(in_pickup_date, 'YYYY-MM-DD')
                )
            );

        end if;

    end check_cmr;

    -- Every rule across tables, in the order of the specification
    procedure check_shipment (
        in_shipment_id         in emk_data.emk_shipments.shipment_id%type,
        in_shipper_id          in emk_data.emk_shipments.shipper_id%type,
        in_carrier_id          in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id        in emk_data.emk_shipments.consignee_id%type,
        in_origin_country      in emk_data.emk_shipments.origin_country%type,
        in_destination_country in emk_data.emk_shipments.destination_country%type,
        in_pickup_date         in emk_data.emk_shipments.pickup_date%type,
        in_currency_code       in emk_data.emk_shipments.currency_code%type
    ) is
    begin
        if in_pickup_date is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'The pickup date is required');
        end if;
        check_parties(in_shipment_id, in_shipper_id, in_carrier_id, in_consignee_id);
        check_country(in_origin_country, in_pickup_date);
        check_country(in_destination_country, in_pickup_date);
        check_currency(in_currency_code, in_pickup_date);
        check_cmr(in_shipment_id, in_origin_country, in_destination_country, in_pickup_date);
    end check_shipment;

    -- Locks a shipment (NOWAIT), checks that it is active and, if asked, its version
    procedure lock_shipment (
        in_shipment_id         in emk_data.emk_shipments.shipment_id%type,
        in_expected_updated_at in emk_data.emk_shipments.updated_at%type,
        in_check_version       in boolean,
        out_shipment           out emk_data.emk_shipments%rowtype
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
        into out_shipment
        from
            emk_data.emk_shipments
        where
            shipment_id = in_shipment_id
        for update nowait;

        if in_check_version then
            if out_shipment.deleted_yn = 'Y' then
                raise_application_error(emk_errors_pkg.c_not_found, 'Shipment '
                                                                    || in_shipment_id
                                                                    || ' is deleted');
            end if;

            if nvl(out_shipment.updated_at, out_shipment.created_at) <> in_expected_updated_at then
                raise_application_error(emk_errors_pkg.c_record_changed, 'The shipment was changed by another user: reload it');
            end if;

        end if;

    exception
        when no_data_found then
            raise_application_error(emk_errors_pkg.c_not_found, 'Shipment '
                                                                || in_shipment_id
                                                                || ' does not exist');
        when e_resource_busy then
            raise_application_error(emk_errors_pkg.c_record_locked, 'The shipment is being changed by another user: try again');
    end lock_shipment;

    -- Public subprograms -----------------------------------------------------------

    procedure create_shipment (
        in_cmr_note_no          in emk_data.emk_shipments.cmr_note_no%type,
        in_shipper_id           in emk_data.emk_shipments.shipper_id%type,
        in_carrier_id           in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id         in emk_data.emk_shipments.consignee_id%type,
        in_pickup_place         in emk_data.emk_shipments.pickup_place%type,
        in_origin_country       in emk_data.emk_shipments.origin_country%type,
        in_delivery_place       in emk_data.emk_shipments.delivery_place%type,
        in_destination_country  in emk_data.emk_shipments.destination_country%type,
        in_pickup_date          in emk_data.emk_shipments.pickup_date%type,
        in_agreed_delivery_date in emk_data.emk_shipments.agreed_delivery_date%type,
        in_delivery_date        in emk_data.emk_shipments.delivery_date%type,
        in_goods_description    in emk_data.emk_shipments.goods_description%type,
        in_packages             in emk_data.emk_shipments.packages%type,
        in_gross_weight_kg      in emk_data.emk_shipments.gross_weight_kg%type,
        in_carriage_charges     in emk_data.emk_shipments.carriage_charges%type,
        in_currency_code        in emk_data.emk_shipments.currency_code%type,
        out_shipment_id         out emk_data.emk_shipments.shipment_id%type
    ) is

        l_origin      emk_data.emk_shipments.origin_country%type := upper(trim(in_origin_country));
        l_destination emk_data.emk_shipments.destination_country%type := upper(trim(in_destination_country));
        l_currency    emk_data.emk_shipments.currency_code%type := upper(trim(in_currency_code));
        l_pickup_date emk_data.emk_shipments.pickup_date%type := trunc(in_pickup_date);
    begin
        check_shipment(null, in_shipper_id, in_carrier_id, in_consignee_id, l_origin,
                       l_destination, l_pickup_date, l_currency);

        insert into emk_data.emk_shipments (
            cmr_note_no,
            shipper_id,
            carrier_id,
            consignee_id,
            pickup_place,
            origin_country,
            delivery_place,
            destination_country,
            pickup_date,
            agreed_delivery_date,
            delivery_date,
            goods_description,
            packages,
            gross_weight_kg,
            carriage_charges,
            currency_code
        ) values ( upper(trim(in_cmr_note_no)),
                   in_shipper_id,
                   in_carrier_id,
                   in_consignee_id,
                   trim(in_pickup_place),
                   l_origin,
                   trim(in_delivery_place),
                   l_destination,
                   l_pickup_date,
                   trunc(in_agreed_delivery_date),
                   trunc(in_delivery_date),
                   trim(in_goods_description),
                   in_packages,
                   in_gross_weight_kg,
                   in_carriage_charges,
                   l_currency ) returning shipment_id into out_shipment_id;

    exception
        when dup_val_on_index then   -- the only unique key besides the identity: (carrier_id, cmr_note_no)
            raise_application_error(emk_errors_pkg.c_duplicate_cmr_note,
                                    'The carrier already used CMR note number ' || upper(trim(in_cmr_note_no)));
    end create_shipment;

    procedure update_shipment (
        in_shipment_id          in emk_data.emk_shipments.shipment_id%type,
        in_expected_updated_at  in emk_data.emk_shipments.updated_at%type,
        in_cmr_note_no          in emk_data.emk_shipments.cmr_note_no%type,
        in_shipper_id           in emk_data.emk_shipments.shipper_id%type,
        in_carrier_id           in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id         in emk_data.emk_shipments.consignee_id%type,
        in_pickup_place         in emk_data.emk_shipments.pickup_place%type,
        in_origin_country       in emk_data.emk_shipments.origin_country%type,
        in_delivery_place       in emk_data.emk_shipments.delivery_place%type,
        in_destination_country  in emk_data.emk_shipments.destination_country%type,
        in_pickup_date          in emk_data.emk_shipments.pickup_date%type,
        in_agreed_delivery_date in emk_data.emk_shipments.agreed_delivery_date%type,
        in_delivery_date        in emk_data.emk_shipments.delivery_date%type,
        in_goods_description    in emk_data.emk_shipments.goods_description%type,
        in_packages             in emk_data.emk_shipments.packages%type,
        in_gross_weight_kg      in emk_data.emk_shipments.gross_weight_kg%type,
        in_carriage_charges     in emk_data.emk_shipments.carriage_charges%type,
        in_currency_code        in emk_data.emk_shipments.currency_code%type
    ) is

        l_old         emk_data.emk_shipments%rowtype;
        l_note        emk_data.emk_shipments.cmr_note_no%type := upper(trim(in_cmr_note_no));
        l_origin      emk_data.emk_shipments.origin_country%type := upper(trim(in_origin_country));
        l_destination emk_data.emk_shipments.destination_country%type := upper(trim(in_destination_country));
        l_currency    emk_data.emk_shipments.currency_code%type := upper(trim(in_currency_code));
        l_pickup_date emk_data.emk_shipments.pickup_date%type := trunc(in_pickup_date);
    begin
        lock_shipment(in_shipment_id, in_expected_updated_at, true, l_old);
        check_shipment(in_shipment_id, in_shipper_id, in_carrier_id, in_consignee_id, l_origin,
                       l_destination, l_pickup_date, l_currency);

        if not ( is_changed(l_old.cmr_note_no, l_note)
        or is_changed(l_old.shipper_id, in_shipper_id)
        or is_changed(l_old.carrier_id, in_carrier_id)
        or is_changed(l_old.consignee_id, in_consignee_id)
        or is_changed(l_old.pickup_place,
                      trim(in_pickup_place))
        or is_changed(l_old.origin_country, l_origin)
        or is_changed(l_old.delivery_place,
                      trim(in_delivery_place))
        or is_changed(l_old.destination_country, l_destination)
        or is_changed(l_old.pickup_date, l_pickup_date)
        or is_changed(l_old.agreed_delivery_date,
                      trunc(in_agreed_delivery_date))
        or is_changed(l_old.delivery_date,
                      trunc(in_delivery_date))
        or is_changed(l_old.goods_description,
                      trim(in_goods_description))
        or is_changed(l_old.packages, in_packages)
        or is_changed(l_old.gross_weight_kg, in_gross_weight_kg)
        or is_changed(l_old.carriage_charges, in_carriage_charges)
        or is_changed(l_old.currency_code, l_currency) ) then
            return;   -- nothing changed: no update, no journal row
        end if;

        update emk_data.emk_shipments
        set
            cmr_note_no = l_note,
            shipper_id = in_shipper_id,
            carrier_id = in_carrier_id,
            consignee_id = in_consignee_id,
            pickup_place = trim(in_pickup_place),
            origin_country = l_origin,
            delivery_place = trim(in_delivery_place),
            destination_country = l_destination,
            pickup_date = l_pickup_date,
            agreed_delivery_date = trunc(in_agreed_delivery_date),
            delivery_date = trunc(in_delivery_date),
            goods_description = trim(in_goods_description),
            packages = in_packages,
            gross_weight_kg = in_gross_weight_kg,
            carriage_charges = in_carriage_charges,
            currency_code = l_currency
        where
            shipment_id = in_shipment_id;

    exception
        when dup_val_on_index then
            raise_application_error(emk_errors_pkg.c_duplicate_cmr_note, 'The carrier already used CMR note number ' || l_note);
    end update_shipment;

    procedure delete_shipment (
        in_shipment_id         in emk_data.emk_shipments.shipment_id%type,
        in_expected_updated_at in emk_data.emk_shipments.updated_at%type
    ) is

        l_old   emk_data.emk_shipments%rowtype;
        l_count pls_integer;
        l_user  emk_data.emk_shipments.deleted_by%type := get_current_user;   -- a private function cannot be called in SQL
    begin
        lock_shipment(in_shipment_id, in_expected_updated_at, true, l_old);
        select
            count(*)
        into l_count
        from
            emk_data.emk_claims
        where
                shipment_id = in_shipment_id
            and deleted_yn = 'N';

        if l_count > 0 then
            raise_application_error(emk_errors_pkg.c_shipment_in_use, 'The shipment has '
                                                                      || l_count
                                                                      || ' active claim(s)');
        end if;

        update emk_data.emk_shipments
        set
            deleted_yn = 'Y',
            deleted_by = l_user,
            deleted_at = systimestamp
        where
            shipment_id = in_shipment_id;

    end delete_shipment;

    procedure restore_shipment (
        in_shipment_id in emk_data.emk_shipments.shipment_id%type
    ) is
        l_old emk_data.emk_shipments%rowtype;
    begin
        lock_shipment(in_shipment_id, null, false, l_old);
        if l_old.deleted_yn = 'N' then
            return;
        end if;

        -- A company may have been deleted or lost its role while the shipment was deleted
        check_parties(in_shipment_id, l_old.shipper_id, l_old.carrier_id, l_old.consignee_id);
        update emk_data.emk_shipments
        set
            deleted_yn = 'N',
            deleted_by = null,
            deleted_at = null
        where
            shipment_id = in_shipment_id;

    end restore_shipment;

end emk_shipment_api;
/


-- sqlcl_snapshot {"hash":"ae838e01d0d5ada13371806053623f7321effcc7","type":"PACKAGE_BODY","name":"EMK_SHIPMENT_API","schemaName":"EMK_API","sxml":""}