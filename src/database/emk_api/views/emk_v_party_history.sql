create or replace force editionable view emk_api.emk_v_party_history (
    history_id,
    party_id,
    changed_at,
    changed_by,
    action,
    previous_name,
    previous_vat_number,
    previous_country_code,
    previous_street,
    previous_postal_code,
    previous_city,
    previous_language_code
) as
    select
    /**
     * Change history of companies (FR-09, D-67): one row per change, with
     * when, who (the APEX user), the action (UPDATED, DELETED, RESTORED) and
     * the values before the change. Shown in the company form to the claims
     * handler, the compliance officer and the administrator.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        j.jn_id         as history_id,
        j.party_id,
        j.jn_at         as changed_at,
        j.jn_by         as changed_by,
        case
            when j.deleted_yn = 'N'
                 and j.next_deleted_yn = 'Y' then
                'DELETED'
            when j.deleted_yn = 'Y'
                 and j.next_deleted_yn = 'N' then
                'RESTORED'
            else
                'UPDATED'
        end             as action,
        j.name          as previous_name,
        j.vat_number    as previous_vat_number,
        j.country_code  as previous_country_code,
        j.street        as previous_street,
        j.postal_code   as previous_postal_code,
        j.city          as previous_city,
        j.language_code as previous_language_code
    from
        (
            select
                jn.*,
                coalesce(lead(jn.deleted_yn)
                         over(partition by jn.party_id
                              order by
                                  jn.jn_at, jn.jn_id
                ),
                         p.deleted_yn) as next_deleted_yn
            from
                     emk_data.emk_parties_jn jn
                join emk_data.emk_parties p on p.party_id = jn.party_id
        ) j;


-- sqlcl_snapshot {"hash":"2a83779acb0140b08b9bec2d377ca0e884d93ab4","type":"VIEW","name":"EMK_V_PARTY_HISTORY","schemaName":"EMK_API","sxml":""}