alter table emk_data.emk_file_extensions
    add constraint emk_file_extensions_file_types_fk
        foreign key ( mime_type )
            references emk_data.emk_file_types ( mime_type )
        enable;


-- sqlcl_snapshot {"hash":"cfe4e28b3b596304562a991c169185e0c7a474a6","type":"REF_CONSTRAINT","name":"EMK_FILE_EXTENSIONS_FILE_TYPES_FK","schemaName":"EMK_DATA","sxml":""}