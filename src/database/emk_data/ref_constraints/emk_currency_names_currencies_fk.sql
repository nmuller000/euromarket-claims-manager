alter table emk_data.emk_currency_names
    add constraint emk_currency_names_currencies_fk
        foreign key ( currency_code )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"3cd08748bfec9690343488dbf71ef56927a6f86d","type":"REF_CONSTRAINT","name":"EMK_CURRENCY_NAMES_CURRENCIES_FK","schemaName":"EMK_DATA","sxml":""}