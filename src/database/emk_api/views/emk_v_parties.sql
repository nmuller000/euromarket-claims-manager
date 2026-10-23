create or replace force editionable view emk_api.emk_v_parties (
    party_id,
    name,
    vat_number,
    country_code,
    country_name,
    street,
    postal_code,
    city,
    language_code,
    language_name,
    country_valid_yn,
    language_valid_yn,
    roles,
    roles_in_use,
    deletable_yn,
    created_at,
    created_by,
    updated_at,
    updated_by,
    row_version
) as
    select
    /**
     * Active companies for the APEX pages (step 7.4, D-66): every column of
     * the company, the English country name, its roles as one colon-separated
     * value (the format of an APEX checkbox item) and row_version, the version
     * for optimistic locking as text (EMK_ROW_VERSION_PKG.format_row_version).
     * country_valid_yn and language_valid_yn = 'N' when the value of the
     * company is no longer valid today: the form offers valid values only and
     * asks the user to choose another one (D-86).
     * The company page shows the rules before the user saves (step 7.8):
     * roles_in_use, the roles a shipment uses (they cannot be removed), and
     * deletable_yn = 'Y' if no active shipment uses the company; both come
     * from EMK_PARTY_API, which applies the same rules.
     * Changes go through EMK_PARTY_API.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        p.party_id,
        p.name,
        p.vat_number,
        p.country_code,
        c.name                                                                          as country_name,
        p.street,
        p.postal_code,
        p.city,
        p.language_code,
        l.name                                                                          as language_name,
        case
            when c.valid_from <= trunc(sysdate)
                 and ( c.valid_to is null
                       or c.valid_to >= trunc(sysdate) ) then
                'Y'
            else
                'N'
        end                                                                             as country_valid_yn,
        case
            when l.valid_from <= trunc(sysdate)
                 and ( l.valid_to is null
                       or l.valid_to >= trunc(sysdate) ) then
                'Y'
            else
                'N'
        end                                                                             as language_valid_yn,
        (
            select
                listagg(r.role_code, ':') within group(
                order by
                    r.role_code
                )
            from
                emk_data.emk_party_roles r
            where
                r.party_id = p.party_id
        )                                                                               as roles,
        emk_api.emk_party_api.get_roles_in_use(p.party_id)                              as roles_in_use,
        case
            when emk_api.emk_party_api.is_deletable(p.party_id) then
                'Y'
            else
                'N'
        end                                                                             as deletable_yn,
        p.created_at,
        p.created_by,
        p.updated_at,
        p.updated_by,
        emk_api.emk_row_version_pkg.format_row_version(nvl(p.updated_at, p.created_at)) as row_version
    from
             emk_data.emk_parties p
        join emk_data.emk_countries c on c.country_code = p.country_code
        join emk_data.emk_languages l on l.language_code = p.language_code
    where
        p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"9fc1a18264db0d5f651749ec0990da59787d1a52","type":"VIEW","name":"EMK_V_PARTIES","schemaName":"EMK_API","sxml":""}