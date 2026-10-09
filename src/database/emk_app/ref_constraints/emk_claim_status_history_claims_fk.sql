alter table emk_app.emk_claim_status_history
    add constraint emk_claim_status_history_claims_fk
        foreign key ( claim_id )
            references emk_app.emk_claims ( claim_id )
        enable;


-- sqlcl_snapshot {"hash":"85e3e662e556a7440a4b28f2ba71266f5a916808","type":"REF_CONSTRAINT","name":"EMK_CLAIM_STATUS_HISTORY_CLAIMS_FK","schemaName":"EMK_APP","sxml":""}