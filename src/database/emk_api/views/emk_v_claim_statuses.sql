create or replace force editionable view emk_api.emk_v_claim_statuses (
    status_code,
    name,
    description,
    sort_order,
    final_yn,
    valid_yn,
    valid_from,
    valid_to,
    row_version
) as
    select
    /**
     * Claim statuses for the APEX lists of values and filters (D-68, spec §4).
     * final_yn = 'Y' for the final statuses (open claims are those with 'N').
     * valid_yn = 'Y' if the status is valid today. Which status may follow
     * which is decided by EMK_CLAIM_API (BR-01), not by this list.
     * The master data pages read it too (D-82): row_version for optimistic
     * locking (EMK_ROW_VERSION_PKG.format_row_version).
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        status_code,
        name,
        description,
        sort_order,
        final_yn,
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
        emk_data.emk_claim_statuses;


-- sqlcl_snapshot {"hash":"f128448a2b4ae6daa79b657bec1363aee4927efc","type":"VIEW","name":"EMK_V_CLAIM_STATUSES","schemaName":"EMK_API","sxml":""}