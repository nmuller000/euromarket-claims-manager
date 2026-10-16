create or replace package test_emk_shipments as
    /**
     * Unit tests of EMK_SHIPMENTS in EMK_DATA (M1a step 4): BR-03 (a carrier
     * never reuses a CMR note number, also after a soft delete; another carrier
     * may use the same number) and D-40 (normalised note number, different
     * origin and destination countries).
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Shipments (EMK_DATA))
    --%suitepath(emk_data)

    --%beforeeach
    procedure create_test_shipment;

    --%test(BR-03: the same carrier cannot reuse a CMR note number)
    --%throws(-1)
    procedure rejects_reused_note_number;

    --%test(BR-03: another carrier may use the same CMR note number)
    procedure accepts_note_number_of_other_carrier;

    --%test(BR-03: the note number stays taken after a soft delete)
    --%throws(-1)
    procedure rejects_note_number_after_soft_delete;

    --%test(D-40: the note number must be upper case without spaces)
    --%throws(-2290)
    procedure rejects_lower_case_note_number;

    --%test(Origin and destination must be different countries)
    --%throws(-2290)
    procedure rejects_same_origin_and_destination;
end test_emk_shipments;
/

create or replace package body test_emk_shipments as

    c_note_number constant emk_shipments.cmr_note_no%type := 'CMR-TEST-0001';

    g_shipper   emk_parties.party_id%type;
    g_carrier   emk_parties.party_id%type;
    g_carrier2  emk_parties.party_id%type;
    g_consignee emk_parties.party_id%type;
    g_shipment  emk_shipments.shipment_id%type;

    procedure insert_shipment (
        in_note_number in varchar2,
        in_carrier     in number,
        in_origin      in varchar2 default 'DE',
        in_destination in varchar2 default 'FR'
    ) is
    begin
        insert into emk_shipments (cmr_note_no, shipper_id, carrier_id, consignee_id, pickup_place, origin_country,
                                   delivery_place, destination_country, pickup_date, goods_description, gross_weight_kg)
        values (in_note_number, g_shipper, in_carrier, g_consignee, 'Berlin', in_origin,
                'Paris', in_destination, date '2026-09-10', 'Goods', 10)
        returning shipment_id into g_shipment;
    end insert_shipment;

    procedure create_test_shipment is
    begin
        insert into emk_parties (name, country_code) values ('Test Shipper', 'DE') returning party_id into g_shipper;
        insert into emk_parties (name, country_code) values ('Test Carrier', 'PL') returning party_id into g_carrier;
        insert into emk_parties (name, country_code) values ('Test Carrier 2', 'CZ') returning party_id into g_carrier2;
        insert into emk_parties (name, country_code) values ('Test Consignee', 'FR') returning party_id into g_consignee;
        insert_shipment(c_note_number, g_carrier);
    end create_test_shipment;

    procedure rejects_reused_note_number is
    begin
        insert_shipment(c_note_number, g_carrier);
    end rejects_reused_note_number;

    procedure accepts_note_number_of_other_carrier is
        l_count pls_integer;
    begin
        insert_shipment(c_note_number, g_carrier2);
        select count(*) into l_count from emk_shipments where cmr_note_no = c_note_number;
        ut.expect(l_count).to_equal(2);
    end accepts_note_number_of_other_carrier;

    procedure rejects_note_number_after_soft_delete is
    begin
        update emk_shipments
        set    deleted_yn = 'Y', deleted_by = 'TEST', deleted_at = systimestamp
        where  carrier_id = g_carrier and cmr_note_no = c_note_number;
        insert_shipment(c_note_number, g_carrier);
    end rejects_note_number_after_soft_delete;

    procedure rejects_lower_case_note_number is
    begin
        insert_shipment('cmr-test-0002', g_carrier);
    end rejects_lower_case_note_number;

    procedure rejects_same_origin_and_destination is
    begin
        insert_shipment('CMR-TEST-0003', g_carrier, in_origin => 'DE', in_destination => 'DE');
    end rejects_same_origin_and_destination;

end test_emk_shipments;
/
