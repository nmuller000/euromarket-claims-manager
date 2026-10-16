create or replace editionable trigger emk_data.emk_parties_bu before
    update on emk_data.emk_parties
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-08
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

alter trigger emk_data.emk_parties_bu enable;


-- sqlcl_snapshot {"hash":"9c0777ae4c544b3c93cc3bd69adcad81b73e8a35","type":"TRIGGER","name":"EMK_PARTIES_BU","schemaName":"EMK_DATA","sxml":""}