create or replace editionable trigger emk_data.emk_claim_documents_jn_aud after
    update or delete on emk_data.emk_claim_documents
    for each row
    /**
     * Journal: stores the previous row of EMK_CLAIM_DOCUMENTS in EMK_CLAIM_DOCUMENTS_JN
     * (U = update, D = delete). Content and extracted_text are not
     * journaled (the file is immutable). Every journaled column must be listed
     * (checked by the tests, D-39). jn_at and jn_by come from the defaults.
     *
     * @author Natalia Müller
     * @since  2026-10-09
     */
declare
    l_operation emk_claim_documents_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_claim_documents_jn (
        jn_operation,
        document_id,
        claim_id,
        doc_type,
        file_name,
        mime_type,
        file_size,
        created_at,
        created_by,
        updated_at,
        updated_by,
        deleted_yn,
        deleted_by,
        deleted_at
    ) values ( l_operation,
               :old.document_id,
               :old.claim_id,
               :old.doc_type,
               :old.file_name,
               :old.mime_type,
               :old.file_size,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by,
               :old.deleted_yn,
               :old.deleted_by,
               :old.deleted_at );

end;
/

alter trigger emk_data.emk_claim_documents_jn_aud enable;


-- sqlcl_snapshot {"hash":"24c8634684835011b0f8daf1ed42e23819fbf4c5","type":"TRIGGER","name":"EMK_CLAIM_DOCUMENTS_JN_AUD","schemaName":"EMK_DATA","sxml":""}