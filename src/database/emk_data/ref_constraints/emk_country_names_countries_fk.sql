alter table emk_data.emk_country_names
    add constraint emk_country_names_countries_fk
        foreign key ( country_code )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"61d19df4350bce15268f5fdf041b96a505153ec1","type":"REF_CONSTRAINT","name":"EMK_COUNTRY_NAMES_COUNTRIES_FK","schemaName":"EMK_DATA","sxml":""}