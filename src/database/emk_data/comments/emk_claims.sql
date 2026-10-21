comment on table emk_data.emk_claims is
    'CMR claims (one shipment each, BR-04); status changes only through EMK_CLAIM_API (BR-01, BR-02); soft delete; journal EMK_CLAIMS_JN'
    ;

comment on column emk_data.emk_claims.carrier_rejection_date is
    'Written rejection by the carrier; ends the suspension (CMR Art. 32(2))';

comment on column emk_data.emk_claims.claimed_amount is
    'Amount claimed (BR-11)';

comment on column emk_data.emk_claims.claim_no is
    'Business number CLM-YYYY-NNNNNN (EMK_CLAIM_NO_SEQ)';

comment on column emk_data.emk_claims.claim_type is
    'Claim type (EMK_CLAIM_TYPES); different limitation rules';

comment on column emk_data.emk_claims.currency_code is
    'Currency of the amounts (ISO 4217; ECB rate on registration_date, BR-12)';

comment on column emk_data.emk_claims.damage_apparent_yn is
    'Apparent loss or damage (CMR Art. 30(1)); only for PARTIAL_LOSS and DAMAGE';

comment on column emk_data.emk_claims.handler is
    'APEX user responsible for the claim';

comment on column emk_data.emk_claims.joint_check_date is
    'Joint check by consignee and carrier (CMR Art. 30(2))';

comment on column emk_data.emk_claims.recovered_amount is
    'Amount received; requires and does not exceed settled_amount (BR-11)';

comment on column emk_data.emk_claims.registration_date is
    'Business date of registration; date of the EUR rate (BR-12)';

comment on column emk_data.emk_claims.reservation_date is
    'Reservation sent to the carrier (CMR Art. 30)';

comment on column emk_data.emk_claims.settled_amount is
    'Amount agreed; requires and does not exceed claimed_amount (BR-11)';

comment on column emk_data.emk_claims.status is
    'Status (EMK_CLAIM_STATUSES); changed only through the transitions of EMK_CLAIM_API (spec §4)';

comment on column emk_data.emk_claims.weight_short_kg is
    'Gross weight lost or damaged in kg (liability cap, M4)';

comment on column emk_data.emk_claims.written_claim_date is
    'Written claim; suspends the limitation period (CMR Art. 32(2))';


-- sqlcl_snapshot {"hash":"d28a4c914b2c40de74e8ca31e66f4db2bde7dfb6","type":"COMMENT","name":"emk_claims","schemaName":"emk_data","sxml":""}