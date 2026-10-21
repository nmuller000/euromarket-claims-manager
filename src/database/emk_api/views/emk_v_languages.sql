create or replace force editionable view emk_api.emk_v_languages (
    language_code,
    name,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Languages for the APEX lists of values (D-68). valid_yn = 'Y' if the
     * language is valid today: a list offers those, plus the value the record
     * already has (a retired value stays on old records).
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        language_code,
        name,
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
        emk_data.emk_languages;


-- sqlcl_snapshot {"hash":"89cfcc1f447f2acb16c04481a490b7af0cd3c9a2","type":"VIEW","name":"EMK_V_LANGUAGES","schemaName":"EMK_API","sxml":""}