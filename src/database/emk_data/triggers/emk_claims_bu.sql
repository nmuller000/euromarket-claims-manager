create or replace editionable trigger emk_data.emk_claims_bu before
    update on emk_data.emk_claims
    for each row
    /**
     * Audit block: sets updated_at and updated_by (docs/design/README.md).
     *
     * @author Natalia Müller
     * @since  2026-10-09
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

alter trigger emk_data.emk_claims_bu enable;


-- sqlcl_snapshot {"hash":"cd39845338dd286f87de736d1cdcce3b836fb52c","type":"TRIGGER","name":"EMK_CLAIMS_BU","schemaName":"EMK_DATA","sxml":""}