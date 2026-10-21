create or replace force editionable view emk_api.emk_v_claim_types (
    claim_type,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Claim types for the APEX lists of values (D-68). valid_yn = 'Y' if the
     * type is valid today: a list offers those, plus the value the claim
     * already has.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        claim_type,
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
        emk_data.emk_claim_types;


-- sqlcl_snapshot {"hash":"9ba5f52b2133c1ba3a8cdab87bb3b66148d9d97c","type":"VIEW","name":"EMK_V_CLAIM_TYPES","schemaName":"EMK_API","sxml":""}