alter table emk_data.emk_party_roles
    add constraint emk_party_roles_role_types_fk
        foreign key ( role_code )
            references emk_data.emk_party_role_types ( role_code )
        enable;


-- sqlcl_snapshot {"hash":"f68c7930ecfb06df135b4fdd0ee5b4844a69468b","type":"REF_CONSTRAINT","name":"EMK_PARTY_ROLES_ROLE_TYPES_FK","schemaName":"EMK_DATA","sxml":""}