alter table emk_app.emk_shipments
    add constraint emk_shipments_currency_fk
        foreign key ( currency_code )
            references emk_app.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"def6cb7590b79a4d12b8ba50cf6350a28c9bfad6","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CURRENCY_FK","schemaName":"EMK_APP","sxml":""}