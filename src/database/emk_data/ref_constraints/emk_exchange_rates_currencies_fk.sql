alter table emk_data.emk_exchange_rates
    add constraint emk_exchange_rates_currencies_fk
        foreign key ( currency_code )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"e25a514d7122e02ba8975a4750ce9ccf79e0b8aa","type":"REF_CONSTRAINT","name":"EMK_EXCHANGE_RATES_CURRENCIES_FK","schemaName":"EMK_DATA","sxml":""}