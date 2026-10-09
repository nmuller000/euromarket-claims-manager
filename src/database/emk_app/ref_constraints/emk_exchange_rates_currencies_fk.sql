alter table emk_app.emk_exchange_rates
    add constraint emk_exchange_rates_currencies_fk
        foreign key ( currency_code )
            references emk_app.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"d1792dba347092f4fd972afccba8baa8f3b88d91","type":"REF_CONSTRAINT","name":"EMK_EXCHANGE_RATES_CURRENCIES_FK","schemaName":"EMK_APP","sxml":""}