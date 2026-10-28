create or replace force editionable view emk_api.emk_v_contact_history (
    history_id,
    contact_id,
    party_id,
    changed_at,
    changed_by,
    action,
    previous_full_name,
    previous_email,
    previous_phone
) as
    select
    /**
     * Change history of contact persons (FR-09, D-67): when, who, the action
     * and the former personal data. Shown to the compliance officer only
     * (GDPR Art. 5(1)(c), data minimisation: the claims handler needs the
     * current contact data, not the former ones).
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        j.jn_id     as history_id,
        j.contact_id,
        j.party_id,
        j.jn_at     as changed_at,
        j.jn_by     as changed_by,
        case
            when j.deleted_yn = 'N'
                 and j.next_deleted_yn = 'Y' then
                'DELETED'
            when j.deleted_yn = 'Y'
                 and j.next_deleted_yn = 'N' then
                'RESTORED'
            else
                'UPDATED'
        end         as action,
        j.full_name as previous_full_name,
        j.email     as previous_email,
        j.phone     as previous_phone
    from
        (
            select
                jn.*,
                coalesce(lead(jn.deleted_yn)
                         over(partition by jn.contact_id
                              order by
                                  jn.jn_at, jn.jn_id
                ),
                         c.deleted_yn) as next_deleted_yn
            from
                     emk_data.emk_contacts_jn jn
                join emk_data.emk_contacts c on c.contact_id = jn.contact_id
        ) j;


-- sqlcl_snapshot {"hash":"9731e4e37346b67666a953cf6dc017de226e80c4","type":"VIEW","name":"EMK_V_CONTACT_HISTORY","schemaName":"EMK_API","sxml":""}