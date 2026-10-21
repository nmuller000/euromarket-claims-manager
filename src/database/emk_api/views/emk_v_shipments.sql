create or replace force editionable view emk_api.emk_v_shipments (
    shipment_id,
    cmr_note_no,
    cmr_note_date,
    sender_id,
    sender_name,
    carrier_id,
    carrier_name,
    consignee_id,
    consignee_name,
    taking_over_place,
    origin_country,
    origin_country_name,
    delivery_place,
    destination_country,
    destination_country_name,
    taking_over_date,
    agreed_time_limit,
    delivery_date,
    disposal_date,
    goods_description,
    packages,
    gross_weight_kg,
    carriage_charges,
    currency_code,
    declared_value,
    declared_value_currency,
    special_interest,
    special_interest_currency,
    created_at,
    created_by,
    updated_at,
    updated_by,
    row_version
) as
    select
    /**
     * Active shipments for the APEX pages: every column of the shipment, the
     * names of the sender, carrier and consignee and of both countries, and
     * row_version for optimistic locking. Changes go through EMK_SHIPMENT_API.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        s.shipment_id,
        s.cmr_note_no,
        s.cmr_note_date,
        s.sender_id,
        sh.name                                                                         as sender_name,
        s.carrier_id,
        ca.name                                                                         as carrier_name,
        s.consignee_id,
        co.name                                                                         as consignee_name,
        s.taking_over_place,
        s.origin_country,
        o.name                                                                          as origin_country_name,
        s.delivery_place,
        s.destination_country,
        d.name                                                                          as destination_country_name,
        s.taking_over_date,
        s.agreed_time_limit,
        s.delivery_date,
        s.disposal_date,
        s.goods_description,
        s.packages,
        s.gross_weight_kg,
        s.carriage_charges,
        s.currency_code,
        s.declared_value,
        s.declared_value_currency,
        s.special_interest,
        s.special_interest_currency,
        s.created_at,
        s.created_by,
        s.updated_at,
        s.updated_by,
        emk_api.emk_row_version_pkg.format_row_version(nvl(s.updated_at, s.created_at)) as row_version
    from
             emk_data.emk_shipments s
        join emk_data.emk_parties   sh on sh.party_id = s.sender_id
        join emk_data.emk_parties   ca on ca.party_id = s.carrier_id
        join emk_data.emk_parties   co on co.party_id = s.consignee_id
        join emk_data.emk_countries o on o.country_code = s.origin_country
        join emk_data.emk_countries d on d.country_code = s.destination_country
    where
        s.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"3706bf1e9d5310ac271acfc62c0d4a184cb5f3fa","type":"VIEW","name":"EMK_V_SHIPMENTS","schemaName":"EMK_API","sxml":""}