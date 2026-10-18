create or replace force editionable view emk_api.emk_v_shipment_history (
    history_id,
    shipment_id,
    changed_at,
    changed_by,
    action,
    previous_cmr_note_no,
    previous_shipper_id,
    previous_carrier_id,
    previous_consignee_id,
    previous_pickup_place,
    previous_origin_country,
    previous_delivery_place,
    previous_destination_country,
    previous_pickup_date,
    previous_agreed_delivery_date,
    previous_delivery_date,
    previous_goods_description,
    previous_packages,
    previous_gross_weight_kg,
    previous_carriage_charges,
    previous_currency_code
) as
    select
    /**
     * Change history of shipments (FR-09, D-67): when, who, the action and the
     * values before the change. Shown in the shipment form to the claims
     * handler, the compliance officer and the administrator.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        j.jn_id                as history_id,
        j.shipment_id,
        j.jn_at                as changed_at,
        j.jn_by                as changed_by,
        case
            when j.deleted_yn = 'N'
                 and j.next_deleted_yn = 'Y' then
                'DELETED'
            when j.deleted_yn = 'Y'
                 and j.next_deleted_yn = 'N' then
                'RESTORED'
            else
                'UPDATED'
        end                    as action,
        j.cmr_note_no          as previous_cmr_note_no,
        j.shipper_id           as previous_shipper_id,
        j.carrier_id           as previous_carrier_id,
        j.consignee_id         as previous_consignee_id,
        j.pickup_place         as previous_pickup_place,
        j.origin_country       as previous_origin_country,
        j.delivery_place       as previous_delivery_place,
        j.destination_country  as previous_destination_country,
        j.pickup_date          as previous_pickup_date,
        j.agreed_delivery_date as previous_agreed_delivery_date,
        j.delivery_date        as previous_delivery_date,
        j.goods_description    as previous_goods_description,
        j.packages             as previous_packages,
        j.gross_weight_kg      as previous_gross_weight_kg,
        j.carriage_charges     as previous_carriage_charges,
        j.currency_code        as previous_currency_code
    from
        (
            select
                jn.*,
                coalesce(lead(jn.deleted_yn)
                         over(partition by jn.shipment_id
                              order by
                                  jn.jn_at, jn.jn_id
                ),
                         s.deleted_yn) as next_deleted_yn
            from
                     emk_data.emk_shipments_jn jn
                join emk_data.emk_shipments s on s.shipment_id = jn.shipment_id
        ) j;


-- sqlcl_snapshot {"hash":"b44a20658b30ad44be3c56324c5ee0eaa5f5105a","type":"VIEW","name":"EMK_V_SHIPMENT_HISTORY","schemaName":"EMK_API","sxml":""}