comment on table emk_data.emk_contacts_jn is
    'Journal of EMK_CONTACTS: PERSONAL DATA; GDPR erasure (FR-41) must also process this table';

comment on column emk_data.emk_contacts_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_data.emk_contacts_jn.jn_operation is
    'U = update (also soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"8ec9c33042be267490535f75acae85416a8aee67","type":"COMMENT","name":"emk_contacts_jn","schemaName":"emk_data","sxml":""}