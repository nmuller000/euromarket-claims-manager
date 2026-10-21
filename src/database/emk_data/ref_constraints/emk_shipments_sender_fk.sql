alter table emk_data.emk_shipments
    add constraint emk_shipments_sender_fk
        foreign key ( sender_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"f369318f947ec4f3d096227ad9ef3cdedd55fa79","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_SENDER_FK","schemaName":"EMK_DATA","sxml":""}