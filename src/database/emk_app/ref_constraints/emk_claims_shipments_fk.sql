alter table emk_app.emk_claims
    add constraint emk_claims_shipments_fk
        foreign key ( shipment_id )
            references emk_app.emk_shipments ( shipment_id )
        enable;


-- sqlcl_snapshot {"hash":"2bbeaffadc29349aaaf4441d08cdb5779f062c57","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_SHIPMENTS_FK","schemaName":"EMK_APP","sxml":""}