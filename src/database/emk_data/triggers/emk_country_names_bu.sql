create or replace editionable trigger emk_data.emk_country_names_bu before
    update on emk_data.emk_country_names
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

alter trigger emk_data.emk_country_names_bu enable;


-- sqlcl_snapshot {"hash":"e04721f07b8604bfd21d58591919fd8b14e50cd4","type":"TRIGGER","name":"EMK_COUNTRY_NAMES_BU","schemaName":"EMK_DATA","sxml":""}