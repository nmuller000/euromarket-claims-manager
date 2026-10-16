create or replace editionable trigger emk_data.emk_shipments_bu before
    update on emk_data.emk_shipments
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

alter trigger emk_data.emk_shipments_bu enable;


-- sqlcl_snapshot {"hash":"788194f0258e7183cac33caf9eb1f91bd347df0b","type":"TRIGGER","name":"EMK_SHIPMENTS_BU","schemaName":"EMK_DATA","sxml":""}