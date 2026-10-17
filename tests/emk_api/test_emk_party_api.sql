create or replace package test_emk_party_api as
    /**
     * Unit tests of EMK_PARTY_API (M1a step 7.2, api-design.md §3): companies,
     * their roles (BR-16, T-M1-29) and contact persons; normalised values,
     * VAT rules, optimistic locking (D-43), soft delete and restore (BR-13,
     * D-39, T-M1-08). Shipments that use a company are inserted directly with
     * the grants of EMK_API; utPLSQL rolls everything back.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Companies, roles and contacts EMK_PARTY_API (EMK_API))
    --%suitepath(emk_api)

    --%context(Companies)

    --%test(A new company is stored with normalised values: trimmed name, VAT and country upper case, language en)
    procedure creates_party_with_normalised_values;

    --%test(A VAT number of another country is rejected)
    --%throws(emk_errors_pkg.c_vat_country_mismatch)
    procedure rejects_vat_of_other_country;

    --%test(A company in GB may use the Northern Ireland prefix XI)
    procedure accepts_xi_vat_for_gb;

    --%test(A company outside the EU has no EU VAT number)
    --%throws(emk_errors_pkg.c_vat_country_mismatch)
    procedure rejects_vat_outside_eu;

    --%test(An unknown country is rejected)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rejects_unknown_country;

    --%test(A VAT number used by another company is rejected)
    --%throws(emk_errors_pkg.c_duplicate_vat)
    procedure rejects_duplicate_vat;

    --%test(D-39: a VAT number of a deleted company asks to restore that company)
    procedure asks_to_restore_owner_of_vat;

    --%test(D-43: an update with an old version is rejected)
    --%throws(emk_errors_pkg.c_record_changed)
    procedure rejects_update_with_old_version;

    --%test(An update without changes writes nothing: no updated_at, no journal row)
    procedure writes_nothing_when_unchanged;

    --%test(An update changes the row and the journal keeps the previous values)
    procedure updates_party_and_keeps_journal;

    --%test(A deleted company cannot be updated)
    --%throws(emk_errors_pkg.c_not_found)
    procedure rejects_update_of_deleted_party;

    --%test(A company used by an active shipment cannot be deleted)
    --%throws(emk_errors_pkg.c_party_in_use)
    procedure rejects_delete_of_party_in_use;

    --%test(BR-13: delete hides the company and its contacts but keeps the rows)
    procedure deletes_party_and_contacts;

    --%test(D-39: restore brings the company back; its contacts are restored one by one)
    procedure restores_party_then_contact;

    --%endcontext

    --%context(Roles, BR-16)

    --%test(Adding a role twice keeps one row; has_role sees it only while the company is active)
    procedure adds_role_once;

    --%test(An unknown role is rejected)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_unknown_role;

    --%test(T-M1-29: a role used by a shipment, also a deleted one, cannot be removed)
    --%throws(emk_errors_pkg.c_party_role_in_use)
    procedure rejects_removal_of_role_in_use;

    --%test(set_roles adds the missing roles and removes the others; an empty list removes all)
    procedure sets_complete_role_list;

    --%endcontext

    --%context(Contacts)

    --%test(A phone number is stored without spaces (E.164))
    procedure normalises_contact_phone;

    --%test(A contact of a deleted company cannot be restored)
    --%throws(emk_errors_pkg.c_not_found)
    procedure rejects_restore_of_contact_of_deleted_party;

    --%endcontext
end test_emk_party_api;
/

create or replace package body test_emk_party_api as

    -- Test data helpers ----------------------------------------------------------

    function new_party (
        in_name    in varchar2,
        in_country in varchar2,
        in_vat     in varchar2 default null
    ) return emk_data.emk_parties.party_id%type is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => in_name,
                                   in_vat_number    => in_vat,
                                   in_country_code  => in_country,
                                   in_street        => null,
                                   in_postal_code   => null,
                                   in_city          => null,
                                   in_language_code => null,
                                   out_party_id     => l_id);
        return l_id;
    end new_party;

    function version_of_party (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return emk_data.emk_parties.updated_at%type is
        l_version emk_data.emk_parties.updated_at%type;
    begin
        select nvl(updated_at, created_at) into l_version from emk_data.emk_parties where party_id = in_party_id;
        return l_version;
    end version_of_party;

    function new_shipment (
        in_shipper   in emk_data.emk_shipments.shipper_id%type,
        in_carrier   in emk_data.emk_shipments.carrier_id%type,
        in_consignee in emk_data.emk_shipments.consignee_id%type
    ) return emk_data.emk_shipments.shipment_id%type is
        l_id emk_data.emk_shipments.shipment_id%type;
    begin
        insert into emk_data.emk_shipments (cmr_note_no, shipper_id, carrier_id, consignee_id, pickup_place,
                                            origin_country, delivery_place, destination_country, pickup_date,
                                            goods_description, gross_weight_kg)
        values ('CMR-TEST-PARTY-' || in_carrier, in_shipper, in_carrier, in_consignee, 'Berlin', 'DE', 'Paris', 'FR',
                date '2026-09-01', 'Goods', 10)
        returning shipment_id into l_id;
        return l_id;
    end new_shipment;

    -- Companies ------------------------------------------------------------------

    procedure creates_party_with_normalised_values is
        l_id    emk_data.emk_parties.party_id%type;
        l_party emk_data.emk_parties%rowtype;
    begin
        emk_party_api.create_party(in_name          => '  Test Spedition GmbH  ',
                                   in_vat_number    => ' de 123 456 789 ',
                                   in_country_code  => 'de',
                                   in_street        => ' Hauptstrasse 1 ',
                                   in_postal_code   => '10115',
                                   in_city          => ' Berlin ',
                                   in_language_code => null,
                                   out_party_id     => l_id);
        select * into l_party from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_party.name).to_equal('Test Spedition GmbH');
        ut.expect(l_party.vat_number).to_equal('DE123456789');
        ut.expect(l_party.country_code).to_equal('DE');
        ut.expect(l_party.city).to_equal('Berlin');
        ut.expect(l_party.language_code).to_equal('en');
        ut.expect(l_party.deleted_yn).to_equal('N');
    end creates_party_with_normalised_values;

    procedure rejects_vat_of_other_country is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test Company', 'DE', 'FR12345678901');
    end rejects_vat_of_other_country;

    procedure accepts_xi_vat_for_gb is
        l_id  emk_data.emk_parties.party_id%type;
        l_vat emk_data.emk_parties.vat_number%type;
    begin
        l_id := new_party('Test Belfast Ltd', 'GB', 'XI123456789');
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_vat).to_equal('XI123456789');
    end accepts_xi_vat_for_gb;

    procedure rejects_vat_outside_eu is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test AG', 'CH', 'CHE123456789');
    end rejects_vat_outside_eu;

    procedure rejects_unknown_country is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test Company', 'ZZ');
    end rejects_unknown_country;

    procedure rejects_duplicate_vat is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test One', 'DE', 'DE999999901');
        l_id := new_party('Test Two', 'DE', 'DE999999901');
    end rejects_duplicate_vat;

    procedure asks_to_restore_owner_of_vat is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test One', 'DE', 'DE999999902');
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        begin
            l_id := new_party('Test Two', 'DE', 'DE999999902');
            ut.fail('A duplicate VAT number was accepted');
        exception
            when emk_errors_pkg.e_duplicate_vat then
                ut.expect(sqlerrm).to_be_like('%restore%');
        end;
    end asks_to_restore_owner_of_vat;

    procedure rejects_update_with_old_version is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id) - interval '1' second,
                                   in_name                => 'Test Company New',
                                   in_vat_number          => null,
                                   in_country_code        => 'DE',
                                   in_street              => null,
                                   in_postal_code         => null,
                                   in_city                => null,
                                   in_language_code       => 'en');
    end rejects_update_with_old_version;

    procedure writes_nothing_when_unchanged is
        l_id         emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_updated_at emk_data.emk_parties.updated_at%type;
        l_journal    pls_integer;
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id),
                                   in_name                => ' Test Company ',
                                   in_vat_number          => null,
                                   in_country_code        => 'de',
                                   in_street              => null,
                                   in_postal_code         => null,
                                   in_city                => null,
                                   in_language_code       => null);
        select updated_at into l_updated_at from emk_data.emk_parties where party_id = l_id;
        select count(*) into l_journal from emk_data.emk_parties_jn where party_id = l_id;
        ut.expect(l_updated_at).to_be_null();
        ut.expect(l_journal).to_equal(0);
    end writes_nothing_when_unchanged;

    procedure updates_party_and_keeps_journal is
        l_id         emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_name       emk_data.emk_parties.name%type;
        l_updated_at emk_data.emk_parties.updated_at%type;
        l_old_name   emk_data.emk_parties_jn.name%type;
        l_operation  emk_data.emk_parties_jn.jn_operation%type;
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id),
                                   in_name                => 'Test Company Renamed',
                                   in_vat_number          => null,
                                   in_country_code        => 'DE',
                                   in_street              => null,
                                   in_postal_code         => null,
                                   in_city                => null,
                                   in_language_code       => 'en');
        select name, updated_at into l_name, l_updated_at from emk_data.emk_parties where party_id = l_id;
        select name, jn_operation into l_old_name, l_operation from emk_data.emk_parties_jn where party_id = l_id;
        ut.expect(l_name).to_equal('Test Company Renamed');
        ut.expect(l_updated_at).to_be_not_null();
        ut.expect(l_old_name).to_equal('Test Company');
        ut.expect(l_operation).to_equal('U');
    end updates_party_and_keeps_journal;

    procedure rejects_update_of_deleted_party is
        l_id      emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_version emk_data.emk_parties.updated_at%type;
    begin
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        l_version := version_of_party(l_id);
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => l_version,
                                   in_name                => 'Test Company New',
                                   in_vat_number          => null,
                                   in_country_code        => 'DE',
                                   in_street              => null,
                                   in_postal_code         => null,
                                   in_city                => null,
                                   in_language_code       => 'en');
    end rejects_update_of_deleted_party;

    procedure rejects_delete_of_party_in_use is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
    begin
        l_shipment := new_shipment(l_shipper, l_carrier, l_consignee);
        emk_party_api.delete_party(l_carrier, version_of_party(l_carrier));
    end rejects_delete_of_party_in_use;

    procedure deletes_party_and_contacts is
        l_id         emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_contact    emk_data.emk_contacts.contact_id%type;
        l_party_del  emk_data.emk_parties.deleted_yn%type;
        l_party_by   emk_data.emk_parties.deleted_by%type;
        l_contact_del emk_data.emk_contacts.deleted_yn%type;
    begin
        emk_party_api.create_contact(l_id, 'Test Person', 'test.person@example.com', null, l_contact);
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        select deleted_yn, deleted_by into l_party_del, l_party_by from emk_data.emk_parties where party_id = l_id;
        select deleted_yn into l_contact_del from emk_data.emk_contacts where contact_id = l_contact;
        ut.expect(l_party_del).to_equal('Y');
        ut.expect(l_party_by).to_be_not_null();
        ut.expect(l_contact_del).to_equal('Y');
    end deletes_party_and_contacts;

    procedure restores_party_then_contact is
        l_id          emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_contact     emk_data.emk_contacts.contact_id%type;
        l_party_del   emk_data.emk_parties.deleted_yn%type;
        l_party_by    emk_data.emk_parties.deleted_by%type;
        l_contact_del emk_data.emk_contacts.deleted_yn%type;
    begin
        emk_party_api.create_contact(l_id, 'Test Person', null, null, l_contact);
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        emk_party_api.restore_party(l_id);
        select deleted_yn, deleted_by into l_party_del, l_party_by from emk_data.emk_parties where party_id = l_id;
        select deleted_yn into l_contact_del from emk_data.emk_contacts where contact_id = l_contact;
        ut.expect(l_party_del).to_equal('N');
        ut.expect(l_party_by).to_be_null();
        ut.expect(l_contact_del).to_equal('Y');
        emk_party_api.restore_contact(l_contact);
        select deleted_yn into l_contact_del from emk_data.emk_contacts where contact_id = l_contact;
        ut.expect(l_contact_del).to_equal('N');
    end restores_party_then_contact;

    -- Roles ----------------------------------------------------------------------

    procedure adds_role_once is
        l_id    emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL');
        l_count pls_integer;
    begin
        emk_party_api.add_role(l_id, 'CARRIER');
        emk_party_api.add_role(l_id, ' carrier ');
        select count(*) into l_count from emk_data.emk_party_roles where party_id = l_id;
        ut.expect(l_count).to_equal(1);
        ut.expect(emk_party_api.has_role(l_id, 'CARRIER')).to_be_true();
        ut.expect(emk_party_api.has_role(l_id, 'SHIPPER')).to_be_false();
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        ut.expect(emk_party_api.has_role(l_id, 'CARRIER')).to_be_false();
    end adds_role_once;

    procedure rejects_unknown_role is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.add_role(l_id, 'DRIVER');
    end rejects_unknown_role;

    procedure rejects_removal_of_role_in_use is
        l_shipper   emk_data.emk_parties.party_id%type := new_party('Test Shipper', 'DE');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
    begin
        emk_party_api.add_role(l_carrier, 'CARRIER');
        l_shipment := new_shipment(l_shipper, l_carrier, l_consignee);
        update emk_data.emk_shipments
        set    deleted_yn = 'Y', deleted_by = 'TEST', deleted_at = systimestamp
        where  shipment_id = l_shipment;
        emk_party_api.remove_role(l_carrier, 'CARRIER');
    end rejects_removal_of_role_in_use;

    procedure sets_complete_role_list is
        l_id    emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_roles varchar2(200 char);
    begin
        emk_party_api.add_role(l_id, 'SHIPPER');
        emk_party_api.set_roles(l_id, 'CARRIER:consignee:');
        select listagg(role_code, ':') within group (order by role_code)
        into   l_roles
        from   emk_data.emk_party_roles
        where  party_id = l_id;
        ut.expect(l_roles).to_equal('CARRIER:CONSIGNEE');
        emk_party_api.set_roles(l_id, null);
        select listagg(role_code, ':') within group (order by role_code)
        into   l_roles
        from   emk_data.emk_party_roles
        where  party_id = l_id;
        ut.expect(l_roles).to_be_null();
    end sets_complete_role_list;

    -- Contacts -------------------------------------------------------------------

    procedure normalises_contact_phone is
        l_id      emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_contact emk_data.emk_contacts.contact_id%type;
        l_phone   emk_data.emk_contacts.phone%type;
    begin
        emk_party_api.create_contact(l_id, ' Test Person ', null, '+49 30 1234567', l_contact);
        select phone into l_phone from emk_data.emk_contacts where contact_id = l_contact;
        ut.expect(l_phone).to_equal('+49301234567');
    end normalises_contact_phone;

    procedure rejects_restore_of_contact_of_deleted_party is
        l_id      emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_contact emk_data.emk_contacts.contact_id%type;
    begin
        emk_party_api.create_contact(l_id, 'Test Person', null, null, l_contact);
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        emk_party_api.restore_contact(l_contact);
    end rejects_restore_of_contact_of_deleted_party;

end test_emk_party_api;
/
