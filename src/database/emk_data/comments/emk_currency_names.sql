comment on table emk_data.emk_currency_names is
    'Currency names in languages other than English (ISO 639-1); English is in EMK_CURRENCIES.name';

comment on column emk_data.emk_currency_names.language_code is
    'Language of the name (EMK_LANGUAGES); not en, which is the base table';

comment on column emk_data.emk_currency_names.name is
    'Translated name from the EU authority table Currencies';


-- sqlcl_snapshot {"hash":"d7348661d22d666393ee764db08f3ab03d926d41","type":"COMMENT","name":"emk_currency_names","schemaName":"emk_data","sxml":""}