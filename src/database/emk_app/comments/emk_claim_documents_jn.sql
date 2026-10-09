comment on table emk_app.emk_claim_documents_jn is
    'Journal of EMK_CLAIM_DOCUMENTS without content and extracted_text (the file is immutable, D-41)';

comment on column emk_app.emk_claim_documents_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_claim_documents_jn.jn_operation is
    'U = update (doc_type, soft delete, restore), D = delete';


-- sqlcl_snapshot {"hash":"754768c4a73a0bd6fc770f0a5608e219bb1d3b4e","type":"COMMENT","name":"emk_claim_documents_jn","schemaName":"emk_app","sxml":""}