comment on table emk_app.emk_claims is
    'CMR claims (one shipment each, BR-04); status changes only through EMK_CLAIM_API (BR-01, BR-02); soft delete; journal EMK_CLAIMS_JN'
    ;

comment on column emk_app.emk_claims.carrier_rejection_date is
    'Written rejection by the carrier; ends the suspension (CMR Art. 32(2))';

comment on column emk_app.emk_claims.claimed_amount is
    'Amount claimed (BR-11)';

comment on column emk_app.emk_claims.claim_no is
    'Business number CLM-YYYY-NNNNNN (EMK_CLAIM_NO_SEQ)';

comment on column emk_app.emk_claims.claim_type is
    'TOTAL_LOSS, PARTIAL_LOSS, DAMAGE or DELAY (different limitation rules)';

comment on column emk_app.emk_claims.currency_code is
    'Currency of the amounts (ISO 4217; ECB rate on registration_date, BR-12)';

comment on column emk_app.emk_claims.damage_apparent_yn is
    'Apparent loss or damage (CMR Art. 30(1)); only for PARTIAL_LOSS and DAMAGE';

comment on column emk_app.emk_claims.handler is
    'APEX user responsible for the claim';

comment on column emk_app.emk_claims.joint_check_date is
    'Joint check by consignee and carrier (CMR Art. 30(2))';

comment on column emk_app.emk_claims.recovered_amount is
    'Amount received; requires and does not exceed settled_amount (BR-11)';

comment on column emk_app.emk_claims.registration_date is
    'Business date of registration; date of the EUR rate (BR-12)';

comment on column emk_app.emk_claims.reservation_date is
    'Reservation sent to the carrier (CMR Art. 30)';

comment on column emk_app.emk_claims.settled_amount is
    'Amount agreed; requires and does not exceed claimed_amount (BR-11)';

comment on column emk_app.emk_claims.status is
    'DRAFT, SUBMITTED, UNDER_REVIEW, NEGOTIATION, RESOLVED, REJECTED or ESCALATED (state machine, spec §4)';

comment on column emk_app.emk_claims.weight_short_kg is
    'Gross weight lost or damaged in kg (liability cap, M4)';

comment on column emk_app.emk_claims.written_claim_date is
    'Written claim; suspends the limitation period (CMR Art. 32(2))';


-- sqlcl_snapshot {"hash":"22659aa0179259cf769cc85306947877f784e44d","type":"COMMENT","name":"emk_claims","schemaName":"emk_app","sxml":""}