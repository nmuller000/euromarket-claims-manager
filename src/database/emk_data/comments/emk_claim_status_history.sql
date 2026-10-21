comment on table emk_data.emk_claim_status_history is
    'Business history of claim statuses (spec §4); written by EMK_CLAIM_API in the same transaction; never purged (ageing KPIs)';

comment on column emk_data.emk_claim_status_history.created_at is
    'When the status changed';

comment on column emk_data.emk_claim_status_history.created_by is
    'Who changed the status';

comment on column emk_data.emk_claim_status_history.from_status is
    'Previous status (EMK_CLAIM_STATUSES); NULL when the claim is created';

comment on column emk_data.emk_claim_status_history.reason is
    'Optional comment, e.g. reason for a rejection';

comment on column emk_data.emk_claim_status_history.to_status is
    'New status (EMK_CLAIM_STATUSES)';


-- sqlcl_snapshot {"hash":"e468ad5c9c9b738f7b90037351b0d3912036a3e6","type":"COMMENT","name":"emk_claim_status_history","schemaName":"emk_data","sxml":""}