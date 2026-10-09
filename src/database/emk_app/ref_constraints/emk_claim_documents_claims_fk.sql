alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_claims_fk
        foreign key ( claim_id )
            references emk_app.emk_claims ( claim_id )
        enable;


-- sqlcl_snapshot {"hash":"a7aa90dd8517969d39b17c19388789ad9d830433","type":"REF_CONSTRAINT","name":"EMK_CLAIM_DOCUMENTS_CLAIMS_FK","schemaName":"EMK_APP","sxml":""}