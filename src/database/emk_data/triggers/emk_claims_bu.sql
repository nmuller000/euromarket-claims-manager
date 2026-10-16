create or replace editionable trigger emk_data.emk_claims_bu before
    update on emk_data.emk_claims
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-09
     */
begin
    :new.updated_at := systimestamp;
    :new.updated_by := coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    );

end;
/

alter trigger emk_data.emk_claims_bu enable;


-- sqlcl_snapshot {"hash":"8bba06bc18e38edd801b6574e00528e0fbac99f0","type":"TRIGGER","name":"EMK_CLAIMS_BU","schemaName":"EMK_DATA","sxml":""}