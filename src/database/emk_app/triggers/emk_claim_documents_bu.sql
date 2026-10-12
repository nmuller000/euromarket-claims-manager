create or replace editionable trigger emk_app.emk_claim_documents_bu before
    update on emk_app.emk_claim_documents
    for each row
    /**
     * Audit block and immutable file (D-41): rejects any change of content,
     * file_name, mime_type or file_size, because the journal does not copy the
     * file and a document can be legal evidence (CMR Art. 30). doc_type,
     * extracted_text and the soft-delete columns may change.
     *
     * @throws emk_errors.e_document_immutable file columns changed
     * @author Natalia Müller
     * @since  2026-10-09
     */
begin
    if updating('CONTENT')
    or updating('FILE_NAME')
    or updating('MIME_TYPE')
    or updating('FILE_SIZE') then
        raise_application_error(emk_errors.c_document_immutable, 'The file of a claim document cannot be changed; upload a new document instead'
        );
    end if;

    :new.updated_at := systimestamp;
    :new.updated_by := coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    );

end;
/

alter trigger emk_app.emk_claim_documents_bu enable;


-- sqlcl_snapshot {"hash":"ea0faca67182f115e76760bdbe65396cba571025","type":"TRIGGER","name":"EMK_CLAIM_DOCUMENTS_BU","schemaName":"EMK_APP","sxml":""}