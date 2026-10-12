create or replace editionable trigger emk_app.emk_party_roles_jn_aud after
    update or delete on emk_app.emk_party_roles
    for each row
    /**
     * Journal: stores the previous row of EMK_PARTY_ROLES in EMK_PARTY_ROLES_JN
     * (normally D: roles are deleted, never updated). Every column of the base
     * table must be listed (checked by the tests, D-39).
     *
     * @author Natalia Müller
     * @since  2026-10-08
     */
declare
    l_operation emk_party_roles_jn.jn_operation%type;
begin
    l_operation :=
        case
            when updating then
                'U'
            else
                'D'
        end;
    insert into emk_party_roles_jn (
        jn_operation,
        party_id,
        role_code,
        created_at,
        created_by
    ) values ( l_operation,
               :old.party_id,
               :old.role_code,
               :old.created_at,
               :old.created_by );

end;
/

alter trigger emk_app.emk_party_roles_jn_aud enable;


-- sqlcl_snapshot {"hash":"0ef25e56e0ea3ff7d1b8de34ff9216415d0d8ee6","type":"TRIGGER","name":"EMK_PARTY_ROLES_JN_AUD","schemaName":"EMK_APP","sxml":""}