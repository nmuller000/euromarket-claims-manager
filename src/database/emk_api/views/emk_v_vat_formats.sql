create or replace force editionable view emk_api.emk_v_vat_formats (
    vat_prefix,
    country_code,
    national_example,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * VAT prefix and example of each country for the company page (D-88): the
     * page shows the prefix next to the VAT number field and the example in
     * its help, and the user types only the national part; EMK_PARTY_API
     * adds the prefix and checks the format. valid_yn = 'Y' if the prefix is
     * valid today: the page uses those only (D-86). The format itself stays
     * in the API (one place for the rule).
     *
     * @author Natalia Müller
     * @since  2026-10-25
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        vat_prefix,
        country_code,
        national_example,
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
        emk_data.emk_vat_formats;


-- sqlcl_snapshot {"hash":"9e4429cc42993efc0c608f8b113c00d7be491cd9","type":"VIEW","name":"EMK_V_VAT_FORMATS","schemaName":"EMK_API","sxml":""}