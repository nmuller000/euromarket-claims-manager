alter table emk_app.emk_shipments
    add constraint emk_shipments_dest_fk
        foreign key ( destination_country )
            references emk_app.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"09c06b0e0c566d3c54ce6fd154de7575410a48b5","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_DEST_FK","schemaName":"EMK_APP","sxml":""}