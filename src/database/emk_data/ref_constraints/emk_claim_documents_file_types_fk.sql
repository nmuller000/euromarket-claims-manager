alter table emk_data.emk_claim_documents
    add constraint emk_claim_documents_file_types_fk
        foreign key ( mime_type )
            references emk_data.emk_file_types ( mime_type )
        enable;


-- sqlcl_snapshot {"hash":"7e41750f3c1eda295368121afe19af4da8041b9f","type":"REF_CONSTRAINT","name":"EMK_CLAIM_DOCUMENTS_FILE_TYPES_FK","schemaName":"EMK_DATA","sxml":""}