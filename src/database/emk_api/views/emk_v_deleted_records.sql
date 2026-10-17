create or replace force editionable view emk_api.emk_v_deleted_records (
    entity,
    record_id,
    description,
    restorable_yn,
    deleted_by,
    deleted_at
) as
    select
    /**
     * Soft-deleted companies, contacts and shipments for the restore page
     * (D-66): one page lists them and its Restore button calls the API of the
     * entity. restorable_yn = 'N' for a contact whose company is deleted
     * (restore the company first).
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        'PARTY'    as entity,
        p.party_id as record_id,
        p.name     as description,
        'Y'        as restorable_yn,
        p.deleted_by,
        p.deleted_at
    from
        emk_data.emk_parties p
    where
        p.deleted_yn = 'Y'
    union all
    select
        'CONTACT',
        c.contact_id,
        c.full_name
        || ' ('
        || p.name
        || ')',
        case p.deleted_yn
            when 'N' then
                'Y'
            else
                'N'
        end,
        c.deleted_by,
        c.deleted_at
    from
             emk_data.emk_contacts c
        join emk_data.emk_parties p on p.party_id = c.party_id
    where
        c.deleted_yn = 'Y'
    union all
    select
        'SHIPMENT',
        s.shipment_id,
        s.cmr_note_no
        || ' ('
        || ca.name
        || ')',
        'Y',
        s.deleted_by,
        s.deleted_at
    from
             emk_data.emk_shipments s
        join emk_data.emk_parties ca on ca.party_id = s.carrier_id
    where
        s.deleted_yn = 'Y';


-- sqlcl_snapshot {"hash":"5cd2e0b1ede060cac9fcac0f78fbb628132a620b","type":"VIEW","name":"EMK_V_DELETED_RECORDS","schemaName":"EMK_API","sxml":""}