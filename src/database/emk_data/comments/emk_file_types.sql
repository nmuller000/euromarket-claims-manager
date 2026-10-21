comment on table emk_data.emk_file_types is
    'Catalog of file types for claim documents (BR-18, OWASP ASVS 5.0 V5): type and signature added by developers with documented criteria; allowed period set by the administrator (D-72)'
    ;

comment on column emk_data.emk_file_types.mime_type is
    'IANA media type, lower case; stored on each document as determined by the server';

comment on column emk_data.emk_file_types.name is
    'English display name';

comment on column emk_data.emk_file_types.signature is
    'First bytes every file of this type starts with (magic bytes): PDF 255044462D, JPEG FFD8FF, PNG 89504E470D0A1A0A';

comment on column emk_data.emk_file_types.valid_from is
    'Allowed from (administrator); NULL = in the catalog but not allowed';

comment on column emk_data.emk_file_types.valid_to is
    'Allowed until; NULL = still allowed. Stored documents keep a retired type; it cannot be uploaded again';


-- sqlcl_snapshot {"hash":"5f9d75dd949a8d6d3ffe7d0ae431b0ecc875f2b4","type":"COMMENT","name":"emk_file_types","schemaName":"emk_data","sxml":""}