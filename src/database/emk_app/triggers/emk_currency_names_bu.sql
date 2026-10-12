create or replace editionable trigger emk_app.emk_currency_names_bu before
    update on emk_app.emk_currency_names
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

alter trigger emk_app.emk_currency_names_bu enable;


-- sqlcl_snapshot {"hash":"74456a2cf85b21d2689cdb2bc396b6f9c630b78c","type":"TRIGGER","name":"EMK_CURRENCY_NAMES_BU","schemaName":"EMK_APP","sxml":""}