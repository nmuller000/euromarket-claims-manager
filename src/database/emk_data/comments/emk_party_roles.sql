comment on table emk_data.emk_party_roles is
    'Roles of a company (party-role pattern; BR-16); a role change is a DELETE plus an INSERT, recorded in EMK_PARTY_ROLES_JN';

comment on column emk_data.emk_party_roles.role_code is
    'Role (EMK_PARTY_ROLE_TYPES)';


-- sqlcl_snapshot {"hash":"d3c407eb53f46a2c5aa4b41c44e4ab7286ae8a34","type":"COMMENT","name":"emk_party_roles","schemaName":"emk_data","sxml":""}