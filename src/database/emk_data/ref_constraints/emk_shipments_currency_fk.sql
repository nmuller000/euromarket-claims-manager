alter table emk_data.emk_shipments
    add constraint emk_shipments_currency_fk
        foreign key ( currency_code )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"c99b0dd3eb82d74b2c288cd3931aa2f08947f996","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_CURRENCY_FK","schemaName":"EMK_DATA","sxml":""}