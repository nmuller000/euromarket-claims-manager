comment on table emk_app.emk_contacts is
    'Contact persons of a company: PERSONAL DATA isolated here and in EMK_CONTACTS_JN (GDPR erasure FR-41)';

comment on column emk_app.emk_contacts.email is
    'Personal data; basic syntax check only (RFC 5322 not fully validated)';

comment on column emk_app.emk_contacts.full_name is
    'Personal data';

comment on column emk_app.emk_contacts.phone is
    'Personal data; ITU-T E.164: + and at most 15 digits, no spaces';


-- sqlcl_snapshot {"hash":"beef9e1820bd31eb4a856aff22e65a78087a61f7","type":"COMMENT","name":"emk_contacts","schemaName":"emk_app","sxml":""}