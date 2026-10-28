alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_countries_fk
        foreign key ( country_code )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"6713884f53b43ea4e57e6d0ca524e34a4893d3f5","type":"REF_CONSTRAINT","name":"EMK_POSTAL_FORMATS_COUNTRIES_FK","schemaName":"EMK_DATA","sxml":""}