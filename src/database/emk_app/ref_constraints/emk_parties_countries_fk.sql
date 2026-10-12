alter table emk_app.emk_parties
    add constraint emk_parties_countries_fk
        foreign key ( country_code )
            references emk_app.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"d0eb1a9a5b1aee0a4c90a3cbb4615f81f74f6ee3","type":"REF_CONSTRAINT","name":"EMK_PARTIES_COUNTRIES_FK","schemaName":"EMK_APP","sxml":""}