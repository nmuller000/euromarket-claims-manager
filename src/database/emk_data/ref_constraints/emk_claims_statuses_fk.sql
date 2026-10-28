alter table emk_data.emk_claims
    add constraint emk_claims_statuses_fk
        foreign key ( status )
            references emk_data.emk_claim_statuses ( status_code )
        enable;


-- sqlcl_snapshot {"hash":"976d4a7d6d36e479d704e2afd3d5f463e37b1725","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_STATUSES_FK","schemaName":"EMK_DATA","sxml":""}