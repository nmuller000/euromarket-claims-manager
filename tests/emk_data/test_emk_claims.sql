create or replace package test_emk_claims as
    /**
     * Unit tests of the claims area in EMK_DATA: claims, claim documents and
     * status history (M1a step 5). Rules: BR-11 (amounts), D-41 (immutable
     * document file, error -20303), claim number format (BR-04), journals.
     * Statuses, types and file types are code lists (D-68): an unknown value
     * is rejected by the foreign key (ORA-02291).
     * Every test runs on its own data, created before the test and rolled back
     * after it by utPLSQL.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Claims, documents and status history (EMK_DATA))
    --%suitepath(emk_data)

    --%beforeeach
    procedure create_test_claim;

    --%test(A new claim starts as DRAFT)
    procedure starts_as_draft;

    --%test(An update writes the previous row to the claim journal)
    procedure keeps_previous_row_in_journal;

    --%test(BR-11: settled amount above claimed amount is rejected)
    --%throws(-2290)
    procedure rejects_settled_above_claimed;

    --%test(BR-11: recovered amount above settled amount is rejected)
    --%throws(-2290)
    procedure rejects_recovered_above_settled;

    --%test(BR-11: amounts without a currency are rejected)
    --%throws(-2290)
    procedure rejects_amounts_without_currency;

    --%test(BR-04: claim number must follow CLM-YYYY-NNNNNN)
    --%throws(-2290)
    procedure rejects_malformed_claim_number;

    --%test(D-68: an unknown status is rejected by the foreign key to the status list)
    --%throws(-2291)
    procedure rejects_unknown_status;

    --%test(D-41: the file content of a document cannot change)
    --%throws(-20303)
    procedure rejects_new_document_content;

    --%test(D-41: the file name of a document cannot change)
    --%throws(-20303)
    procedure rejects_new_document_file_name;

    --%test(D-41: document type and extracted text may change; the journal keeps the old type)
    procedure accepts_new_document_metadata;

    --%test(D-68, BR-18: a file type outside the allowlist is rejected by the foreign key)
    --%throws(-2291)
    procedure rejects_other_mime_type;

    --%test(D-68: the status history rejects an unknown status)
    --%throws(-2291)
    procedure rejects_unknown_history_status;

    --%test(D-68: an unknown claim type is rejected by the foreign key to the type list)
    --%throws(-2291)
    procedure rejects_unknown_claim_type;

    --%test(D-68: an unknown document type is rejected by the foreign key to the type list)
    --%throws(-2291)
    procedure rejects_unknown_document_type;

    --%test(CMR Art. 30(1): a damage claim needs the apparent-damage flag)
    --%throws(-2290)
    procedure rejects_damage_without_apparent_flag;

    --%test(CMR Art. 30(1): a total loss claim has no apparent-damage flag)
    --%throws(-2290)
    procedure rejects_apparent_flag_for_total_loss;
end test_emk_claims;
/

create or replace package body test_emk_claims as

    g_claim_id    emk_claims.claim_id%type;
    g_document_id emk_claim_documents.document_id%type;

    procedure create_test_claim is
        l_shipper   emk_parties.party_id%type;
        l_carrier   emk_parties.party_id%type;
        l_consignee emk_parties.party_id%type;
        l_shipment  emk_shipments.shipment_id%type;
    begin
        insert into emk_parties (name, country_code, language_code) values ('Test Shipper', 'DE', 'en') returning party_id into l_shipper;
        insert into emk_parties (name, country_code, language_code) values ('Test Carrier', 'PL', 'en') returning party_id into l_carrier;
        insert into emk_parties (name, country_code, language_code) values ('Test Consignee', 'FR', 'en') returning party_id into l_consignee;

        insert into emk_shipments (cmr_note_no, shipper_id, carrier_id, consignee_id, pickup_place, origin_country,
                                   delivery_place, destination_country, pickup_date, delivery_date,
                                   goods_description, gross_weight_kg, cmr_note_date)
        values ('CMR-TEST-CLAIMS', l_shipper, l_carrier, l_consignee, 'Berlin', 'DE', 'Paris', 'FR',
                date '2026-09-01', date '2026-09-03', 'Goods', 1000, date '2026-09-01')
        returning shipment_id into l_shipment;

        insert into emk_claims (claim_no, shipment_id, claim_type, damage_apparent_yn, handler, registration_date,
                                written_claim_date, claimed_amount, settled_amount, recovered_amount,
                                currency_code, description)
        values ('CLM-2026-999001', l_shipment, 'DAMAGE', 'Y', 'TEST_HANDLER', date '2026-09-05',
                date '2026-09-10', 5000, 3000, 1000, 'EUR', 'Damaged machine parts')
        returning claim_id into g_claim_id;

        insert into emk_claim_documents (claim_id, doc_type, file_name, mime_type, file_size, content)
        values (g_claim_id, 'PHOTO', 'damage.png', 'image/png', 4, to_blob(utl_raw.cast_to_raw('test')))
        returning document_id into g_document_id;
    end create_test_claim;

    procedure starts_as_draft is
        l_status emk_claims.status%type;
    begin
        select status into l_status from emk_claims where claim_id = g_claim_id;
        ut.expect(l_status).to_equal('DRAFT');
    end starts_as_draft;

    procedure keeps_previous_row_in_journal is
        l_count pls_integer;
    begin
        update emk_claims set status = 'SUBMITTED' where claim_id = g_claim_id;

        select count(*) into l_count
        from   emk_claims_jn
        where  claim_id = g_claim_id and jn_operation = 'U' and status = 'DRAFT'
        and    claimed_amount = 5000 and claim_no = 'CLM-2026-999001';
        ut.expect(l_count).to_equal(1);
    end keeps_previous_row_in_journal;

    procedure rejects_settled_above_claimed is
    begin
        update emk_claims set settled_amount = 6000 where claim_id = g_claim_id;
    end rejects_settled_above_claimed;

    procedure rejects_recovered_above_settled is
    begin
        update emk_claims set recovered_amount = 3500 where claim_id = g_claim_id;
    end rejects_recovered_above_settled;

    procedure rejects_amounts_without_currency is
    begin
        update emk_claims set currency_code = null where claim_id = g_claim_id;
    end rejects_amounts_without_currency;

    procedure rejects_malformed_claim_number is
    begin
        update emk_claims set claim_no = 'CLM-26-1' where claim_id = g_claim_id;
    end rejects_malformed_claim_number;

    procedure rejects_unknown_status is
    begin
        update emk_claims set status = 'CLOSED' where claim_id = g_claim_id;
    end rejects_unknown_status;

    procedure rejects_new_document_content is
    begin
        update emk_claim_documents set content = to_blob(utl_raw.cast_to_raw('XXXX'))
        where  document_id = g_document_id;
    end rejects_new_document_content;

    procedure rejects_new_document_file_name is
    begin
        update emk_claim_documents set file_name = 'other.png' where document_id = g_document_id;
    end rejects_new_document_file_name;

    procedure accepts_new_document_metadata is
        l_count pls_integer;
    begin
        update emk_claim_documents
        set    doc_type = 'DAMAGE_REPORT', extracted_text = 'Scratch on the housing'
        where  document_id = g_document_id;

        select count(*) into l_count
        from   emk_claim_documents_jn
        where  document_id = g_document_id and jn_operation = 'U' and doc_type = 'PHOTO';
        ut.expect(l_count).to_equal(1);
    end accepts_new_document_metadata;

    procedure rejects_other_mime_type is
    begin
        insert into emk_claim_documents (claim_id, doc_type, file_name, mime_type, file_size, content)
        values (g_claim_id, 'OTHER', 'a.txt', 'text/plain', 4, to_blob(utl_raw.cast_to_raw('test')));
    end rejects_other_mime_type;

    procedure rejects_unknown_history_status is
    begin
        insert into emk_claim_status_history (claim_id, to_status) values (g_claim_id, 'CLOSED');
    end rejects_unknown_history_status;

    procedure rejects_unknown_claim_type is
    begin
        update emk_claims set claim_type = 'THEFT', damage_apparent_yn = null where claim_id = g_claim_id;
    end rejects_unknown_claim_type;

    procedure rejects_unknown_document_type is
    begin
        update emk_claim_documents set doc_type = 'CONTRACT' where document_id = g_document_id;
    end rejects_unknown_document_type;

    procedure rejects_damage_without_apparent_flag is
    begin
        update emk_claims set damage_apparent_yn = null where claim_id = g_claim_id;
    end rejects_damage_without_apparent_flag;

    procedure rejects_apparent_flag_for_total_loss is
    begin
        update emk_claims set claim_type = 'TOTAL_LOSS' where claim_id = g_claim_id;   -- the flag stays 'Y'
    end rejects_apparent_flag_for_total_loss;

end test_emk_claims;
/
