alter table emk_app.emk_claims
    add constraint emk_claims_currencies_fk
        foreign key ( currency_code )
            references emk_app.emk_currencies ( currency_code )
        enable;


-- sqlcl_snapshot {"hash":"e665886ecdb6bbd8995bb02d94b70bb56d8b7280","type":"REF_CONSTRAINT","name":"EMK_CLAIMS_CURRENCIES_FK","schemaName":"EMK_APP","sxml":""}