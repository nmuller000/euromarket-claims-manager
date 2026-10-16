alter table emk_data.emk_shipments
    add constraint emk_shipments_origin_fk
        foreign key ( origin_country )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"5668c690123ad286f80dc5ab90442937b5dbd85f","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_ORIGIN_FK","schemaName":"EMK_DATA","sxml":""}