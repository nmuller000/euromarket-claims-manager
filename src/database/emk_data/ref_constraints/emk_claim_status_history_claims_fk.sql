alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_claims_fk
        foreign key ( claim_id )
            references emk_data.emk_claims ( claim_id )
        enable;


-- sqlcl_snapshot {"hash":"454a028244ec9013eb01a1e5ad93919b0e45dad0","type":"REF_CONSTRAINT","name":"EMK_CLAIM_STATUS_HISTORY_CLAIMS_FK","schemaName":"EMK_DATA","sxml":""}