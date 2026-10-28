create or replace editionable trigger emk_data.emk_vat_formats_bu before
    update on emk_data.emk_vat_formats
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-25
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
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

alter trigger emk_data.emk_vat_formats_bu enable;


-- sqlcl_snapshot {"hash":"0f9e4b40c12b3ac7df9913a546e9eff8ac7dbc4d","type":"TRIGGER","name":"EMK_VAT_FORMATS_BU","schemaName":"EMK_DATA","sxml":""}