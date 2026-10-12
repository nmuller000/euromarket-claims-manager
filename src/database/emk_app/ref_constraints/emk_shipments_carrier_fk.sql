alter table emk_app.emk_shipments
    add constraint emk_shipments_carrier_fk
        foreign key ( carrier_id )
            references emk_app.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"adc78eb22360eeb710b2e71fa2509420b6480f63","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CARRIER_FK","schemaName":"EMK_APP","sxml":""}