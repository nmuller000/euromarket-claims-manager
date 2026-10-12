comment on table emk_app.emk_country_names is
    'Country names in languages other than English (ISO 639-1); English is in EMK_COUNTRIES.name';

comment on column emk_app.emk_country_names.language_code is
    'ISO 639-1 language code, lower case; not en';

comment on column emk_app.emk_country_names.name is
    'Translated name from the EU authority table Countries and territories';


-- sqlcl_snapshot {"hash":"e3297618ebe2c2225633090ba3389e58a45dd519","type":"COMMENT","name":"emk_country_names","schemaName":"emk_app","sxml":""}