alter table emk_data.emk_shipments
    add constraint emk_shipments_carrier_fk
        foreign key ( carrier_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"0c6292cb0ebc504b942569feb78c9f69268df7e1","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CARRIER_FK","schemaName":"EMK_DATA","sxml":""}