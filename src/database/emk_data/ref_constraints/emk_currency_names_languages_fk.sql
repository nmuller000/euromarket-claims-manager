alter table emk_data.emk_currency_names
    add constraint emk_currency_names_languages_fk
        foreign key ( language_code )
            references emk_data.emk_languages ( language_code )
        enable;


-- sqlcl_snapshot {"hash":"9b432ad55ce25ead44c66994b056dddb5c2aaa74","type":"REF_CONSTRAINT","name":"EMK_CURRENCY_NAMES_LANGUAGES_FK","schemaName":"EMK_DATA","sxml":""}