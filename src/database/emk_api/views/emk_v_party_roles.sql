create or replace force editionable view emk_api.emk_v_party_roles (
    party_id,
    role_code,
    party_name,
    country_code,
    role_name,
    valid_yn,
    valid_to
) as
    select
    /**
     * Roles of the active companies, one row per company and role, for the
     * APEX lists of values ("choose the carrier": role_code = 'CARRIER') and
     * for the company form, which shows the roles no longer valid apart from
     * the checkboxes of valid roles (D-86): valid_yn = 'Y' if the role is
     * valid today; valid_to is the last valid day of a retired role.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        r.party_id,
        r.role_code,
        p.name as party_name,
        p.country_code,
        t.name as role_name,
        case
            when t.valid_from <= trunc(sysdate)
                 and ( t.valid_to is null
                       or t.valid_to >= trunc(sysdate) ) then
                'Y'
            else
                'N'
        end    as valid_yn,
        t.valid_to
    from
             emk_data.emk_party_roles r
        join emk_data.emk_parties          p on p.party_id = r.party_id
        join emk_data.emk_party_role_types t on t.role_code = r.role_code
    where
        p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"47891054a47a3dbc1822904a016309380fcb33b2","type":"VIEW","name":"EMK_V_PARTY_ROLES","schemaName":"EMK_API","sxml":""}