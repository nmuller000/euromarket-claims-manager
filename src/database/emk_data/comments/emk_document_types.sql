comment on table emk_data.emk_document_types is
    'Kinds of documents attached to a claim; a code list with validity, maintained by the administrator (D-68)';

comment on column emk_data.emk_document_types.description is
    'Meaning and CMR articles';

comment on column emk_data.emk_document_types.doc_type is
    'Document type code, upper case';

comment on column emk_data.emk_document_types.name is
    'English display name';

comment on column emk_data.emk_document_types.sort_order is
    'Position in lists';

comment on column emk_data.emk_document_types.valid_from is
    'Start of validity';

comment on column emk_data.emk_document_types.valid_to is
    'End of validity; NULL = still valid';


-- sqlcl_snapshot {"hash":"c61bb3c9b6e0aef0296df4cc8e3eaa178d14b171","type":"COMMENT","name":"emk_document_types","schemaName":"emk_data","sxml":""}