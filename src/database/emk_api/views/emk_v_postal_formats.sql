create or replace force editionable view emk_api.emk_v_postal_formats (
    country_code,
    postal_code_required_yn,
    postal_code_example,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Postcode rule of each country for the company page (D-90): the page
     * shows the example of the chosen country under the postcode field;
     * EMK_PARTY_API adds the prefix of the official form and checks the
     * pattern. valid_yn = 'Y' if the rule is valid today: the page uses
     * those only (D-86). The pattern itself stays in the API (one place for
     * the rule).
     *
     * @author Natalia Müller
     * @since  2026-10-28
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        country_code,
        postal_code_required_yn,
        postal_code_example,
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
        emk_data.emk_postal_formats;


-- sqlcl_snapshot {"hash":"034bf1710fab10802b18f56f83aa9fc1a79d0ea7","type":"VIEW","name":"EMK_V_POSTAL_FORMATS","schemaName":"EMK_API","sxml":""}