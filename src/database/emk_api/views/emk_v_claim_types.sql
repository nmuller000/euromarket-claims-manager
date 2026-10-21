create or replace force editionable view emk_api.emk_v_claim_types (
    claim_type,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to,
    row_version
) as
    select
    /**
     * Claim types for the APEX lists of values (D-68). valid_yn = 'Y' if the
     * type is valid today: a list offers those, plus the value the claim
     * already has.
     * The master data pages read it too (D-82): row_version for optimistic
     * locking (EMK_ROW_VERSION_PKG.format_row_version).
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
        end                                                                         as valid_yn,
        valid_from,
        valid_to,
        emk_api.emk_row_version_pkg.format_row_version(nvl(updated_at, created_at)) as row_version
    from
        emk_data.emk_claim_types;


-- sqlcl_snapshot {"hash":"766674029192efa8caeaee4a69d31adb6c5cb02f","type":"VIEW","name":"EMK_V_CLAIM_TYPES","schemaName":"EMK_API","sxml":""}