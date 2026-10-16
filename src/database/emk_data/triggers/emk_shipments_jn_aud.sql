create or replace editionable trigger emk_data.emk_shipments_jn_aud after
    update or delete on emk_data.emk_shipments
    for each row
    /**
     * Journal: stores the previous row of EMK_SHIPMENTS in EMK_SHIPMENTS_JN
     * (U = update, D = delete). Every column of the base table must be listed
     * (checked by the tests, D-39). jn_at and jn_by come from the defaults.
     *
     * @author Natalia Müller
     * @since  2026-10-09
     */
declare
    l_operation emk_shipments_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_shipments_jn (
        jn_operation,
        shipment_id,
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
        currency_code,
        created_at,
        created_by,
        updated_at,
        updated_by,
        deleted_yn,
        deleted_by,
        deleted_at
    ) values ( l_operation,
               :old.shipment_id,
               :old.cmr_note_no,
               :old.shipper_id,
               :old.carrier_id,
               :old.consignee_id,
               :old.pickup_place,
               :old.origin_country,
               :old.delivery_place,
               :old.destination_country,
               :old.pickup_date,
               :old.agreed_delivery_date,
               :old.delivery_date,
               :old.goods_description,
               :old.packages,
               :old.gross_weight_kg,
               :old.carriage_charges,
               :old.currency_code,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by,
               :old.deleted_yn,
               :old.deleted_by,
               :old.deleted_at );

end;
/

alter trigger emk_data.emk_shipments_jn_aud enable;


-- sqlcl_snapshot {"hash":"8039dd512c8f64b45066cab0d403a2c2911b130c","type":"TRIGGER","name":"EMK_SHIPMENTS_JN_AUD","schemaName":"EMK_DATA","sxml":""}