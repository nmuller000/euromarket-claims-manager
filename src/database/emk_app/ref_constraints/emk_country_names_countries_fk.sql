alter table emk_app.emk_country_names
    add constraint emk_country_names_countries_fk
        foreign key ( country_code )
            references emk_app.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"fb6bbb722dee7f12133b4e110c20c3246051aea1","type":"REF_CONSTRAINT","name":"EMK_COUNTRY_NAMES_COUNTRIES_FK","schemaName":"EMK_APP","sxml":""}