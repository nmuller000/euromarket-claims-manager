create or replace editionable trigger emk_data.emk_countries_bu before
    update on emk_data.emk_countries
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-08
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

alter trigger emk_data.emk_countries_bu enable;


-- sqlcl_snapshot {"hash":"eadc19c613cc6059b5b2575067a584ac02ee4de5","type":"TRIGGER","name":"EMK_COUNTRIES_BU","schemaName":"EMK_DATA","sxml":""}