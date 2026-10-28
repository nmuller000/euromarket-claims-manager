alter table emk_data.emk_claim_documents
    add constraint emk_claim_documents_doc_types_fk
        foreign key ( doc_type )
            references emk_data.emk_document_types ( doc_type )
        enable;


-- sqlcl_snapshot {"hash":"31fcbb50270634f08d1810ce98f3041c0f532d34","type":"REF_CONSTRAINT","name":"EMK_CLAIM_DOCUMENTS_DOC_TYPES_FK","schemaName":"EMK_DATA","sxml":""}