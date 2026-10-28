create or replace editionable trigger emk_data.emk_claim_types_bu before
    update on emk_data.emk_claim_types
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

alter trigger emk_data.emk_claim_types_bu enable;


-- sqlcl_snapshot {"hash":"04553724a031c3ea7983a80f2e323403b3cde6ea","type":"TRIGGER","name":"EMK_CLAIM_TYPES_BU","schemaName":"EMK_DATA","sxml":""}