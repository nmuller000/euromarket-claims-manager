create or replace editionable trigger emk_app.emk_contacts_jn_aud after
    update or delete on emk_app.emk_contacts
    for each row
    /**
     * Journal: stores the previous row of EMK_CONTACTS in EMK_CONTACTS_JN
     * (U = update, D = delete). Personal data. Every column of the base table
     * must be listed (checked by the tests, D-39).
     *
     * @author Natalia Müller
     * @since  2026-10-08
     */
declare
    l_operation emk_contacts_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_contacts_jn (
        jn_operation,
        contact_id,
        party_id,
        full_name,
        email,
        phone,
        created_at,
        created_by,
        updated_at,
        updated_by,
        deleted_yn,
        deleted_by,
        deleted_at
    ) values ( l_operation,
               :old.contact_id,
               :old.party_id,
               :old.full_name,
               :old.email,
               :old.phone,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by,
               :old.deleted_yn,
               :old.deleted_by,
               :old.deleted_at );

end;
/

alter trigger emk_app.emk_contacts_jn_aud enable;


-- sqlcl_snapshot {"hash":"f110cdd3dedbedc5b7c144ae84780fdc1be8a2fb","type":"TRIGGER","name":"EMK_CONTACTS_JN_AUD","schemaName":"EMK_APP","sxml":""}