create or replace editionable trigger emk_data.emk_file_types_jn_aud after
    update or delete on emk_data.emk_file_types
    for each row
    /**
     * Journal: stores the previous row of EMK_FILE_TYPES in EMK_FILE_TYPES_JN, so that the changes
     * made in the master data pages show who changed what and when (D-72).
     * Every column of the base table must be listed (checked by the tests).
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
declare
    l_operation emk_data.emk_file_types_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_data.emk_file_types_jn (
        jn_operation,
        mime_type,
        name,
        signature,
        valid_from,
        valid_to,
        created_at,
        created_by,
        updated_at,
        updated_by
    ) values ( l_operation,
               :old.mime_type,
               :old.name,
               :old.signature,
               :old.valid_from,
               :old.valid_to,
               :old.created_at,
               :old.created_by,
               :old.updated_at,
               :old.updated_by );

end;
/

alter trigger emk_data.emk_file_types_jn_aud enable;


-- sqlcl_snapshot {"hash":"caa8487ca8406b9dc86553f83755a3bffc865b93","type":"TRIGGER","name":"EMK_FILE_TYPES_JN_AUD","schemaName":"EMK_DATA","sxml":""}