create or replace editionable trigger emk_data.emk_languages_bu before
    update on emk_data.emk_languages
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-18
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

alter trigger emk_data.emk_languages_bu enable;


-- sqlcl_snapshot {"hash":"876ed776dca0a0e0da429d559d4781d4c5706965","type":"TRIGGER","name":"EMK_LANGUAGES_BU","schemaName":"EMK_DATA","sxml":""}