alter table emk_data.emk_claim_documents
    add constraint emk_claim_documents_claims_fk
        foreign key ( claim_id )
            references emk_data.emk_claims ( claim_id )
        enable;


-- sqlcl_snapshot {"hash":"02847d6ba25e739db2f9e636ea1cb7f7f505391f","type":"REF_CONSTRAINT","name":"EMK_CLAIM_DOCUMENTS_CLAIMS_FK","schemaName":"EMK_DATA","sxml":""}