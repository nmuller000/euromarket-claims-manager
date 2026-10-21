comment on table emk_data.emk_file_extensions is
    'File name extensions of each file type in the catalog (BR-18); technical, added by developers; a type is retired in EMK_FILE_TYPES'
    ;

comment on column emk_data.emk_file_extensions.file_extension is
    'Extension after the last dot of the file name, lower case, without the dot';

comment on column emk_data.emk_file_extensions.mime_type is
    'File type of the extension; the content must start with its signature';


-- sqlcl_snapshot {"hash":"5ba4b72d7fef58bc8cd137599e4bc341d26a6a7e","type":"COMMENT","name":"emk_file_extensions","schemaName":"emk_data","sxml":""}