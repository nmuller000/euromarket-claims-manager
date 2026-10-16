create or replace editionable trigger emk_data.emk_parties_jn_aud after
    update or delete on emk_data.emk_parties
    for each row
    /**
     * Journal: stores the previous row of EMK_PARTIES in EMK_PARTIES_JN
     * (U = update, D = delete). Every column of the base table must be listed
     * (checked by the tests, D-39). jn_at and jn_by come from the defaults.
     *
     * @author Natalia Müller
     * @since  2026-10-08
     */
declare
    l_operation emk_parties_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_parties_jn (
        jn_operation,
        party_id,
        name,
        vat_number,
        country_code,
        street,
        postal_code,
        city,
        language_code,
        created_at,
        created_by,
        updated_at,
        updated_by,
        deleted_yn,
        deleted_by,
        deleted_at
    ) values ( l_operation,
               :old.party_id,
               :old.name,
               :old.vat_number,
               :old.country_code,
               :old.street,
               :old.postal_code,
               :old.city,
               :old.language_code,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by,
               :old.deleted_yn,
               :old.deleted_by,
               :old.deleted_at );

end;
/

alter trigger emk_data.emk_parties_jn_aud enable;


-- sqlcl_snapshot {"hash":"3b553a08864ae59e1a34b155e6e048c8836d374c","type":"TRIGGER","name":"EMK_PARTIES_JN_AUD","schemaName":"EMK_DATA","sxml":""}