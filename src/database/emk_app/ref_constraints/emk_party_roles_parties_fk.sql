alter table emk_app.emk_party_roles
    add constraint emk_party_roles_parties_fk
        foreign key ( party_id )
            references emk_app.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"c3fe75505cac894c66fc499ae8925f812b7d4ab2","type":"REF_CONSTRAINT","name":"EMK_PARTY_ROLES_PARTIES_FK","schemaName":"EMK_APP","sxml":""}