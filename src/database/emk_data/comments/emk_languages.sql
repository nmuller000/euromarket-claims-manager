comment on table emk_data.emk_languages is
    'Languages of the application and of letters (ISO 639-1); a code list with validity, read-only in the application (D-68)';

comment on column emk_data.emk_languages.language_code is
    'ISO 639-1 alpha-2 code, lower case';

comment on column emk_data.emk_languages.name is
    'English name (ISO 639)';

comment on column emk_data.emk_languages.valid_from is
    'Start of validity';

comment on column emk_data.emk_languages.valid_to is
    'End of validity; NULL = still valid. Stored rows keep a retired language';


-- sqlcl_snapshot {"hash":"e0c92e9447f8a09fa7f12129a10beb3a9a64f52c","type":"COMMENT","name":"emk_languages","schemaName":"emk_data","sxml":""}