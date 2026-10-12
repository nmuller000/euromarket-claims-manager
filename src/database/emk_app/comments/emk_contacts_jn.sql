comment on table emk_app.emk_contacts_jn is
    'Journal of EMK_CONTACTS: PERSONAL DATA; GDPR erasure (FR-41) must also process this table';

comment on column emk_app.emk_contacts_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_contacts_jn.jn_operation is
    'U = update (also soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"c267a3462f54c22db218138f7754d1e9f903c002","type":"COMMENT","name":"emk_contacts_jn","schemaName":"emk_app","sxml":""}