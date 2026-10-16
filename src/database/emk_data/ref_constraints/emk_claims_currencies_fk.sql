alter table emk_data.emk_claims
    add constraint emk_claims_currencies_fk
        foreign key ( currency_code )
            references emk_data.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"31daa86d93d5aa5b65dd0f083bc6a999a283e320","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_CURRENCIES_FK","schemaName":"EMK_DATA","sxml":""}