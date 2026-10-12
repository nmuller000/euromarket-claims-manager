comment on table emk_app.emk_claim_documents is
    'Documents of a claim (evidence); the file is immutable (trigger EMK_CLAIM_DOCUMENTS_BU, D-41); journal without the file';

comment on column emk_app.emk_claim_documents.content is
    'The file (SecureFiles BLOB); immutable: a new file is a new document row';

comment on column emk_app.emk_claim_documents.doc_type is
    'CMR_NOTE, DAMAGE_REPORT, PHOTO, INVOICE, CORRESPONDENCE or OTHER';

comment on column emk_app.emk_claim_documents.extracted_text is
    'Text extracted for search and AI features (M3, X1)';

comment on column emk_app.emk_claim_documents.file_name is
    'Original file name (immutable)';

comment on column emk_app.emk_claim_documents.file_size is
    'Bytes, 1 to 10 MB (immutable)';

comment on column emk_app.emk_claim_documents.mime_type is
    'application/pdf, image/jpeg or image/png (immutable)';


-- sqlcl_snapshot {"hash":"c49521a681dba42296b483dc0658f3d5ced74078","type":"COMMENT","name":"emk_claim_documents","schemaName":"emk_app","sxml":""}