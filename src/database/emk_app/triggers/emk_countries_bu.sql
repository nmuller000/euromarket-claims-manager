create or replace editionable trigger emk_app.emk_countries_bu before
    update on emk_app.emk_countries
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

alter trigger emk_app.emk_countries_bu enable;


-- sqlcl_snapshot {"hash":"c198e0522bd86126c8be9f3f68c5033b567cfb67","type":"TRIGGER","name":"EMK_COUNTRIES_BU","schemaName":"EMK_APP","sxml":""}