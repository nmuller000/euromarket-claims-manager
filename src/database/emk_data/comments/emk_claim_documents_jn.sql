comment on table emk_data.emk_claim_documents_jn is
    'Journal of EMK_CLAIM_DOCUMENTS without content and extracted_text (the file is immutable, D-41)';

comment on column emk_data.emk_claim_documents_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_data.emk_claim_documents_jn.jn_operation is
    'U = update (doc_type, soft delete, restore), D = delete';


-- sqlcl_snapshot {"hash":"aff9b4389ca00da552fb30c6092c6914b9b03333","type":"COMMENT","name":"emk_claim_documents_jn","schemaName":"emk_data","sxml":""}