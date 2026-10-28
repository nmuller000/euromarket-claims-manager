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
        p.name                                                                          as party_name,
        c.full_name,
        c.email,
        c.phone,
        c.created_at,
        c.created_by,
        c.updated_at,
        c.updated_by,
        emk_api.emk_row_version_pkg.format_row_version(nvl(c.updated_at, c.created_at)) as row_version
    from
             emk_data.emk_contacts c
        join emk_data.emk_parties p on p.party_id = c.party_id
    where
            c.deleted_yn = 'N'
        and p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"43e8bcd97736692dc4709090886d3c6762d46377","type":"VIEW","name":"EMK_V_CONTACTS","schemaName":"EMK_API","sxml":""}