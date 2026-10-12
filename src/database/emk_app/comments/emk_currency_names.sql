comment on table emk_app.emk_currency_names is
    'Currency names in languages other than English (ISO 639-1); English is in EMK_CURRENCIES.name';

comment on column emk_app.emk_currency_names.language_code is
    'ISO 639-1 language code, lower case; not en';

comment on column emk_app.emk_currency_names.name is
    'Translated name from the EU authority table Currencies';


-- sqlcl_snapshot {"hash":"eccb5099c067cb8c9f16f4c6b520c2a5b03455e1","type":"COMMENT","name":"emk_currency_names","schemaName":"emk_app","sxml":""}