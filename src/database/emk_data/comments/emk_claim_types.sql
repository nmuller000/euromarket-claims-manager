comment on table emk_data.emk_claim_types is
    'Kinds of CMR claims (different limitation rules, spec §5); a code list with validity (D-68)';

comment on column emk_data.emk_claim_types.claim_type is
    'Claim type code, upper case';

comment on column emk_data.emk_claim_types.description is
    'Meaning and CMR articles';

comment on column emk_data.emk_claim_types.name is
    'English display name';

comment on column emk_data.emk_claim_types.sort_order is
    'Position in lists';

comment on column emk_data.emk_claim_types.valid_from is
    'Start of validity';

comment on column emk_data.emk_claim_types.valid_to is
    'End of validity; NULL = still valid';


-- sqlcl_snapshot {"hash":"8591c1ad930fae8b08200ef9675eeed43f69fd0a","type":"COMMENT","name":"emk_claim_types","schemaName":"emk_data","sxml":""}