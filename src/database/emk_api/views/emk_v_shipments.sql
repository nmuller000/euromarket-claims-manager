create or replace force editionable view emk_api.emk_v_shipments (
    shipment_id,
    cmr_note_no,
    shipper_id,
    shipper_name,
    carrier_id,
    carrier_name,
    consignee_id,
    consignee_name,
    pickup_place,
    origin_country,
    origin_country_name,
    delivery_place,
    destination_country,
    destination_country_name,
    pickup_date,
    agreed_delivery_date,
    delivery_date,
    goods_description,
    packages,
    gross_weight_kg,
    carriage_charges,
    currency_code,
    created_at,
    created_by,
    updated_at,
    updated_by,
    row_version
) as
    select
    /**
     * Active shipments for the APEX pages: every column of the shipment, the
     * names of the shipper, carrier and consignee and of both countries, and
     * row_version for optimistic locking. Changes go through EMK_SHIPMENT_API.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        s.shipment_id,
        s.cmr_note_no,
        s.shipper_id,
        sh.name as shipper_name,
        s.carrier_id,
        ca.name as carrier_name,
        s.consignee_id,
        co.name as consignee_name,
        s.pickup_place,
        s.origin_country,
        o.name  as origin_country_name,
        s.delivery_place,
        s.destination_country,
        d.name  as destination_country_name,
        s.pickup_date,
        s.agreed_delivery_date,
        s.delivery_date,
        s.goods_description,
        s.packages,
        s.gross_weight_kg,
        s.carriage_charges,
        s.currency_code,
        s.created_at,
        s.created_by,
        s.updated_at,
        s.updated_by,
        to_char(
            nvl(s.updated_at, s.created_at),
            'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM'
        )       as row_version
    from
             emk_data.emk_shipments s
        join emk_data.emk_parties   sh on sh.party_id = s.shipper_id
        join emk_data.emk_parties   ca on ca.party_id = s.carrier_id
        join emk_data.emk_parties   co on co.party_id = s.consignee_id
        join emk_data.emk_countries o on o.country_code = s.origin_country
        join emk_data.emk_countries d on d.country_code = s.destination_country
    where
        s.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"a57700144941b3a624e36549d84ff5a5b01be099","type":"VIEW","name":"EMK_V_SHIPMENTS","schemaName":"EMK_API","sxml":""}