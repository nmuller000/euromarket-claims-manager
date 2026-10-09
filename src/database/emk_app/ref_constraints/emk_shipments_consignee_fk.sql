alter table emk_app.emk_shipments
    add constraint emk_shipments_consignee_fk
        foreign key ( consignee_id )
            references emk_app.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"4c5179b6dbff042929b28c3d9e3478aa7e66d2e8","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CONSIGNEE_FK","schemaName":"EMK_APP","sxml":""}