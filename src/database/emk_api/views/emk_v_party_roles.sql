create or replace force editionable view emk_api.emk_v_party_roles (
    party_id,
    role_code,
    party_name,
    country_code
) as
    select
    /**
     * Roles of the active companies, one row per company and role, for the
     * APEX lists of values ("choose the carrier": role_code = 'CARRIER').
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        r.party_id,
        r.role_code,
        p.name as party_name,
        p.country_code
    from
             emk_data.emk_party_roles r
        join emk_data.emk_parties p on p.party_id = r.party_id
    where
        p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"9256ab05a4808408f7446d21f3c3dcb90dba1890","type":"VIEW","name":"EMK_V_PARTY_ROLES","schemaName":"EMK_API","sxml":""}