comment on table emk_app.emk_claim_status_history is
    'Business history of claim statuses (spec §4); written by EMK_CLAIM_API in the same transaction; never purged (ageing KPIs)';

comment on column emk_app.emk_claim_status_history.created_at is
    'When the status changed';

comment on column emk_app.emk_claim_status_history.created_by is
    'Who changed the status';

comment on column emk_app.emk_claim_status_history.from_status is
    'Previous status; NULL when the claim is created';

comment on column emk_app.emk_claim_status_history.reason is
    'Optional comment, e.g. reason for a rejection';

comment on column emk_app.emk_claim_status_history.to_status is
    'New status';


-- sqlcl_snapshot {"hash":"c1cf9216a60ea0c6fd4aa380267afe7c6524cf7e","type":"COMMENT","name":"emk_claim_status_history","schemaName":"emk_app","sxml":""}