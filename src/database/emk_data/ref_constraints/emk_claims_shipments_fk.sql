alter table emk_data.emk_claims
    add constraint emk_claims_shipments_fk
        foreign key ( shipment_id )
            references emk_data.emk_shipments ( shipment_id )
        enable;


-- sqlcl_snapshot {"hash":"edf00f69beea348c659570d74eeb65253624937f","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_SHIPMENTS_FK","schemaName":"EMK_DATA","sxml":""}