create or replace force editionable view emk_api.emk_v_document_types (
    doc_type,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to
) as
    select
    /**
     * Document types for the APEX lists of values (D-68). valid_yn = 'Y' if
     * the type is valid today: a list offers those, plus the value the
     * document already has.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        doc_type,
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
        end as valid_yn,
        valid_from,
        valid_to
    from
        emk_data.emk_document_types;


-- sqlcl_snapshot {"hash":"111bc2516304a894160a122826af212024380652","type":"VIEW","name":"EMK_V_DOCUMENT_TYPES","schemaName":"EMK_API","sxml":""}