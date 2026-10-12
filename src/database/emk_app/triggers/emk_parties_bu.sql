create or replace editionable trigger emk_app.emk_parties_bu before
    update on emk_app.emk_parties
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

alter trigger emk_app.emk_parties_bu enable;


-- sqlcl_snapshot {"hash":"2c2abaebc7a0468e82952d2a6196857472e9176b","type":"TRIGGER","name":"EMK_PARTIES_BU","schemaName":"EMK_APP","sxml":""}