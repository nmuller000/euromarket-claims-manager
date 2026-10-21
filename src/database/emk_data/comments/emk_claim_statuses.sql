comment on table emk_data.emk_claim_statuses is
    'Statuses of the claim state machine (spec §4); a code list with validity (D-68). Transitions are program logic of EMK_CLAIM_API (BR-01)'
    ;

comment on column emk_data.emk_claim_statuses.description is
    'Meaning of the status';

comment on column emk_data.emk_claim_statuses.final_yn is
    'Y = final status (RESOLVED, REJECTED, ESCALATED): the claim is closed';

comment on column emk_data.emk_claim_statuses.name is
    'English display name';

comment on column emk_data.emk_claim_statuses.sort_order is
    'Position in lists (order of the state machine)';

comment on column emk_data.emk_claim_statuses.status_code is
    'Status code, upper case';

comment on column emk_data.emk_claim_statuses.valid_from is
    'Start of validity';

comment on column emk_data.emk_claim_statuses.valid_to is
    'End of validity; NULL = still valid';


-- sqlcl_snapshot {"hash":"c8f9c844f7353ab4f76212a388e58c204d54d90b","type":"COMMENT","name":"emk_claim_statuses","schemaName":"emk_data","sxml":""}