create or replace force editionable view emk_api.emk_v_document_types (
    doc_type,
    name,
    description,
    sort_order,
    valid_yn,
    valid_from,
    valid_to,
    row_version
) as
    select
    /**
     * Document types for the APEX lists of values (D-68). valid_yn = 'Y' if
     * the type is valid today: a list offers those, plus the value the
     * document already has.
     * The master data pages read it too (D-82): row_version for optimistic
     * locking (EMK_ROW_VERSION_PKG.format_row_version).
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
        end                                                                         as valid_yn,
        valid_from,
        valid_to,
        emk_api.emk_row_version_pkg.format_row_version(nvl(updated_at, created_at)) as row_version
    from
        emk_data.emk_document_types;


-- sqlcl_snapshot {"hash":"523b7a70db02ddbb364f3faef6ee5ff3093156e0","type":"VIEW","name":"EMK_V_DOCUMENT_TYPES","schemaName":"EMK_API","sxml":""}