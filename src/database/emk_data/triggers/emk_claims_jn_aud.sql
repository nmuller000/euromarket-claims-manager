create or replace editionable trigger emk_data.emk_claims_jn_aud after
    update or delete on emk_data.emk_claims
    for each row
    /**
     * Journal: stores the previous row of EMK_CLAIMS in EMK_CLAIMS_JN
     * (U = update, D = delete). Every journaled column must be listed
     * (checked by the tests, D-39). jn_at and jn_by come from the defaults.
     *
     * @author Natalia Müller
     * @since  2026-10-09
     */
declare
    l_operation emk_claims_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_claims_jn (
        jn_operation,
        claim_id,
        claim_no,
        shipment_id,
        claim_type,
        damage_apparent_yn,
        status,
        handler,
        registration_date,
        joint_check_date,
        reservation_date,
        written_claim_date,
        carrier_rejection_date,
        weight_short_kg,
        claimed_amount,
        settled_amount,
        recovered_amount,
        currency_code,
        description,
        created_at,
        created_by,
        updated_at,
        updated_by,
        deleted_yn,
        deleted_by,
        deleted_at
    ) values ( l_operation,
               :old.claim_id,
               :old.claim_no,
               :old.shipment_id,
               :old.claim_type,
               :old.damage_apparent_yn,
               :old.status,
               :old.handler,
               :old.registration_date,
               :old.joint_check_date,
               :old.reservation_date,
               :old.written_claim_date,
               :old.carrier_rejection_date,
               :old.weight_short_kg,
               :old.claimed_amount,
               :old.settled_amount,
               :old.recovered_amount,
               :old.currency_code,
               :old.description,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by,
               :old.deleted_yn,
               :old.deleted_by,
               :old.deleted_at );

end;
/

alter trigger emk_data.emk_claims_jn_aud enable;


-- sqlcl_snapshot {"hash":"cb485661cb0d79dfeb3c3161accaa8ca85187234","type":"TRIGGER","name":"EMK_CLAIMS_JN_AUD","schemaName":"EMK_DATA","sxml":""}