create or replace editionable trigger emk_data.emk_postal_formats_bu before
    update on emk_data.emk_postal_formats
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-28
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

alter trigger emk_data.emk_postal_formats_bu enable;


-- sqlcl_snapshot {"hash":"18fd4d7cef57a740ce19087463e11dcca55c8116","type":"TRIGGER","name":"EMK_POSTAL_FORMATS_BU","schemaName":"EMK_DATA","sxml":""}