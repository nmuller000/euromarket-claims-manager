create or replace force editionable view emk_api.emk_v_countries (
    country_code,
    name,
    iso_name,
    eu_member_yn,
    cmr_party_since,
    valid_from,
    valid_to
) as
    select
    /**
     * Countries for the APEX lists of values, with their validity and the
     * date from which each is a CMR party: a page filters by the date of taking over
     * (a shipment is checked on its date of taking over, D-64).
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        country_code,
        name,
        iso_name,
        eu_member_yn,
        cmr_party_since,
        valid_from,
        valid_to
    from
        emk_data.emk_countries;


-- sqlcl_snapshot {"hash":"3f8b93567db39d3b0d661213b28c2d6a5c0f93ce","type":"VIEW","name":"EMK_V_COUNTRIES","schemaName":"EMK_API","sxml":""}