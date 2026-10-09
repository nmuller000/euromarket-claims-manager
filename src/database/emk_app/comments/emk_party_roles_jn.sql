comment on table emk_app.emk_party_roles_jn is
    'Journal of EMK_PARTY_ROLES: removed roles (D); with created_at it shows from when to when a company had a role';

comment on column emk_app.emk_party_roles_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_party_roles_jn.jn_operation is
    'D = delete (U only if a row is ever updated, which the APIs do not do)';


-- sqlcl_snapshot {"hash":"90ab54fc68a708315c5f0fec2d076f2892081688","type":"COMMENT","name":"emk_party_roles_jn","schemaName":"emk_app","sxml":""}