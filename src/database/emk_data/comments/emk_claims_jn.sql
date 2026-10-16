comment on table emk_data.emk_claims_jn is
    'Journal of EMK_CLAIMS: previous row on UPDATE (U) and DELETE (D); written by trigger EMK_CLAIMS_JN_AUD';

comment on column emk_data.emk_claims_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_data.emk_claims_jn.jn_operation is
    'U = update (also status change, soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"40c566008ddb79c1e13852a74e7f5401994b5262","type":"COMMENT","name":"emk_claims_jn","schemaName":"emk_data","sxml":""}