create or replace package test_emk_views as
    /**
     * Unit tests of the read layer of the application (M1a step 7.4, D-66):
     * the views EMK_V_* hide soft-deleted rows (BR-13), show the roles of a
     * company as one value, deliver row_version so that the APIs accept it
     * back, list deleted records for the restore page, show the change
     * history with the action of each change (D-67), offer the code lists
     * valid today (D-68), and carry their own documentation header (spec §1.3).
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Views for the application (EMK_API))
    --%suitepath(emk_api)

    --%test(Every view EMK_V_* has its header with the copyright line)
    procedure documents_every_view;

    --%test(BR-13: the views hide deleted companies, their contacts and deleted shipments)
    procedure hides_deleted_rows;

    --%test(The roles of a company are one value in alphabetical order, e.g. CARRIER:SENDER)
    procedure shows_roles_as_one_value;

    --%test(row_version read from a view is accepted by the API: no false "changed by another user")
    procedure round_trips_row_version;

    --%test(Deleted records list companies, contacts and shipments; a contact of a deleted company is not restorable)
    procedure lists_deleted_records;

    --%test(The shipment view shows the names of the companies and countries)
    procedure shows_shipment_names;

    --%test(FR-09: the company history shows each change with its action (UPDATED, DELETED, RESTORED), user and previous values)
    procedure shows_party_history;

    --%test(FR-09: the shipment and contact histories show a change with the previous value)
    procedure shows_shipment_and_contact_history;

    --%test(D-68: the code list views offer the values valid today: 2 languages, 6 roles, 7 statuses (4 open), 4 claim types, 6 document types, 28 VAT prefixes, 60 postcode rules)
    procedure offers_valid_code_list_values;
end test_emk_views;
/

create or replace package body test_emk_views as

    -- The example postcode of the country (D-90): it follows the format of the country
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
        in_roles   in varchar2
    ) return emk_data.emk_parties.party_id%type is
        l_id emk_data.emk_parties.party_id%type;
    begin
        emk_party_api.create_party(in_name          => in_name,
                                   in_vat_number    => null,
                                   in_country_code  => in_country,
                                   in_street        => 'Test Street 1',
                                   in_postal_code   => postal_code_of(in_country),   -- the format of the country (D-90)
                                   in_city          => 'Test City',
                                   in_language_code => 'en',
                                   in_role_codes    => in_roles,
                                   out_party_id     => l_id);
        return l_id;
    end new_party;

    function new_shipment (
        in_note      in varchar2,
        in_sender    in emk_data.emk_shipments.sender_id%type,
        in_carrier   in emk_data.emk_shipments.carrier_id%type,
        in_consignee in emk_data.emk_shipments.consignee_id%type
    ) return emk_data.emk_shipments.shipment_id%type is
        l_id emk_data.emk_shipments.shipment_id%type;
    begin
        emk_shipment_api.create_shipment(in_cmr_note_no          => in_note,
                                         in_cmr_note_date        => date '2026-09-01',
                                         in_sender_id            => in_sender,
                                         in_carrier_id           => in_carrier,
                                         in_consignee_id         => in_consignee,
                                         in_taking_over_place    => 'Berlin',
                                         in_origin_country       => 'DE',
                                         in_delivery_place       => 'Paris',
                                         in_destination_country  => 'FR',
                                         in_taking_over_date     => date '2026-09-01',
                                         in_agreed_time_limit => null,
                                         in_delivery_date        => null,
                                         in_disposal_date        => null,
                                         in_goods_description    => 'Test goods',
                                         in_packages             => 1,
                                         in_gross_weight_kg      => 100,
                                         in_carriage_charges     => null,
                                         in_currency_code        => null,
                                         in_declared_value       => null,
                                         in_declared_value_currency => null,
                                         in_special_interest     => null,
                                         in_special_interest_currency => null,
                                         out_shipment_id         => l_id);
        return l_id;
    end new_shipment;

    function party_version (
        in_party_id in emk_data.emk_parties.party_id%type
    ) return emk_data.emk_parties.updated_at%type is
        l_version varchar2(40 char);
    begin
        select row_version into l_version from emk_v_parties where party_id = in_party_id;
        return emk_row_version_pkg.parse_row_version(l_version);
    end party_version;

    function shipment_version (
        in_shipment_id in emk_data.emk_shipments.shipment_id%type
    ) return emk_data.emk_shipments.updated_at%type is
        l_version varchar2(40 char);
    begin
        select row_version into l_version from emk_v_shipments where shipment_id = in_shipment_id;
        return emk_row_version_pkg.parse_row_version(l_version);
    end shipment_version;

    procedure documents_every_view is
        l_views        pls_integer;
        l_undocumented pls_integer;
    begin
        select count(*),
               count(case when text_vc not like '%Copyright (c) 2026 Natalia Müller. All rights reserved.%' then 1 end)
        into   l_views, l_undocumented
        from   user_views
        where  view_name like 'EMK\_V\_%' escape '\';
        ut.expect(l_views).to_equal(20);   -- 7.7: EMK_V_FILE_TYPES, EMK_V_CODE_LIST_HISTORY (D-82); 7.8: EMK_V_VAT_FORMATS (D-88), EMK_V_POSTAL_FORMATS (D-90)
        ut.expect(l_undocumented).to_equal(0);
    end documents_every_view;

    procedure hides_deleted_rows is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE', 'SENDER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_contact   emk_data.emk_contacts.contact_id%type;
        l_shipment  emk_data.emk_shipments.shipment_id%type;
        l_parties   pls_integer;
        l_contacts  pls_integer;
        l_shipments pls_integer;
        l_roles     pls_integer;
    begin
        l_shipment := new_shipment('CMR-TEST-VIEW-1', l_sender, l_carrier, l_consignee);
        emk_shipment_api.delete_shipment(l_shipment, shipment_version(l_shipment));
        emk_party_api.create_contact(l_consignee, 'Test Person', null, null, l_contact);
        emk_party_api.delete_party(l_consignee, party_version(l_consignee));

        select count(*) into l_parties from emk_v_parties where party_id = l_consignee;
        select count(*) into l_contacts from emk_v_contacts where contact_id = l_contact;
        select count(*) into l_shipments from emk_v_shipments where shipment_id = l_shipment;
        select count(*) into l_roles from emk_v_party_roles where party_id = l_consignee;
        ut.expect(l_parties).to_equal(0);
        ut.expect(l_contacts).to_equal(0);
        ut.expect(l_shipments).to_equal(0);
        ut.expect(l_roles).to_equal(0);
    end hides_deleted_rows;

    procedure shows_roles_as_one_value is
        l_id    emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', 'SENDER:CARRIER');
        l_roles emk_v_parties.roles%type;
    begin
        select roles into l_roles from emk_v_parties where party_id = l_id;
        ut.expect(l_roles).to_equal('CARRIER:SENDER');
    end shows_roles_as_one_value;

    procedure round_trips_row_version is
        l_id   emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', 'FORWARDER');
        l_name emk_data.emk_parties.name%type;
    begin
        -- Twice: after the update the version comes from updated_at, before from created_at
        emk_party_api.update_party(l_id, party_version(l_id), 'Test Company 2', null, 'DE', 'Test Street 1', '10115', 'Test City', 'en');
        emk_party_api.update_party(l_id, party_version(l_id), 'Test Company 3', null, 'DE', 'Test Street 1', '10115', 'Test City', 'en');
        select name into l_name from emk_v_parties where party_id = l_id;
        ut.expect(l_name).to_equal('Test Company 3');
    end round_trips_row_version;

    procedure lists_deleted_records is
        l_party       emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', 'FORWARDER');
        l_contact     emk_data.emk_contacts.contact_id%type;
        l_entity      emk_v_deleted_records.entity%type;
        l_restorable  emk_v_deleted_records.restorable_yn%type;
    begin
        emk_party_api.create_contact(l_party, 'Test Person', null, null, l_contact);
        emk_party_api.delete_party(l_party, party_version(l_party));

        select entity into l_entity from emk_v_deleted_records where entity = 'PARTY' and record_id = l_party;
        ut.expect(l_entity).to_equal('PARTY');
        select restorable_yn into l_restorable from emk_v_deleted_records where entity = 'CONTACT' and record_id = l_contact;
        ut.expect(l_restorable).to_equal('N');

        emk_party_api.restore_party(l_party);
        select restorable_yn into l_restorable from emk_v_deleted_records where entity = 'CONTACT' and record_id = l_contact;
        ut.expect(l_restorable).to_equal('Y');
    end lists_deleted_records;

    procedure shows_shipment_names is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE', 'SENDER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
        l_row       emk_v_shipments%rowtype;
    begin
        l_shipment := new_shipment('CMR-TEST-VIEW-2', l_sender, l_carrier, l_consignee);
        select * into l_row from emk_v_shipments where shipment_id = l_shipment;
        ut.expect(l_row.carrier_name).to_equal('Test Carrier');
        ut.expect(l_row.origin_country_name).to_equal('Germany');
        ut.expect(l_row.destination_country_name).to_equal('France');
    end shows_shipment_names;

    procedure shows_party_history is
        l_id      emk_data.emk_parties.party_id%type := new_party('Test Company', 'DE', 'FORWARDER');
        l_actions varchar2(200 char);
        l_first   emk_v_party_history.previous_name%type;
        l_by      emk_v_party_history.changed_by%type;
    begin
        emk_party_api.update_party(l_id, party_version(l_id), 'Test Company Renamed', null, 'DE', 'Test Street 1', '10115', 'Test City', 'en');
        emk_party_api.delete_party(l_id, party_version(l_id));
        emk_party_api.restore_party(l_id);

        select listagg(action, ':') within group (order by changed_at, history_id)
        into   l_actions
        from   emk_v_party_history
        where  party_id = l_id;
        ut.expect(l_actions).to_equal('UPDATED:DELETED:RESTORED');

        select previous_name, changed_by
        into   l_first, l_by
        from   emk_v_party_history
        where  party_id = l_id
        and    action = 'UPDATED';
        ut.expect(l_first).to_equal('Test Company');
        ut.expect(l_by).to_be_not_null();
    end shows_party_history;

    procedure shows_shipment_and_contact_history is
        l_sender    emk_data.emk_parties.party_id%type := new_party('Test Sender', 'DE', 'SENDER');
        l_carrier   emk_data.emk_parties.party_id%type := new_party('Test Carrier', 'PL', 'CARRIER');
        l_consignee emk_data.emk_parties.party_id%type := new_party('Test Consignee', 'FR', 'CONSIGNEE');
        l_shipment  emk_data.emk_shipments.shipment_id%type;
        l_contact   emk_data.emk_contacts.contact_id%type;
        l_goods     emk_v_shipment_history.previous_goods_description%type;
        l_email     emk_v_contact_history.previous_email%type;
        l_action    emk_v_contact_history.action%type;
        l_version   varchar2(40 char);
    begin
        l_shipment := new_shipment('CMR-TEST-VIEW-3', l_sender, l_carrier, l_consignee);
        emk_shipment_api.update_shipment(in_shipment_id          => l_shipment,
                                         in_expected_updated_at  => shipment_version(l_shipment),
                                         in_cmr_note_no          => 'CMR-TEST-VIEW-3',
                                         in_cmr_note_date        => date '2026-09-01',
                                         in_sender_id            => l_sender,
                                         in_carrier_id           => l_carrier,
                                         in_consignee_id         => l_consignee,
                                         in_taking_over_place    => 'Berlin',
                                         in_origin_country       => 'DE',
                                         in_delivery_place       => 'Paris',
                                         in_destination_country  => 'FR',
                                         in_taking_over_date     => date '2026-09-01',
                                         in_agreed_time_limit => null,
                                         in_delivery_date        => null,
                                         in_disposal_date        => null,
                                         in_goods_description    => 'Changed goods',
                                         in_packages             => 1,
                                         in_gross_weight_kg      => 100,
                                         in_carriage_charges     => null,
                                         in_currency_code        => null,
                                         in_declared_value       => null,
                                         in_declared_value_currency => null,
                                         in_special_interest     => null,
                                         in_special_interest_currency => null);
        select previous_goods_description into l_goods from emk_v_shipment_history where shipment_id = l_shipment;
        ut.expect(l_goods).to_equal('Test goods');

        emk_party_api.create_contact(l_consignee, 'Test Person', 'old@example.com', null, l_contact);
        select row_version into l_version from emk_v_contacts where contact_id = l_contact;
        emk_party_api.update_contact(l_contact, emk_row_version_pkg.parse_row_version(l_version), 'Test Person', 'new@example.com', null);
        select previous_email, action into l_email, l_action from emk_v_contact_history where contact_id = l_contact;
        ut.expect(l_email).to_equal('old@example.com');
        ut.expect(l_action).to_equal('UPDATED');
    end shows_shipment_and_contact_history;

    procedure offers_valid_code_list_values is
        l_count pls_integer;
    begin
        select count(*) into l_count from emk_v_languages where valid_yn = 'Y';
        ut.expect(l_count, 'languages').to_equal(2);
        select count(*) into l_count from emk_v_party_role_types where valid_yn = 'Y';
        ut.expect(l_count, 'roles').to_equal(6);
        select count(*) into l_count from emk_v_claim_statuses where valid_yn = 'Y';
        ut.expect(l_count, 'claim statuses').to_equal(7);
        select count(*) into l_count from emk_v_claim_statuses where valid_yn = 'Y' and final_yn = 'N';
        ut.expect(l_count, 'open claim statuses').to_equal(4);
        select count(*) into l_count from emk_v_claim_types where valid_yn = 'Y';
        ut.expect(l_count, 'claim types').to_equal(4);
        select count(*) into l_count from emk_v_document_types where valid_yn = 'Y';
        ut.expect(l_count, 'document types').to_equal(6);
        select count(*) into l_count from emk_v_vat_formats where valid_yn = 'Y';
        ut.expect(l_count, 'VAT prefixes (D-88)').to_equal(28);
        select count(*) into l_count from emk_v_postal_formats where valid_yn = 'Y';
        ut.expect(l_count, 'postcode rules (D-90)').to_equal(60);
    end offers_valid_code_list_values;

end test_emk_views;
/
