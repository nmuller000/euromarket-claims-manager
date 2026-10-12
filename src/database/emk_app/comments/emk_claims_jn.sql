comment on table emk_app.emk_claims_jn is
    'Journal of EMK_CLAIMS: previous row on UPDATE (U) and DELETE (D); written by trigger EMK_CLAIMS_JN_AUD';

comment on column emk_app.emk_claims_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_claims_jn.jn_operation is
    'U = update (also status change, soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"953a40e70b6cc654853e7eb13def64c090314f20","type":"COMMENT","name":"emk_claims_jn","schemaName":"emk_app","sxml":""}