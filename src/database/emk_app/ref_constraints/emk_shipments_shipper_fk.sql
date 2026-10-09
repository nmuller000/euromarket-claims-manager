alter table emk_app.emk_shipments
    add constraint emk_shipments_shipper_fk
        foreign key ( shipper_id )
            references emk_app.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"2ac0cbd97a995242fe02d69b993981ecdca4c7b7","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_SHIPPER_FK","schemaName":"EMK_APP","sxml":""}