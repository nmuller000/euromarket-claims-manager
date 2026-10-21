create or replace force editionable view emk_api.emk_v_code_list_history (
    list_name,
    history_id,
    code,
    changed_at,
    changed_by,
    previous_name,
    previous_description,
    previous_sort_order,
    previous_valid_from,
    previous_valid_to
) as
    select
    /**
     * Change history of the code lists the administrator maintains (D-82,
     * spec §7.1): when, who and the values before each change, from the
     * journals <TABLE>_JN. Shown in the master data pages to the
     * administrator. Values are never deleted, so every row is an update.
     * A row is identified by list_name and history_id together.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        'PARTY_ROLE_TYPES' as list_name,
        j.jn_id            as history_id,
        j.role_code        as code,
        j.jn_at            as changed_at,
        j.jn_by            as changed_by,
        j.name             as previous_name,
        j.description      as previous_description,
        j.sort_order       as previous_sort_order,
        j.valid_from       as previous_valid_from,
        j.valid_to         as previous_valid_to
    from
        emk_data.emk_party_role_types_jn j
    union all
    select
        'CLAIM_STATUSES',
        j.jn_id,
        j.status_code,
        j.jn_at,
        j.jn_by,
        j.name,
        j.description,
        j.sort_order,
        j.valid_from,
        j.valid_to
    from
        emk_data.emk_claim_statuses_jn j
    union all
    select
        'CLAIM_TYPES',
        j.jn_id,
        j.claim_type,
        j.jn_at,
        j.jn_by,
        j.name,
        j.description,
        j.sort_order,
        j.valid_from,
        j.valid_to
    from
        emk_data.emk_claim_types_jn j
    union all
    select
        'DOCUMENT_TYPES',
        j.jn_id,
        j.doc_type,
        j.jn_at,
        j.jn_by,
        j.name,
        j.description,
        j.sort_order,
        j.valid_from,
        j.valid_to
    from
        emk_data.emk_document_types_jn j
    union all
    select
        'FILE_TYPES',
        j.jn_id,
        j.mime_type,
        j.jn_at,
        j.jn_by,
        j.name,
        null,
        null,
        j.valid_from,
        j.valid_to
    from
        emk_data.emk_file_types_jn j;


-- sqlcl_snapshot {"hash":"e8963b3c636acb80ab8834bf69b335325590de17","type":"VIEW","name":"EMK_V_CODE_LIST_HISTORY","schemaName":"EMK_API","sxml":""}