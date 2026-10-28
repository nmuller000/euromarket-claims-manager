create or replace force editionable view emk_api.emk_v_party_role_types (
    role_code,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to,
    row_version,
    protected_yn
) as
    select
    /**
     * Roles a company can play, for the APEX lists of values and checkbox
     * lists (D-68, BR-16). valid_yn = 'Y' if the role is valid today: a list
     * offers those only; the retired roles a company keeps are shown apart
     * (EMK_V_PARTY_ROLES.valid_yn, D-86).
     * The master data pages read it too (D-82): row_version for optimistic
     * locking (EMK_ROW_VERSION_PKG.format_row_version); protected_yn = 'Y'
     * for a role named by the rules (EMK_CODES_PKG.is_protected_role): the
     * page shows its end of validity disabled, with the reason.
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
        end                                                                         as valid_yn,
        valid_from,
        valid_to,
        emk_api.emk_row_version_pkg.format_row_version(nvl(updated_at, created_at)) as row_version,
        case
            when emk_api.emk_codes_pkg.is_protected_role(role_code) then
                'Y'
            else
                'N'
        end                                                                         as protected_yn
    from
        emk_data.emk_party_role_types;


-- sqlcl_snapshot {"hash":"de911a027758bf28183561aea2392d9d06f26be3","type":"VIEW","name":"EMK_V_PARTY_ROLE_TYPES","schemaName":"EMK_API","sxml":""}