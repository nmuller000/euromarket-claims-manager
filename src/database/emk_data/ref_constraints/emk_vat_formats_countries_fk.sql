alter table emk_data.emk_vat_formats
    add constraint emk_vat_formats_countries_fk
        foreign key ( country_code )
            references emk_data.emk_countries ( country_code )
        enable;


-- sqlcl_snapshot {"hash":"b1b392ebe8a6762f7da51e3dafddbb256ad3e06d","type":"REF_CONSTRAINT","name":"EMK_VAT_FORMATS_COUNTRIES_FK","schemaName":"EMK_DATA","sxml":""}