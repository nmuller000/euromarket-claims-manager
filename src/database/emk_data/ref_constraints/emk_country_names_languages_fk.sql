alter table emk_data.emk_country_names
    add constraint emk_country_names_languages_fk
        foreign key ( language_code )
            references emk_data.emk_languages ( language_code )
        enable;


-- sqlcl_snapshot {"hash":"58acc400c8382e251e3fe2430e8e7e22d194ba61","type":"REF_CONSTRAINT","name":"EMK_COUNTRY_NAMES_LANGUAGES_FK","schemaName":"EMK_DATA","sxml":""}