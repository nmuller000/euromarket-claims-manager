create or replace force editionable view emk_api.emk_v_file_types (
    mime_type,
    name,
    signature_hex,
    extensions,
    allowed_yn,
    valid_from,
    valid_to,
    row_version
) as
    select
    /**
     * Catalog of file types for the master data page (BR-18, D-72, D-82):
     * the developer maintains type, name, signature and extensions (shown
     * read only); the administrator allows or retires a type
     * (EMK_MASTER_DATA_API.allow_file_type, retire_file_type). allowed_yn =
     * 'Y' if uploads of the type are allowed today; the page offers "Allow"
     * or "Retire" from it. row_version for optimistic locking.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        t.mime_type,
        t.name,
        rawtohex(t.signature)                                                           as signature_hex,
        (
            select
                listagg(e.file_extension, ', ') within group(
                order by
                    e.file_extension
                )
            from
                emk_data.emk_file_extensions e
            where
                e.mime_type = t.mime_type
        )                                                                               as extensions,
        case
            when t.valid_from <= trunc(sysdate)
                 and ( t.valid_to is null
                       or t.valid_to >= trunc(sysdate) ) then
                'Y'
            else
                'N'
        end                                                                             as allowed_yn,
        t.valid_from,
        t.valid_to,
        emk_api.emk_row_version_pkg.format_row_version(nvl(t.updated_at, t.created_at)) as row_version
    from
        emk_data.emk_file_types t;


-- sqlcl_snapshot {"hash":"f971074d9692503d9d596ab31e4f1f3410af57d3","type":"VIEW","name":"EMK_V_FILE_TYPES","schemaName":"EMK_API","sxml":""}