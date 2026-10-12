alter table emk_app.emk_currency_names
    add constraint emk_currency_names_currencies_fk
        foreign key ( currency_code )
            references emk_app.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"15f6607fdde059e012ca30d6fb05b504e38ba36a","type":"REF_CONSTRAINT","name":"EMK_CURRENCY_NAMES_CURRENCIES_FK","schemaName":"EMK_APP","sxml":""}