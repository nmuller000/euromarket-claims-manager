create or replace package test_emk_party_api as
    /**
     * Unit tests of EMK_PARTY_API (M1a step 7.2, api-design.md §3): companies,
     * their roles (BR-16, T-M1-29) and contact persons; normalised values,
     * VAT rules, optimistic locking (D-43), soft delete and restore (BR-13,
     * D-39, T-M1-08), code lists (D-68: a new language or role must be valid
     * today), language and at least one role required (D-71), postal address
     * and postcode by country (D-89, D-90). Shipments that
     * use a company are inserted directly with
     * the grants of EMK_API; utPLSQL rolls everything back.
     * VAT numbers of the tests use the series 999 999 9xx, which no example
     * and no page test uses: the tests run in DEV next to its data, where a
     * company created and deleted on a page keeps its VAT number (D-39).
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

    --%test(D-68: a language outside the language list is rejected)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rejects_unknown_language;

    --%test(D-68: a language given in upper case is stored in lower case)
    procedure normalises_language_code;

    --%test(D-71: a company without a language is rejected)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_missing_language;

    --%test(D-71: a company is created with its roles in one call)
    procedure creates_party_with_roles;

    --%test(D-71: a company without any role is rejected)
    --%throws(emk_errors_pkg.c_party_role_required)
    procedure rejects_party_without_roles;

    --%test(A VAT number used by another company is rejected)
    --%throws(emk_errors_pkg.c_duplicate_vat)
    procedure rejects_duplicate_vat;

    --%test(D-39: a VAT number of a deleted company asks to restore that company)
    procedure asks_to_restore_owner_of_vat;

    --%test(D-88: the national part gets the VAT prefix of the country; spaces, dots and hyphens are removed)
    procedure adds_vat_prefix_of_country;

    --%test(D-88: a number typed with the prefix of the country is kept, also a French one whose national part starts with two letters)
    procedure keeps_vat_typed_with_prefix;

    --%test(D-88: a company in GB gets the prefix XI, a company in GR the prefix EL)
    procedure adds_xi_and_el_prefixes;

    --%test(D-88: a VAT number outside the format of the country is rejected, with an example of that format)
    procedure rejects_vat_outside_country_format;

    --%test(D-88: a Dutch number may contain + and * (BZSt))
    procedure accepts_dutch_vat_with_signs;

    --%test(D-88: an update with the national part of the stored number keeps it and writes nothing)
    procedure keeps_stored_vat_given_without_prefix;

    --%test(D-89: a company needs a street and a city (CMR Art. 6(1): name and address))
    --%throws(emk_errors_pkg.c_party_address_required)
    procedure rejects_party_without_street_or_city;

    --%test(D-89: a postcode is required where the country uses one)
    --%throws(emk_errors_pkg.c_party_address_required)
    procedure rejects_missing_postal_code;

    --%test(D-89: a company in a country without postcodes (Syria, UPU) needs none)
    procedure accepts_country_without_postal_codes;

    --%test(D-89: a company moved to a country with postcodes needs its postcode)
    --%throws(emk_errors_pkg.c_party_address_required)
    procedure asks_postal_code_when_country_changes;

    --%test(D-90: a postcode is stored upper case, trimmed, with one space between its parts)
    procedure normalises_postal_code;

    --%test(D-90: the prefix of the official form is added when only the digits are typed (Latvia LV-1050))
    procedure adds_postal_code_prefix;

    --%test(D-90: a postcode outside the format of the country is rejected, with an example of that format)
    procedure rejects_postal_code_outside_country_format;

    --%test(D-90: the inner space of a postcode may be left out (United Kingdom SW1A1AA))
    procedure accepts_postal_code_without_inner_space;

    --%test(D-90: a country without a postcode format accepts a postcode of the general form)
    procedure accepts_postal_code_without_country_format;

    --%test(Step 7.8: a VAT number too long gives the friendly format error, not ORA-06502 (log 341))
    --%throws(emk_errors_pkg.c_vat_country_mismatch)
    procedure rejects_long_vat_with_format_error;

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

    --%test(D-68: a role outside the role list is rejected)
    --%throws(emk_errors_pkg.c_reference_not_valid)
    procedure rejects_unknown_role;

    --%test(A role is required)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_missing_role;

    --%test(T-M1-29: a role used by a shipment, also a deleted one, cannot be removed)
    --%throws(emk_errors_pkg.c_party_role_in_use)
    procedure rejects_removal_of_role_in_use;

    --%test(set_roles adds the missing roles and removes the others)
    procedure sets_complete_role_list;

    --%test(D-71: set_roles with an empty list is rejected)
    --%throws(emk_errors_pkg.c_party_role_required)
    procedure rejects_empty_role_list;

    --%test(D-71: the last role of a company cannot be removed)
    --%throws(emk_errors_pkg.c_party_role_required)
    procedure rejects_removal_of_last_role;

    --%test(Step 7.8: the page knows before saving which roles are in use and whether the company can be deleted)
    procedure shows_rules_before_saving;

    --%test(D-86: set_roles never removes a retired role silently; the views show it apart, with its last valid day)
    procedure keeps_retired_role_on_set_roles;

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

    -- The example postcode of the country (D-90): it follows the format of the country; NULL without postcodes
    function postal_code_of (
        in_country in varchar2
    ) return varchar2 is
        l_example emk_data.emk_postal_formats.postal_code_example%type;
    begin
        select max(postal_code_example) into l_example from emk_data.emk_postal_formats where country_code = upper(in_country);
        return l_example;
    end postal_code_of;

    function new_party (
        in_name    in varchar2,
        in_country in varchar2,
        in_vat     in varchar2 default null,
        in_roles   in varchar2 default 'FORWARDER'   -- a role that no rule of BR-16 uses
    ) return emk_data.emk_parties.party_id%type is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => in_name,
                                   in_vat_number    => in_vat,
                                   in_country_code  => in_country,
                                   in_street        => 'Test Street 1',
                                   in_postal_code   => postal_code_of(in_country),
                                   in_city          => 'Test City',
                                   in_language_code => 'en',
                                   in_role_codes    => in_roles,
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
        in_sender    in emk_data.emk_shipments.sender_id%type,
        in_carrier   in emk_data.emk_shipments.carrier_id%type,
        in_consignee in emk_data.emk_shipments.consignee_id%type
    ) return emk_data.emk_shipments.shipment_id%type is
        l_id emk_data.emk_shipments.shipment_id%type;
    begin
        insert into emk_data.emk_shipments (cmr_note_no, sender_id, carrier_id, consignee_id, taking_over_place,
                                            origin_country, delivery_place, destination_country, taking_over_date,
                                            goods_description, gross_weight_kg, cmr_note_date)
        values ('CMR-TEST-PARTY-' || in_carrier, in_sender, in_carrier, in_consignee, 'Berlin', 'DE', 'Paris', 'FR',
                date '2026-09-01', 'Goods', 10, date '2026-09-01')
        returning shipment_id into l_id;
        return l_id;
    end new_shipment;

    -- Companies ------------------------------------------------------------------

    procedure creates_party_with_normalised_values is
        l_id    emk_data.emk_parties.party_id%type;
        l_party emk_data.emk_parties%rowtype;
    begin
        emk_party_api.create_party(in_name          => '  Test Spedition GmbH  ',
                                   in_vat_number    => ' de 999 999 904 ',
                                   in_country_code  => 'de',
                                   in_street        => ' Hauptstrasse 1 ',
                                   in_postal_code   => '10115',
                                   in_city          => ' Berlin ',
                                   in_language_code => 'en',
                                   in_role_codes    => 'SENDER',
                                   out_party_id     => l_id);
        select * into l_party from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_party.name).to_equal('Test Spedition GmbH');
        ut.expect(l_party.vat_number).to_equal('DE999999904');
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
        l_id := new_party('Test Belfast Ltd', 'GB', 'XI999999908');
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_vat).to_equal('XI999999908');
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

    procedure rejects_unknown_language is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => 'Test SARL',
                                   in_vat_number    => null,
                                   in_country_code  => 'FR',
                                   in_street        => 'Test Street 1',
                                   in_postal_code   => '75001',
                                   in_city          => 'Test City',
                                   in_language_code => 'fr',
                                   in_role_codes    => 'SENDER',
                                   out_party_id     => l_id);
    end rejects_unknown_language;

    procedure normalises_language_code is
        l_id       emk_data.emk_parties.party_id%type;
        l_language emk_data.emk_parties.language_code%type;
    begin
        emk_party_api.create_party(in_name          => 'Test GmbH',
                                   in_vat_number    => null,
                                   in_country_code  => 'AT',
                                   in_street        => 'Test Street 1',
                                   in_postal_code   => '1010',
                                   in_city          => 'Test City',
                                   in_language_code => ' DE ',
                                   in_role_codes    => 'SENDER',
                                   out_party_id     => l_id);
        select language_code into l_language from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_language).to_equal('de');
    end normalises_language_code;

    procedure rejects_missing_language is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => 'Test GmbH',
                                   in_vat_number    => null,
                                   in_country_code  => 'DE',
                                   in_street        => 'Test Street 1',
                                   in_postal_code   => '10115',
                                   in_city          => 'Test City',
                                   in_language_code => '  ',
                                   in_role_codes    => 'SENDER',
                                   out_party_id     => l_id);
    end rejects_missing_language;

    procedure creates_party_with_roles is
        l_id    emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', null, 'consignee:SENDER');
        l_roles varchar2(200 char);
    begin
        select listagg(role_code, ':') within group (order by role_code)
        into   l_roles
        from   emk_data.emk_party_roles
        where  party_id = l_id;
        ut.expect(l_roles).to_equal('CONSIGNEE:SENDER');
    end creates_party_with_roles;

    procedure rejects_party_without_roles is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test Company', 'DE', null, null);
    end rejects_party_without_roles;

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

    procedure adds_vat_prefix_of_country is
        l_id       emk_data.emk_parties.party_id%type := new_party('Test GmbH', 'DE', ' 999.999-905 ');
        l_vat      emk_data.emk_parties.vat_number%type;
        l_national varchar2(20 char);
    begin
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_id;
        select vat_national_number into l_national from emk_v_parties where party_id = l_id;
        ut.expect(l_vat).to_equal('DE999999905');
        ut.expect(l_national, 'the form shows the national part').to_equal('999999905');
    end adds_vat_prefix_of_country;

    procedure keeps_vat_typed_with_prefix is
        l_typed    emk_data.emk_parties.party_id%type := new_party('Test SARL One', 'FR', 'fr ab 999 999 901');
        l_national emk_data.emk_parties.party_id%type := new_party('Test SARL Two', 'FR', 'CD999999901');
        l_vat      emk_data.emk_parties.vat_number%type;
    begin
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_typed;
        ut.expect(l_vat, 'typed with the prefix').to_equal('FRAB999999901');
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_national;
        ut.expect(l_vat, 'national part starting with two letters').to_equal('FRCD999999901');
    end keeps_vat_typed_with_prefix;

    procedure adds_xi_and_el_prefixes is
        l_gb  emk_data.emk_parties.party_id%type := new_party('Test Belfast Ltd', 'GB', '999999906');
        l_gr  emk_data.emk_parties.party_id%type := new_party('Test AE', 'GR', '999999907');
        l_vat emk_data.emk_parties.vat_number%type;
    begin
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_gb;
        ut.expect(l_vat, 'GB').to_equal('XI999999906');
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_gr;
        ut.expect(l_vat, 'GR').to_equal('EL999999907');
    end adds_xi_and_el_prefixes;

    procedure rejects_vat_outside_country_format is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test GmbH', 'AT', '999999909');   -- a German format; Austria is U and 8 digits
        ut.fail('A VAT number outside the format of the country was accepted');
    exception
        when emk_errors_pkg.e_vat_country_mismatch then
            ut.expect(sqlerrm).to_be_like('%ATU12345678%');
    end rejects_vat_outside_country_format;

    procedure accepts_dutch_vat_with_signs is
        l_id  emk_data.emk_parties.party_id%type := new_party('Test BV', 'NL', '9999999+*B01');
        l_vat emk_data.emk_parties.vat_number%type;
    begin
        select vat_number into l_vat from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_vat).to_equal('NL9999999+*B01');
    end accepts_dutch_vat_with_signs;

    procedure keeps_stored_vat_given_without_prefix is
        l_id         emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', 'DE999999903');
        l_vat        emk_data.emk_parties.vat_number%type;
        l_updated_at emk_data.emk_parties.updated_at%type;
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id),
                                   in_name                => 'Test Company',
                                   in_vat_number          => '999 999 903',
                                   in_country_code        => 'DE',
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => '10115',
                                   in_city                => 'Test City',
                                   in_language_code       => 'en');
        select vat_number, updated_at into l_vat, l_updated_at from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_vat).to_equal('DE999999903');
        ut.expect(l_updated_at, 'nothing written').to_be_null();
    end keeps_stored_vat_given_without_prefix;

    procedure rejects_update_with_old_version is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id) - interval '1' second,
                                   in_name                => 'Test Company New',
                                   in_vat_number          => null,
                                   in_country_code        => 'DE',
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => '10115',
                                   in_city                => 'Test City',
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
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => '10115',
                                   in_city                => 'Test City',
                                   in_language_code       => ' EN ');
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
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => '10115',
                                   in_city                => 'Test City',
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
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => '10115',
                                   in_city                => 'Test City',
                                   in_language_code       => 'en');
    end rejects_update_of_deleted_party;

    procedure rejects_delete_of_party_in_use is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
    begin
        l_shipment := new_shipment(l_sender, l_carrier, l_consignee);
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
        select count(*) into l_count from emk_data.emk_party_roles where party_id = l_id and role_code = 'CARRIER';
        ut.expect(l_count).to_equal(1);
        ut.expect(emk_party_api.has_role(l_id, 'CARRIER')).to_be_true();
        ut.expect(emk_party_api.has_role(l_id, 'SENDER')).to_be_false();
        emk_party_api.delete_party(l_id, version_of_party(l_id));
        ut.expect(emk_party_api.has_role(l_id, 'CARRIER')).to_be_false();
    end adds_role_once;

    procedure rejects_unknown_role is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.add_role(l_id, 'DRIVER');
    end rejects_unknown_role;

    procedure rejects_missing_role is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.add_role(l_id, '  ');
    end rejects_missing_role;

    procedure rejects_removal_of_role_in_use is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
    begin
        emk_party_api.add_role(l_carrier, 'CARRIER');
        l_shipment := new_shipment(l_sender, l_carrier, l_consignee);
        update emk_data.emk_shipments
        set    deleted_yn = 'Y', deleted_by = 'TEST', deleted_at = systimestamp
        where  shipment_id = l_shipment;
        emk_party_api.remove_role(l_carrier, 'CARRIER');
    end rejects_removal_of_role_in_use;

    procedure sets_complete_role_list is
        l_id    emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
        l_roles varchar2(200 char);
    begin
        emk_party_api.add_role(l_id, 'SENDER');
        emk_party_api.set_roles(l_id, 'CARRIER:consignee:');
        select listagg(role_code, ':') within group (order by role_code)
        into   l_roles
        from   emk_data.emk_party_roles
        where  party_id = l_id;
        ut.expect(l_roles).to_equal('CARRIER:CONSIGNEE');
    end sets_complete_role_list;

    procedure rejects_empty_role_list is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');
    begin
        emk_party_api.set_roles(l_id, ' : ');
    end rejects_empty_role_list;

    procedure rejects_removal_of_last_role is
        l_id emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE');   -- only FORWARDER
    begin
        emk_party_api.remove_role(l_id, 'FORWARDER');
    end rejects_removal_of_last_role;

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

    procedure shows_rules_before_saving is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE', in_roles => 'SENDER:FORWARDER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', in_roles => 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', in_roles => 'CONSIGNEE');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
        l_view_roles varchar2(100 char);
    begin
        ut.expect(emk_party_api.get_roles_in_use(l_sender), 'no shipment yet').to_be_null();
        ut.expect(emk_party_api.is_deletable(l_sender), 'deletable without shipments').to_be_true();
        l_shipment := new_shipment(l_sender, l_carrier, l_consignee);
        ut.expect(emk_party_api.get_roles_in_use(l_sender), 'sender in use, forwarder not').to_equal('SENDER');
        ut.expect(emk_party_api.get_roles_in_use(l_carrier), 'carrier in use').to_equal('CARRIER');
        ut.expect(emk_party_api.is_deletable(l_sender), 'not deletable with an active shipment').to_be_false();
        update emk_data.emk_shipments
        set    deleted_yn = 'Y', deleted_by = 'TEST', deleted_at = systimestamp
        where  shipment_id = l_shipment;
        ut.expect(emk_party_api.is_deletable(l_sender), 'deletable when the shipment is deleted').to_be_true();
        ut.expect(emk_party_api.get_roles_in_use(l_sender), 'a deleted shipment still uses the role').to_equal('SENDER');
        select roles_in_use into l_view_roles from emk_v_parties where party_id = l_sender;
        ut.expect(l_view_roles, 'the view shows the same').to_equal('SENDER');
    end shows_rules_before_saving;

    procedure keeps_retired_role_on_set_roles is
        l_party    emk_data.emk_parties.party_id%type := new_party('Test Retired Role', 'DE', in_roles => 'FORWARDER:SURVEYOR');
        l_roles    varchar2(100 char);
        l_valid_yn varchar2(1 char);
        l_valid_to date;
        l_language varchar2(1 char);
    begin
        update emk_data.emk_party_role_types set valid_to = trunc(sysdate) - 1 where role_code = 'SURVEYOR';
        -- The checkboxes offer valid roles only: the page sends CARRIER without SURVEYOR
        emk_party_api.set_roles(in_party_id => l_party, in_role_codes => 'CARRIER');
        select listagg(role_code, ':') within group (order by role_code)
        into   l_roles
        from   emk_data.emk_party_roles
        where  party_id = l_party;
        ut.expect(l_roles, 'FORWARDER removed, CARRIER added, the retired SURVEYOR kept').to_equal('CARRIER:SURVEYOR');
        select valid_yn, valid_to into l_valid_yn, l_valid_to
        from   emk_v_party_roles
        where  party_id = l_party and role_code = 'SURVEYOR';
        ut.expect(l_valid_yn, 'the view marks the retired role').to_equal('N');
        ut.expect(l_valid_to, 'with its last valid day').to_equal(trunc(sysdate) - 1);
        select language_valid_yn into l_language from emk_v_parties where party_id = l_party;
        ut.expect(l_language, 'the language en is valid').to_equal('Y');
    end keeps_retired_role_on_set_roles;

    -- A company with the address given, roles FORWARDER (D-89 tests)
    function new_party_at (
        in_name        in varchar2,
        in_country     in varchar2,
        in_street      in varchar2,
        in_postal_code in varchar2,
        in_city        in varchar2
    ) return emk_data.emk_parties.party_id%type is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => in_name,
                                   in_vat_number    => null,
                                   in_country_code  => in_country,
                                   in_street        => in_street,
                                   in_postal_code   => in_postal_code,
                                   in_city          => in_city,
                                   in_language_code => 'en',
                                   in_role_codes    => 'FORWARDER',
                                   out_party_id     => l_id);
        return l_id;
    end new_party_at;

    procedure rejects_party_without_street_or_city is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party_at('Test GmbH', 'DE', '   ', '10115', 'Berlin');   -- blanks only: trimmed to nothing
    end rejects_party_without_street_or_city;

    procedure rejects_missing_postal_code is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party_at('Test GmbH', 'DE', 'Hauptstrasse 1', null, 'Berlin');
    end rejects_missing_postal_code;

    procedure accepts_country_without_postal_codes is
        l_id          emk_data.emk_parties.party_id%type := new_party_at('Test Damascus Trading', 'SY', 'Test Street 1', null, 'Damascus');
        l_postal_code emk_data.emk_parties.postal_code%type;
    begin
        select postal_code into l_postal_code from emk_data.emk_parties where party_id = l_id;
        ut.expect(l_postal_code).to_be_null();
    end accepts_country_without_postal_codes;

    procedure asks_postal_code_when_country_changes is
        l_id emk_data.emk_parties.party_id%type := new_party_at('Test Damascus Trading', 'SY', 'Test Street 1', null, 'Damascus');
    begin
        emk_party_api.update_party(in_party_id            => l_id,
                                   in_expected_updated_at => version_of_party(l_id),
                                   in_name                => 'Test Damascus Trading',
                                   in_vat_number          => null,
                                   in_country_code        => 'DE',
                                   in_street              => 'Test Street 1',
                                   in_postal_code         => null,
                                   in_city                => 'Berlin',
                                   in_language_code       => 'en');
    end asks_postal_code_when_country_changes;

    -- The stored postcode of a company
    function postal_code_stored (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return varchar2 is
        l_postal_code emk_data.emk_parties.postal_code%type;
    begin
        select postal_code into l_postal_code from emk_data.emk_parties where party_id = in_party_id;
        return l_postal_code;
    end postal_code_stored;

    procedure normalises_postal_code is
        l_id emk_data.emk_parties.party_id%type := new_party_at('Test BV', 'NL', 'Test Street 1', ' 1012   ab ', 'Amsterdam');
    begin
        ut.expect(postal_code_stored(l_id)).to_equal('1012 AB');
    end normalises_postal_code;

    procedure adds_postal_code_prefix is
        l_digits emk_data.emk_parties.party_id%type := new_party_at('Test SIA One', 'LV', 'Test Street 1', '1050', 'Riga');
        l_typed  emk_data.emk_parties.party_id%type := new_party_at('Test SIA Two', 'LV', 'Test Street 2', 'lv-1050', 'Riga');
    begin
        ut.expect(postal_code_stored(l_digits), 'digits only').to_equal('LV-1050');
        ut.expect(postal_code_stored(l_typed), 'typed with the prefix').to_equal('LV-1050');
    end adds_postal_code_prefix;

    procedure rejects_postal_code_outside_country_format is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party_at('Test GmbH', 'DE', 'Test Street 1', '1234', 'Berlin');   -- Germany: 5 digits
        ut.fail('A postcode outside the format of the country was accepted');
    exception
        when emk_errors_pkg.e_postal_code_format then
            ut.expect(sqlerrm).to_be_like('%10115%');
    end rejects_postal_code_outside_country_format;

    procedure accepts_postal_code_without_inner_space is
        l_id emk_data.emk_parties.party_id%type := new_party_at('Test Ltd', 'GB', 'Test Street 1', 'sw1a1aa', 'London');
    begin
        ut.expect(postal_code_stored(l_id)).to_equal('SW1A1AA');
    end accepts_postal_code_without_inner_space;

    procedure accepts_postal_code_without_country_format is
        l_id emk_data.emk_parties.party_id%type := new_party_at('Test Damascus Trading', 'SY', 'Test Street 1', 'abc 12', 'Damascus');
    begin
        ut.expect(postal_code_stored(l_id)).to_equal('ABC 12');
    end accepts_postal_code_without_country_format;

    procedure rejects_long_vat_with_format_error is
        l_id emk_data.emk_parties.party_id%type;
    begin
        l_id := new_party('Test Long VAT', 'DE', 'DE777777777777777777');   -- 20 characters with the right prefix
    end rejects_long_vat_with_format_error;

end test_emk_party_api;
/
