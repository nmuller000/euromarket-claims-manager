create or replace editionable trigger emk_data.emk_contacts_bu before
    update on emk_data.emk_contacts
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

alter trigger emk_data.emk_contacts_bu enable;


-- sqlcl_snapshot {"hash":"baf9300dfdcc810e59491f3724f744ea14bb7e04","type":"TRIGGER","name":"EMK_CONTACTS_BU","schemaName":"EMK_DATA","sxml":""}