create or replace editionable trigger emk_data.emk_claim_statuses_bu before
    update on emk_data.emk_claim_statuses
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

alter trigger emk_data.emk_claim_statuses_bu enable;


-- sqlcl_snapshot {"hash":"63ad72c3bb1b99d480f8e8f81924800e64233e86","type":"TRIGGER","name":"EMK_CLAIM_STATUSES_BU","schemaName":"EMK_DATA","sxml":""}