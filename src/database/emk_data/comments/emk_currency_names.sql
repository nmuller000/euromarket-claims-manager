comment on table emk_data.emk_currency_names is
    'Currency names in languages other than English (ISO 639-1); English is in EMK_CURRENCIES.name';

comment on column emk_data.emk_currency_names.language_code is
    'ISO 639-1 language code, lower case; not en';

comment on column emk_data.emk_currency_names.name is
    'Translated name from the EU authority table Currencies';


-- sqlcl_snapshot {"hash":"d77e5b738cadea07f1f01262379766d32dfe405c","type":"COMMENT","name":"emk_currency_names","schemaName":"emk_data","sxml":""}