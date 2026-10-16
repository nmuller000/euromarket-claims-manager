alter table emk_data.emk_shipments
    add constraint emk_shipments_consignee_fk
        foreign key ( consignee_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"1e6218bcbf5cbaad37a5d4b67d43c2d6ca12b6f7","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CONSIGNEE_FK","schemaName":"EMK_DATA","sxml":""}