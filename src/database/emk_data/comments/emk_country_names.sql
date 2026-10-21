comment on table emk_data.emk_country_names is
    'Country names in languages other than English (ISO 639-1); English is in EMK_COUNTRIES.name';

comment on column emk_data.emk_country_names.language_code is
    'Language of the name (EMK_LANGUAGES); not en, which is the base table';

comment on column emk_data.emk_country_names.name is
    'Translated name from the EU authority table Countries and territories';


-- sqlcl_snapshot {"hash":"24fa7f29a75a97518ce400276d2a576f8bb14cb4","type":"COMMENT","name":"emk_country_names","schemaName":"emk_data","sxml":""}