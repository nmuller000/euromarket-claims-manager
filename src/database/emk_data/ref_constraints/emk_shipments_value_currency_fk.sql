alter table emk_data.emk_shipments
    add constraint emk_shipments_value_currency_fk
        foreign key ( declared_value_currency )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"5cff4b6de9a12547f2e92ba40ac32f98fbbbf9f0","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_VALUE_CURRENCY_FK","schemaName":"EMK_DATA","sxml":""}