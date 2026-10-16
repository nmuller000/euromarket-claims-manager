alter table emk_data.emk_parties
    add constraint emk_parties_countries_fk
        foreign key ( country_code )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"ab57613f2aea3fbdd032323a9e5cb00c5dc76a0e","type":"REF_CONSTRAINT","name":"EMK_PARTIES_COUNTRIES_FK","schemaName":"EMK_DATA","sxml":""}