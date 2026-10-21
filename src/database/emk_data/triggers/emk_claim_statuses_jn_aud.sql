create or replace editionable trigger emk_data.emk_claim_statuses_jn_aud after
    update or delete on emk_data.emk_claim_statuses
    for each row
    /**
     * Journal: stores the previous row of EMK_CLAIM_STATUSES in EMK_CLAIM_STATUSES_JN, so that the changes
     * made in the master data pages show who changed what and when (D-72).
     * Every column of the base table must be listed (checked by the tests).
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
declare
    l_operation emk_data.emk_claim_statuses_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_data.emk_claim_statuses_jn (
        jn_operation,
        status_code,
        name,
        description,
        sort_order,
        final_yn,
        valid_from,
        valid_to,
        created_at,
        created_by,
        updated_at,
        updated_by
    ) values ( l_operation,
               :old.status_code,
               :old.name,
               :old.description,
               :old.sort_order,
               :old.final_yn,
               :old.valid_from,
               :old.valid_to,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by );

end;
/

alter trigger emk_data.emk_claim_statuses_jn_aud enable;


-- sqlcl_snapshot {"hash":"99731d1cdfbaffe6f2bc1f3917f2b308354efb34","type":"TRIGGER","name":"EMK_CLAIM_STATUSES_JN_AUD","schemaName":"EMK_DATA","sxml":""}