alter table emk_data.emk_claims
    add constraint emk_claims_claim_types_fk
        foreign key ( claim_type )
            references emk_data.emk_claim_types ( claim_type )
        enable;


-- sqlcl_snapshot {"hash":"cfeff1951c7678bc3a3484deee914b5000e60eb8","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_CLAIM_TYPES_FK","schemaName":"EMK_DATA","sxml":""}