create or replace editionable trigger emk_data.emk_party_role_types_bu before
    update on emk_data.emk_party_role_types
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

alter trigger emk_data.emk_party_role_types_bu enable;


-- sqlcl_snapshot {"hash":"e129ed51f27a2a1f498779c8402449f6e8da2f3e","type":"TRIGGER","name":"EMK_PARTY_ROLE_TYPES_BU","schemaName":"EMK_DATA","sxml":""}