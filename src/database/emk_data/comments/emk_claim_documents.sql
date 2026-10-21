comment on table emk_data.emk_claim_documents is
    'Documents of a claim (evidence); the file is immutable (trigger EMK_CLAIM_DOCUMENTS_BU, D-41); journal without the file';

comment on column emk_data.emk_claim_documents.content is
    'The file (SecureFiles BLOB); immutable: a new file is a new document row';

comment on column emk_data.emk_claim_documents.doc_type is
    'Document type (EMK_DOCUMENT_TYPES)';

comment on column emk_data.emk_claim_documents.extracted_text is
    'Text extracted for search and AI features (M3, X1)';

comment on column emk_data.emk_claim_documents.file_name is
    'Original file name (immutable)';

comment on column emk_data.emk_claim_documents.file_size is
    'Bytes, 1 to 10 MB (immutable)';

comment on column emk_data.emk_claim_documents.mime_type is
    'File type determined by the server from the extension and checked against the content signature (EMK_FILE_TYPES, BR-18); immutable'
    ;


-- sqlcl_snapshot {"hash":"55dcb18bd10df374665e4b33f84ac0334667d944","type":"COMMENT","name":"emk_claim_documents","schemaName":"emk_data","sxml":""}