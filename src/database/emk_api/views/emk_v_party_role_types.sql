create or replace force editionable view emk_api.emk_v_party_role_types (
    role_code,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Roles a company can play, for the APEX lists of values and checkbox
     * lists (D-68, BR-16). valid_yn = 'Y' if the role is valid today: a list
     * offers those, plus the roles the company already has.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        role_code,
        name,
        description,
        sort_order,
        case
            when valid_from <= trunc(sysdate)
                 and ( valid_to is null
                       or valid_to >= trunc(sysdate) ) then
                'Y'
            else
                'N'
        end as valid_yn,
        valid_from,
        valid_to
    from
        emk_data.emk_party_role_types;


-- sqlcl_snapshot {"hash":"db6837c37ef7045e8a8671ecaaf5a6a9990de540","type":"VIEW","name":"EMK_V_PARTY_ROLE_TYPES","schemaName":"EMK_API","sxml":""}