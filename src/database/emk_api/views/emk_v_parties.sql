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
    roles,
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
        p.created_at,
        p.created_by,
        p.updated_at,
        p.updated_by,
        emk_api.emk_row_version_pkg.format_row_version(nvl(p.updated_at, p.created_at)) as row_version
    from
             emk_data.emk_parties p
        join emk_data.emk_countries c on c.country_code = p.country_code
    where
        p.deleted_yn = 'N';


-- sqlcl_snapshot {"hash":"8452b0ae04c3ca8eadd006087141b490e93ed38f","type":"VIEW","name":"EMK_V_PARTIES","schemaName":"EMK_API","sxml":""}