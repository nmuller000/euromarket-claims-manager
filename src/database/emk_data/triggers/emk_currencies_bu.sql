create or replace editionable trigger emk_data.emk_currencies_bu before
    update on emk_data.emk_currencies
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

alter trigger emk_data.emk_currencies_bu enable;


-- sqlcl_snapshot {"hash":"8fa4cf93cf19142968dbbb411008b9f287943ca3","type":"TRIGGER","name":"EMK_CURRENCIES_BU","schemaName":"EMK_DATA","sxml":""}