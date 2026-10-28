alter table emk_data.emk_parties
    add constraint emk_parties_languages_fk
        foreign key ( language_code )
            references emk_data.emk_languages ( language_code )
        enable;


-- sqlcl_snapshot {"hash":"43ce567ef788635ee94029d682a17bbb1fb2a7b1","type":"REF_CONSTRAINT","name":"EMK_PARTIES_LANGUAGES_FK","schemaName":"EMK_DATA","sxml":""}