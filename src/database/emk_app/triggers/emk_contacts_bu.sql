create or replace editionable trigger emk_app.emk_contacts_bu before
    update on emk_app.emk_contacts
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

alter trigger emk_app.emk_contacts_bu enable;


-- sqlcl_snapshot {"hash":"2679c4b2d04e12689a1a4b40959b02c68309afc4","type":"TRIGGER","name":"EMK_CONTACTS_BU","schemaName":"EMK_APP","sxml":""}