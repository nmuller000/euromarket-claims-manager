create or replace editionable trigger emk_data.emk_exchange_rates_bu before
    update on emk_data.emk_exchange_rates
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md);
     * an update is an ECB correction of a published rate.
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

alter trigger emk_data.emk_exchange_rates_bu enable;


-- sqlcl_snapshot {"hash":"ef9e68996c8cea5493d907931634c09083aec81d","type":"TRIGGER","name":"EMK_EXCHANGE_RATES_BU","schemaName":"EMK_DATA","sxml":""}