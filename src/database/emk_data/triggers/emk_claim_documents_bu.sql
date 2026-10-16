create or replace editionable trigger emk_data.emk_claim_documents_bu before
    update on emk_data.emk_claim_documents
    for each row
    /**
     * Audit block and immutable file (D-41): rejects any change of content,
     * file_name, mime_type or file_size, because the journal does not copy the
     * file and a document can be legal evidence (CMR Art. 30). doc_type,
     * extracted_text and the soft-delete columns may change.
     *
     * The error code is a literal because the data schema must not depend on
     * the code schema (ADR-008 §4); it must equal
     * emk_api.emk_errors_pkg.c_document_immutable (checked by a unit test).
     *
     * @throws -20303 file columns changed (emk_errors_pkg.e_document_immutable)
     * @author Natalia Müller
     * @since  2026-10-09
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
begin
    if updating('CONTENT')
    or updating('FILE_NAME')
    or updating('MIME_TYPE')
    or updating('FILE_SIZE') then
        raise_application_error(-20303,  -- emk_errors_pkg.c_document_immutable
         'The file of a claim document cannot be changed; upload a new document instead');
    end if;

    :new.updated_at := systimestamp;
    :new.updated_by := coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    );

end;
/

alter trigger emk_data.emk_claim_documents_bu enable;


-- sqlcl_snapshot {"hash":"be4e0e7e298262374cd2ecb0fadd5456465918b0","type":"TRIGGER","name":"EMK_CLAIM_DOCUMENTS_BU","schemaName":"EMK_DATA","sxml":""}