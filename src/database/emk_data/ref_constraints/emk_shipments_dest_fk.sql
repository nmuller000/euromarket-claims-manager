alter table emk_data.emk_shipments
    add constraint emk_shipments_dest_fk
        foreign key ( destination_country )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"47fb226305f1f38d3486c004c51801d80dce6510","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_DEST_FK","schemaName":"EMK_DATA","sxml":""}