alter table emk_data.emk_party_roles
    add constraint emk_party_roles_parties_fk
        foreign key ( party_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"4cfee2753772380970044380e4c53e73ad5395e3","type":"REF_CONSTRAINT","name":"EMK_PARTY_ROLES_PARTIES_FK","schemaName":"EMK_DATA","sxml":""}