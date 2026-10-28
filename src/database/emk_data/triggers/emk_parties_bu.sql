create or replace editionable trigger emk_data.emk_parties_bu before
    update on emk_data.emk_parties
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

alter trigger emk_data.emk_parties_bu enable;


-- sqlcl_snapshot {"hash":"aa3bdce9694e7659b43078cfd01806aaf2f7cb7c","type":"TRIGGER","name":"EMK_PARTIES_BU","schemaName":"EMK_DATA","sxml":""}