comment on table emk_data.emk_party_roles_jn is
    'Journal of EMK_PARTY_ROLES: removed roles (D); with created_at it shows from when to when a company had a role';

comment on column emk_data.emk_party_roles_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_data.emk_party_roles_jn.jn_operation is
    'D = delete (U only if a row is ever updated, which the APIs do not do)';


-- sqlcl_snapshot {"hash":"139b5372eadacdc7a5c13d8a1b36ba686da1fba4","type":"COMMENT","name":"emk_party_roles_jn","schemaName":"emk_data","sxml":""}