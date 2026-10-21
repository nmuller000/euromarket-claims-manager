alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_from_fk
        foreign key ( from_status )
            references emk_data.emk_claim_statuses ( status_code )
        enable;


-- sqlcl_snapshot {"hash":"c06d7d51ee4cfee70238be8922f34f6b7ca69d3f","type":"REF_CONSTRAINT","name":"EMK_CLAIM_STATUS_HISTORY_FROM_FK","schemaName":"EMK_DATA","sxml":""}