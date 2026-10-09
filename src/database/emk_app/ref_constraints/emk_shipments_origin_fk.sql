alter table emk_app.emk_shipments
    add constraint emk_shipments_origin_fk
        foreign key ( origin_country )
            references emk_app.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"7fd2618d3789e612cd25f17298bcd350d19cf9a7","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_ORIGIN_FK","schemaName":"EMK_APP","sxml":""}