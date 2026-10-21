create or replace package test_emk_shipment_api as
    /**
     * Unit tests of EMK_SHIPMENT_API (M1a step 7.3, api-design.md §3, D-64):
     * the rules across tables (companies with their roles, third-party
     * carrier, CMR applicability on the pickup date, reference validity on
     * the pickup date, CMR note number not reused by a carrier), optimistic
     * locking, soft delete and restore. Companies are created through
     * EMK_PARTY_API. Rejections by role and by CMR are logged in an
     * autonomous transaction, so the suite deletes its own log entries.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Shipments EMK_SHIPMENT_API (EMK_API))
    --%suitepath(emk_api)

    --%beforeall
    procedure remember_start;

    --%afterall
    procedure delete_test_log_entries;

    --%test(A new shipment is stored with normalised values: note number upper case and trimmed, dates without time)
    procedure creates_shipment_with_normalised_values;

    --%test(A company without the role CARRIER cannot be the carrier)
    --%throws(emk_errors_pkg.c_party_role_missing)
    procedure rejects_carrier_without_role;

    --%test(The carrier cannot also be the shipper: no carriage on own account)
    --%throws(emk_errors_pkg.c_carrier_not_third_party)
    procedure rejects_carrier_as_shipper;

    --%test(The shipper may also be the consignee: transfer between two sites of a company)
    procedure accepts_shipper_as_consignee;

    --%test(A carriage between two countries that are not CMR parties is rejected: Iceland to Liechtenstein)
    --%throws(emk_errors_pkg.c_cmr_not_applicable)
    procedure rejects_carriage_outside_cmr;

    --%test(One CMR party is enough: Iceland to Germany)
    procedure accepts_one_cmr_party;

    --%test(The CMR applies from the accession date: Oman joined on 2020-12-22)
    procedure checks_cmr_on_pickup_date;

    --%test(A currency that ended is valid for an earlier pickup date: kuna in 2021)
    procedure accepts_historic_currency;

    --%test(A currency that ended is rejected for a later pickup date: kuna in 2024)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rejects_ended_currency;

    --%test(A carrier cannot reuse a CMR note number)
    --%throws(emk_errors_pkg.c_duplicate_cmr_note)
    procedure rejects_reused_cmr_note;

    --%test(A rejection by role is logged as WARN with ids only)
    procedure logs_rejection_as_warn;

    --%test(An update with an old version is rejected)
    --%throws(emk_errors_pkg.c_record_changed)
    procedure rejects_update_with_old_version;

    --%test(An update without changes writes nothing: no updated_at, no journal row)
    procedure writes_nothing_when_unchanged;

    --%test(An update to a pickup date on which the currency is no longer valid is rejected)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rechecks_currency_on_new_pickup_date;

    --%test(A shipment with an active claim cannot be deleted)
    --%throws(emk_errors_pkg.c_shipment_in_use)
    procedure rejects_delete_with_active_claim;

    --%test(Delete hides the shipment and keeps the row; restore brings it back)
    procedure deletes_and_restores_shipment;

    --%test(Restore checks the companies again: a company deleted in the meantime blocks it)
    --%throws(emk_errors_pkg.c_party_role_missing)
    procedure rechecks_roles_on_restore;

    --%context(Consignment note particulars: date, declared value, special interest (D-78, D-79))

    --%test(D-79: the date of the consignment note is required)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_missing_note_date;

    --%test(D-81, spec §5.3 L14: a consignment note dated after the pickup is accepted)
    procedure accepts_note_date_after_pickup;

    --%test(D-78: a declared value is stored with its currency in upper case and shown by the view)
    procedure stores_declared_value;

    --%test(D-78: a declared value in a currency without an ECB rate is rejected)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rejects_declared_value_currency_without_rate;

    --%test(D-78: a declared value without its currency is rejected)
    --%throws(-2290)
    procedure rejects_declared_value_without_currency;

    --%endcontext
end test_emk_shipment_api;
/

create or replace package body test_emk_shipment_api as

    g_started timestamp with time zone;

    -- Suite set-up and clean-up ----------------------------------------------------

    procedure remember_start is
    begin
        g_started := systimestamp;
    end remember_start;

    -- Log entries are committed by EMK_LOG_PKG; only those of this run and user are deleted
    procedure delete_test_log_entries is
        pragma autonomous_transaction;
    begin
        delete from emk_log
        where  module like 'EMK\_SHIPMENT\_API.%' escape '\'
        and    created_at >= g_started
        and    created_by = coalesce(sys_context('USERENV', 'PROXY_USER'), sys_context('USERENV', 'SESSION_USER'));
        commit;
    end delete_test_log_entries;

    -- Test data helpers --------------------------------------------------------------

    function new_party (
        in_name    in varchar2,
        in_country in varchar2,
        in_roles   in varchar2
    ) return emk_data.emk_parties.party_id%type is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => in_name,
                                   in_vat_number    => null,
                                   in_country_code  => in_country,
                                   in_street        => null,
                                   in_postal_code   => null,
                                   in_city          => null,
                                   in_language_code => 'en',
                                   in_role_codes    => in_roles,
                                   out_party_id     => l_id);
        return l_id;
    end new_party;

    function new_shipment (
        in_note        in varchar2,
        in_shipper     in emk_data.emk_shipments.shipper_id%type,
        in_carrier     in emk_data.emk_shipments.carrier_id%type,
        in_consignee   in emk_data.emk_shipments.consignee_id%type,
        in_origin      in varchar2 default 'DE',
        in_destination in varchar2 default 'FR',
        in_pickup_date in date default date '2026-09-01',
        in_charges     in number default null,
        in_currency    in varchar2 default null,
        in_note_date   in date default null,       -- NULL = the pickup date
        in_value       in number default null,
        in_value_cur   in varchar2 default null
    ) return emk_data.emk_shipments.shipment_id%type is
        l_id emk_data.emk_shipments.shipment_id%type;
    begin
        emk_shipment_api.create_shipment(in_cmr_note_no          => in_note,
                                         in_cmr_note_date        => nvl(in_note_date, in_pickup_date),
                                         in_shipper_id           => in_shipper,
                                         in_carrier_id           => in_carrier,
                                         in_consignee_id         => in_consignee,
                                         in_pickup_place         => 'Pickup place',
                                         in_origin_country       => in_origin,
                                         in_delivery_place       => 'Delivery place',
                                         in_destination_country  => in_destination,
                                         in_pickup_date          => in_pickup_date,
                                         in_agreed_delivery_date => null,
                                         in_delivery_date        => null,
                                         in_disposal_date        => null,
                                         in_goods_description    => 'Test goods',
                                         in_packages             => 1,
                                         in_gross_weight_kg      => 100,
                                         in_carriage_charges     => in_charges,
                                         in_currency_code        => in_currency,
                                         in_declared_value       => in_value,
                                         in_declared_value_currency => in_value_cur,
                                         in_special_interest     => null,
                                         in_special_interest_currency => null,
                                         out_shipment_id         => l_id);
        return l_id;
    end new_shipment;

    function version_of_shipment (
        in_shipment_id in emk_data.emk_shipments.shipment_id%type
    ) return emk_data.emk_shipments.updated_at%type is
        l_version emk_data.emk_shipments.updated_at%type;
    begin
        select nvl(updated_at, created_at) into l_version from emk_data.emk_shipments where shipment_id = in_shipment_id;
        return l_version;
    end version_of_shipment;

    -- Same values as the shipment, so that an update changes only what a test sets
    procedure update_from_row (
        in_row     in emk_data.emk_shipments%rowtype,
        in_version in emk_data.emk_shipments.updated_at%type
    ) is
    begin
        emk_shipment_api.update_shipment(in_shipment_id          => in_row.shipment_id,
                                         in_expected_updated_at  => in_version,
                                         in_cmr_note_no          => in_row.cmr_note_no,
                                         in_cmr_note_date        => in_row.cmr_note_date,
                                         in_shipper_id           => in_row.shipper_id,
                                         in_carrier_id           => in_row.carrier_id,
                                         in_consignee_id         => in_row.consignee_id,
                                         in_pickup_place         => in_row.pickup_place,
                                         in_origin_country       => in_row.origin_country,
                                         in_delivery_place       => in_row.delivery_place,
                                         in_destination_country  => in_row.destination_country,
                                         in_pickup_date          => in_row.pickup_date,
                                         in_agreed_delivery_date => in_row.agreed_delivery_date,
                                         in_delivery_date        => in_row.delivery_date,
                                         in_disposal_date        => in_row.disposal_date,
                                         in_goods_description    => in_row.goods_description,
                                         in_packages             => in_row.packages,
                                         in_gross_weight_kg      => in_row.gross_weight_kg,
                                         in_carriage_charges     => in_row.carriage_charges,
                                         in_currency_code        => in_row.currency_code,
                                         in_declared_value       => in_row.declared_value,
                                         in_declared_value_currency => in_row.declared_value_currency,
                                         in_special_interest     => in_row.special_interest,
                                         in_special_interest_currency => in_row.special_interest_currency);
    end update_from_row;

    -- Tests --------------------------------------------------------------------------

    procedure creates_shipment_with_normalised_values is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_row       emk_data.emk_shipments%rowtype;
    begin
        l_id := new_shipment(' cmr-test-0001 ', l_shipper, l_carrier, l_consignee, 'de', 'fr',
                             to_date('2026-09-01 15:30', 'YYYY-MM-DD HH24:MI'), 250, 'pln');
        select * into l_row from emk_data.emk_shipments where shipment_id = l_id;
        ut.expect(l_row.cmr_note_no).to_equal('CMR-TEST-0001');
        ut.expect(l_row.origin_country).to_equal('DE');
        ut.expect(l_row.currency_code).to_equal('PLN');
        ut.expect(l_row.pickup_date).to_equal(date '2026-09-01');
        ut.expect(l_row.deleted_yn).to_equal('N');
    end creates_shipment_with_normalised_values;

    procedure rejects_carrier_without_role is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Not a Carrier', 'PL', 'FORWARDER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0002', l_shipper, l_carrier, l_consignee);
    end rejects_carrier_without_role;

    procedure rejects_carrier_as_shipper is
        l_company   emk_data.emk_parties.party_id%type := new_party('Test Own Trucks', 'DE', 'SHIPPER:CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0003', l_company, l_company, l_consignee);
    end rejects_carrier_as_shipper;

    procedure accepts_shipper_as_consignee is
        l_company emk_data.emk_parties.party_id%type := new_party('Test Two Sites', 'DE', 'SHIPPER:CONSIGNEE');
        l_carrier emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_id      emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0004', l_company, l_carrier, l_company);
        ut.expect(l_id).to_be_not_null();
    end accepts_shipper_as_consignee;

    procedure rejects_carriage_outside_cmr is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'IS', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'LI', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0005', l_shipper, l_carrier, l_consignee, 'IS', 'LI');
    end rejects_carriage_outside_cmr;

    procedure accepts_one_cmr_party is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'IS', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'DE', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0006', l_shipper, l_carrier, l_consignee, 'IS', 'DE');
        ut.expect(l_id).to_be_not_null();
    end accepts_one_cmr_party;

    procedure checks_cmr_on_pickup_date is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'OM', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'IS', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        -- Oman to Iceland: only Oman can make it a CMR carriage, and only from its accession
        begin
            l_id := new_shipment('CMR-TEST-0007', l_shipper, l_carrier, l_consignee, 'OM', 'IS', date '2020-12-21');
            ut.fail('A carriage before the accession of Oman was accepted');
        exception
            when emk_errors_pkg.e_cmr_not_applicable then
                null;
        end;
        l_id := new_shipment('CMR-TEST-0008', l_shipper, l_carrier, l_consignee, 'OM', 'IS', date '2020-12-22');
        ut.expect(l_id).to_be_not_null();
    end checks_cmr_on_pickup_date;

    procedure accepts_historic_currency is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0009', l_shipper, l_carrier, l_consignee, 'DE', 'FR', date '2021-06-01', 1000, 'HRK');
        ut.expect(l_id).to_be_not_null();
    end accepts_historic_currency;

    procedure rejects_ended_currency is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0010', l_shipper, l_carrier, l_consignee, 'DE', 'FR', date '2024-06-01', 1000, 'HRK');
    end rejects_ended_currency;

    procedure rejects_reused_cmr_note is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0011', l_shipper, l_carrier, l_consignee);
        l_id := new_shipment(' cmr-test-0011', l_shipper, l_carrier, l_consignee);
    end rejects_reused_cmr_note;

    procedure logs_rejection_as_warn is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Not a Carrier', 'PL', 'FORWARDER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_level     emk_log.log_level%type;
        l_context   varchar2(4000 char);
    begin
        begin
            l_id := new_shipment('CMR-TEST-0012', l_shipper, l_carrier, l_consignee);
        exception
            when emk_errors_pkg.e_party_role_missing then
                null;
        end;
        select log_level, json_serialize(context)
        into   l_level, l_context
        from   emk_log
        where  module like 'EMK\_SHIPMENT\_API.%' escape '\'
        and    created_at >= g_started
        and    json_value(context, '$.carrier_id' returning number) = l_carrier;
        ut.expect(l_level).to_equal('WARN');
        ut.expect(l_context).not_to_be_like('%Test%');   -- ids only, no names
    end logs_rejection_as_warn;

    procedure rejects_update_with_old_version is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_row       emk_data.emk_shipments%rowtype;
    begin
        l_id := new_shipment('CMR-TEST-0013', l_shipper, l_carrier, l_consignee);
        select * into l_row from emk_data.emk_shipments where shipment_id = l_id;
        l_row.goods_description := 'Changed goods';
        update_from_row(l_row, version_of_shipment(l_id) - interval '1' second);
    end rejects_update_with_old_version;

    procedure writes_nothing_when_unchanged is
        l_shipper    emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier    emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee  emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id         emk_data.emk_shipments.shipment_id%type;
        l_row        emk_data.emk_shipments%rowtype;
        l_journal    pls_integer;
    begin
        l_id := new_shipment('CMR-TEST-0014', l_shipper, l_carrier, l_consignee);
        select * into l_row from emk_data.emk_shipments where shipment_id = l_id;
        update_from_row(l_row, version_of_shipment(l_id));
        select * into l_row from emk_data.emk_shipments where shipment_id = l_id;
        select count(*) into l_journal from emk_data.emk_shipments_jn where shipment_id = l_id;
        ut.expect(l_row.updated_at).to_be_null();
        ut.expect(l_journal).to_equal(0);
    end writes_nothing_when_unchanged;

    procedure rechecks_currency_on_new_pickup_date is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_row       emk_data.emk_shipments%rowtype;
    begin
        l_id := new_shipment('CMR-TEST-0015', l_shipper, l_carrier, l_consignee, 'DE', 'FR', date '2021-06-01', 1000, 'HRK');
        select * into l_row from emk_data.emk_shipments where shipment_id = l_id;
        l_row.pickup_date := date '2024-06-01';
        update_from_row(l_row, version_of_shipment(l_id));
    end rechecks_currency_on_new_pickup_date;

    procedure rejects_delete_with_active_claim is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-0016', l_shipper, l_carrier, l_consignee);
        insert into emk_data.emk_claims (claim_no, shipment_id, claim_type, damage_apparent_yn, handler, registration_date)
        values ('CLM-2026-999101', l_id, 'DAMAGE', 'Y', 'TEST_HANDLER', date '2026-09-05');
        emk_shipment_api.delete_shipment(l_id, version_of_shipment(l_id));
    end rejects_delete_with_active_claim;

    procedure deletes_and_restores_shipment is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_deleted   emk_data.emk_shipments.deleted_yn%type;
        l_by        emk_data.emk_shipments.deleted_by%type;
    begin
        l_id := new_shipment('CMR-TEST-0017', l_shipper, l_carrier, l_consignee);
        emk_shipment_api.delete_shipment(l_id, version_of_shipment(l_id));
        select deleted_yn, deleted_by into l_deleted, l_by from emk_data.emk_shipments where shipment_id = l_id;
        ut.expect(l_deleted).to_equal('Y');
        ut.expect(l_by).to_be_not_null();
        emk_shipment_api.restore_shipment(l_id);
        select deleted_yn, deleted_by into l_deleted, l_by from emk_data.emk_shipments where shipment_id = l_id;
        ut.expect(l_deleted).to_equal('N');
        ut.expect(l_by).to_be_null();
    end deletes_and_restores_shipment;

    procedure rechecks_roles_on_restore is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_version   emk_data.emk_parties.updated_at%type;
    begin
        l_id := new_shipment('CMR-TEST-0018', l_shipper, l_carrier, l_consignee);
        emk_shipment_api.delete_shipment(l_id, version_of_shipment(l_id));
        -- With the shipment deleted, the carrier is no longer in use and can be deleted
        select nvl(updated_at, created_at) into l_version from emk_data.emk_parties where party_id = l_carrier;
        emk_party_api.delete_party(l_carrier, l_version);
        emk_shipment_api.restore_shipment(l_id);
    end rechecks_roles_on_restore;

    -- Consignment note particulars (D-78, D-79) ---------------------------------------------

    procedure rejects_missing_note_date is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        emk_shipment_api.create_shipment(in_cmr_note_no => 'CMR-TEST-NOTE-DATE', in_cmr_note_date => null,
            in_shipper_id => l_shipper, in_carrier_id => l_carrier, in_consignee_id => l_consignee,
            in_pickup_place => 'Berlin', in_origin_country => 'DE', in_delivery_place => 'Paris',
            in_destination_country => 'FR', in_pickup_date => date '2026-09-01', in_agreed_delivery_date => null,
            in_delivery_date => null, in_disposal_date => null, in_goods_description => 'Test goods',
            in_packages => 1, in_gross_weight_kg => 100, in_carriage_charges => null, in_currency_code => null,
            in_declared_value => null, in_declared_value_currency => null, in_special_interest => null,
            in_special_interest_currency => null, out_shipment_id => l_id);
    end rejects_missing_note_date;

    procedure accepts_note_date_after_pickup is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_note_date emk_data.emk_shipments.cmr_note_date%type;
    begin
        l_id := new_shipment('CMR-TEST-LATE-NOTE', l_shipper, l_carrier, l_consignee, in_note_date => date '2026-09-02');
        select cmr_note_date into l_note_date from emk_data.emk_shipments where shipment_id = l_id;
        ut.expect(l_note_date).to_equal(date '2026-09-02');
    end accepts_note_date_after_pickup;

    procedure stores_declared_value is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
        l_value     emk_v_shipments.declared_value%type;
        l_currency  emk_v_shipments.declared_value_currency%type;
        l_note_date emk_v_shipments.cmr_note_date%type;
    begin
        l_id := new_shipment('CMR-TEST-VALUE', l_shipper, l_carrier, l_consignee,
                             in_note_date => date '2026-08-30', in_value => 50000, in_value_cur => ' chf ');
        select declared_value, declared_value_currency, cmr_note_date
        into   l_value, l_currency, l_note_date
        from   emk_v_shipments
        where  shipment_id = l_id;
        ut.expect(l_value, 'declared value').to_equal(50000);
        ut.expect(l_currency, 'currency').to_equal('CHF');
        ut.expect(l_note_date, 'date of the note').to_equal(date '2026-08-30');
    end stores_declared_value;

    procedure rejects_declared_value_currency_without_rate is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-VALUE-RUB', l_shipper, l_carrier, l_consignee, in_value => 1000, in_value_cur => 'RUB');
    end rejects_declared_value_currency_without_rate;

    procedure rejects_declared_value_without_currency is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE', 'SHIPPER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_id        emk_data.emk_shipments.shipment_id%type;
    begin
        l_id := new_shipment('CMR-TEST-VALUE-NO-CUR', l_shipper, l_carrier, l_consignee, in_value => 1000);
    end rejects_declared_value_without_currency;

end test_emk_shipment_api;
/
