alter table emk_data.emk_shipments
    add constraint emk_shipments_interest_currency_fk
        foreign key ( special_interest_currency )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"bb69b07d7ce7fce27fbe5ab8716c2e9fa5580b4e","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_INTEREST_CURRENCY_FK","schemaName":"EMK_DATA","sxml":""}