comment on table emk_data.emk_contacts is
    'Contact persons of a company: PERSONAL DATA isolated here and in EMK_CONTACTS_JN (GDPR erasure FR-41)';

comment on column emk_data.emk_contacts.email is
    'Personal data; basic syntax check only (RFC 5322 not fully validated)';

comment on column emk_data.emk_contacts.full_name is
    'Personal data';

comment on column emk_data.emk_contacts.phone is
    'Personal data; ITU-T E.164: + and at most 15 digits, no spaces';


-- sqlcl_snapshot {"hash":"5820f3573350fefe20d4bbe5e03a095f4322a0bc","type":"COMMENT","name":"emk_contacts","schemaName":"emk_data","sxml":""}