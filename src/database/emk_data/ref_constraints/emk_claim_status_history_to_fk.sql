alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_to_fk
        foreign key ( to_status )
            references emk_data.emk_claim_statuses ( status_code )
        enable;


-- sqlcl_snapshot {"hash":"34d277d8f1b9f3b3ac1658f893ef0f1e9103d837","type":"REF_CONSTRAINT","name":"EMK_CLAIM_STATUS_HISTORY_TO_FK","schemaName":"EMK_DATA","sxml":""}