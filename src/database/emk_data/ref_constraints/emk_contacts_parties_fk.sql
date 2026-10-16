alter table emk_data.emk_contacts
    add constraint emk_contacts_parties_fk
        foreign key ( party_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"ebe625af0f5f0bfe5e9637274c352c491f4e43ec","type":"REF_CONSTRAINT","name":"EMK_CONTACTS_PARTIES_FK","schemaName":"EMK_DATA","sxml":""}