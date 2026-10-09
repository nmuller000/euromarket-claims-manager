alter table emk_app.emk_contacts
    add constraint emk_contacts_parties_fk
        foreign key ( party_id )
            references emk_app.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"d01bdbcc30169d08622a7ed361c90cf328c67b5f","type":"REF_CONSTRAINT","name":"EMK_CONTACTS_PARTIES_FK","schemaName":"EMK_APP","sxml":""}