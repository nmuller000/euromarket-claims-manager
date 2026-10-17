create or replace package test_emk_errors_pkg as
    /**
     * Unit tests of EMK_ERRORS_PKG: every constant matches its named exception,
     * and the codes shared between schemas (ADR-008 §4): the
     * document trigger in EMK_DATA uses the literal -20303, because the data
     * schema must not depend on the code schema; this test proves it equals
     * emk_errors_pkg.c_document_immutable. Uses the object grants of EMK_API on
     * EMK_DATA (insert parties, shipments, claims, documents; update documents).
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Error codes shared with EMK_DATA (EMK_API))
    --%suitepath(emk_api)

    --%test(Every error constant matches its named exception (PRAGMA EXCEPTION_INIT uses literals), and every constant is checked)
    procedure matches_constants_to_exceptions;

    --%test(The document trigger raises exactly emk_errors_pkg.c_document_immutable)
    --%throws(emk_errors_pkg.c_document_immutable)
    procedure raises_document_immutable;
end test_emk_errors_pkg;
/

create or replace package body test_emk_errors_pkg as

    procedure matches_constants_to_exceptions is
        l_matched   pls_integer := 0;
        l_constants pls_integer;
    begin
        -- Raise each constant and catch it only by its named exception
        begin raise_application_error(emk_errors_pkg.c_not_authorized, 'test');
        exception when emk_errors_pkg.e_not_authorized then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_not_found, 'test');
        exception when emk_errors_pkg.e_not_found then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_invalid_argument, 'test');
        exception when emk_errors_pkg.e_invalid_argument then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_party_role_missing, 'test');
        exception when emk_errors_pkg.e_party_role_missing then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_party_role_in_use, 'test');
        exception when emk_errors_pkg.e_party_role_in_use then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_duplicate_cmr_note, 'test');
        exception when emk_errors_pkg.e_duplicate_cmr_note then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_invalid_transition, 'test');
        exception when emk_errors_pkg.e_invalid_transition then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_invalid_amount, 'test');
        exception when emk_errors_pkg.e_invalid_amount then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_document_immutable, 'test');
        exception when emk_errors_pkg.e_document_immutable then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_reference_not_valid, 'test');
        exception when emk_errors_pkg.e_reference_not_valid then l_matched := l_matched + 1; end;
        -- Step 7: party and shipment APIs
        begin raise_application_error(emk_errors_pkg.c_record_changed, 'test');
        exception when emk_errors_pkg.e_record_changed then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_record_locked, 'test');
        exception when emk_errors_pkg.e_record_locked then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_vat_country_mismatch, 'test');
        exception when emk_errors_pkg.e_vat_country_mismatch then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_duplicate_vat, 'test');
        exception when emk_errors_pkg.e_duplicate_vat then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_party_in_use, 'test');
        exception when emk_errors_pkg.e_party_in_use then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_shipment_in_use, 'test');
        exception when emk_errors_pkg.e_shipment_in_use then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_cmr_not_applicable, 'test');
        exception when emk_errors_pkg.e_cmr_not_applicable then l_matched := l_matched + 1; end;
        begin raise_application_error(emk_errors_pkg.c_carrier_not_third_party, 'test');
        exception when emk_errors_pkg.e_carrier_not_third_party then l_matched := l_matched + 1; end;
        ut.expect(l_matched).to_equal(18);
        -- Every constant of the package is checked above: a new code needs its line here
        select count(*)
        into   l_constants
        from   user_source
        where  name = 'EMK_ERRORS_PKG' and type = 'PACKAGE'
        and    regexp_like(text, '^\s*c_[a-z_]+\s+constant\s+pls_integer', 'i');
        ut.expect(l_constants).to_equal(l_matched);
    end matches_constants_to_exceptions;

    procedure raises_document_immutable is
        l_shipper   emk_data.emk_parties.party_id%type;
        l_carrier   emk_data.emk_parties.party_id%type;
        l_consignee emk_data.emk_parties.party_id%type;
        l_shipment  emk_data.emk_shipments.shipment_id%type;
        l_claim     emk_data.emk_claims.claim_id%type;
        l_document  emk_data.emk_claim_documents.document_id%type;
    begin
        insert into emk_data.emk_parties (name, country_code) values ('Test Shipper', 'DE') returning party_id into l_shipper;
        insert into emk_data.emk_parties (name, country_code) values ('Test Carrier', 'PL') returning party_id into l_carrier;
        insert into emk_data.emk_parties (name, country_code) values ('Test Consignee', 'FR') returning party_id into l_consignee;

        insert into emk_data.emk_shipments (cmr_note_no, shipper_id, carrier_id, consignee_id, pickup_place,
                                            origin_country, delivery_place, destination_country, pickup_date,
                                            goods_description, gross_weight_kg)
        values ('CMR-TEST-ERRORS', l_shipper, l_carrier, l_consignee, 'Berlin', 'DE', 'Paris', 'FR',
                date '2026-09-01', 'Goods', 10)
        returning shipment_id into l_shipment;

        insert into emk_data.emk_claims (claim_no, shipment_id, claim_type, damage_apparent_yn, handler,
                                         registration_date)
        values ('CLM-2026-999002', l_shipment, 'DAMAGE', 'Y', 'TEST_HANDLER', date '2026-09-05')
        returning claim_id into l_claim;

        insert into emk_data.emk_claim_documents (claim_id, doc_type, file_name, mime_type, file_size, content)
        values (l_claim, 'PHOTO', 'damage.png', 'image/png', 4, to_blob(utl_raw.cast_to_raw('test')))
        returning document_id into l_document;

        update emk_data.emk_claim_documents set file_name = 'other.png' where document_id = l_document;
    end raises_document_immutable;

end test_emk_errors_pkg;
/
