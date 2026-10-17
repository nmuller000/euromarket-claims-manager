create or replace force editionable view emk_api.emk_v_contacts (
    contact_id,
    party_id,
    party_name,
    full_name,
    email,
    phone,
    created_at,
    created_by,
    updated_at,
    updated_by,
    row_version
) as
    select
    /**
     * Active contact persons of active companies (personal data) and
     * row_version for optimistic locking. Changes go through EMK_PARTY_API.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        c.contact_id,
        c.party_id,
        p.name as party_name,
        c.full_name,
        c.email,
        c.phone,
        c.created_at,
        c.created_by,
        c.updated_at,
        c.updated_by,
        to_char(
            nvl(c.updated_at, c.created_at),
            'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM'
        )      as row_version
    from
             emk_data.emk_contacts c
        join emk_data.emk_parties p on p.party_id = c.party_id
    where
            c.deleted_yn = 'N'
        and p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"b0a80f7d13cd576fde6234a2d4ab2f130a43f6e9","type":"VIEW","name":"EMK_V_CONTACTS","schemaName":"EMK_API","sxml":""}