create or replace force editionable view emk_api.emk_v_currencies (
    currency_code,
    name,
    minor_units,
    ecb_rate_yn,
    charges_allowed_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Currencies for the APEX lists of values, with their validity and whether
     * they may be used for carriage charges (EUR or with an ECB rate, BR-12).
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        currency_code,
        name,
        minor_units,
        ecb_rate_yn,
        case
            when currency_code = 'EUR'
                 or ecb_rate_yn = 'Y' then
                'Y'
            else
                'N'
        end as charges_allowed_yn,
        valid_from,
        valid_to
    from
        emk_data.emk_currencies;


-- sqlcl_snapshot {"hash":"ebd92cfd16790b32f5211e901321d3b6810c08ad","type":"VIEW","name":"EMK_V_CURRENCIES","schemaName":"EMK_API","sxml":""}