create or replace package emk_api.emk_errors_pkg as
    /**
     * Business error codes of the application (spec §1.3, D-33).
     * Specification only: one constant with the code and one named exception
     * per error, grouped by area:
     *   -20001 … -20099  general and security
     *   -20100 … -20199  parties
     *   -20200 … -20299  shipments
     *   -20300 … -20399  claims
     *   -20400 … -20499  reference data
     * Raise: RAISE_APPLICATION_ERROR(emk_errors_pkg.c_not_authorized, 'message');
     * Catch: WHEN emk_errors_pkg.e_not_authorized THEN …
     * PRAGMA EXCEPTION_INIT uses literals; a unit test checks that every
     * constant matches its exception.
     *
     * @author Natalia Müller
     * @since  2026-10-08
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- General and security --------------------------------------------------
    c_not_authorized constant pls_integer := -20001;  -- BR-02, EMK_SECURITY_PKG.assert_role
    e_not_authorized exception;
    pragma exception_init ( e_not_authorized, -20001 );
    c_not_found constant pls_integer := -20002;  -- record does not exist or is soft-deleted
    e_not_found exception;
    pragma exception_init ( e_not_found, -20002 );
    c_invalid_argument constant pls_integer := -20003;  -- missing or malformed parameter
    e_invalid_argument exception;
    pragma exception_init ( e_invalid_argument, -20003 );
    c_record_changed constant pls_integer := -20004;  -- D-43, row changed by another user since it was read
    e_record_changed exception;
    pragma exception_init ( e_record_changed, -20004 );
    c_record_locked constant pls_integer := -20005;  -- D-43, row locked by another transaction (ORA-00054)
    e_record_locked exception;
    pragma exception_init ( e_record_locked, -20005 );

    -- Parties ----------------------------------------------------------------
    c_party_role_missing constant pls_integer := -20101;  -- BR-16, party lacks the required role
    e_party_role_missing exception;
    pragma exception_init ( e_party_role_missing, -20101 );
    c_party_role_in_use constant pls_integer := -20102;  -- BR-16, role used by a shipment
    e_party_role_in_use exception;
    pragma exception_init ( e_party_role_in_use, -20102 );
    c_vat_country_mismatch constant pls_integer := -20103;  -- VAT prefix does not match the party's country
    e_vat_country_mismatch exception;
    pragma exception_init ( e_vat_country_mismatch, -20103 );
    c_duplicate_vat constant pls_integer := -20104;  -- VAT number already used, also by a soft-deleted party (D-39)
    e_duplicate_vat exception;
    pragma exception_init ( e_duplicate_vat, -20104 );
    c_party_in_use constant pls_integer := -20105;  -- party has active shipments
    e_party_in_use exception;
    pragma exception_init ( e_party_in_use, -20105 );
    c_party_role_required constant pls_integer := -20106;  -- a company needs at least one role (D-71)
    e_party_role_required exception;
    pragma exception_init ( e_party_role_required, -20106 );

    -- Shipments --------------------------------------------------------------
    c_duplicate_cmr_note constant pls_integer := -20201;  -- BR-03, CMR note number reused by a carrier
    e_duplicate_cmr_note exception;
    pragma exception_init ( e_duplicate_cmr_note, -20201 );
    c_shipment_in_use constant pls_integer := -20202;  -- shipment has active claims
    e_shipment_in_use exception;
    pragma exception_init ( e_shipment_in_use, -20202 );
    c_cmr_not_applicable constant pls_integer := -20203;  -- BR-17, no CMR party on the pickup date
    e_cmr_not_applicable exception;
    pragma exception_init ( e_cmr_not_applicable, -20203 );
    c_carrier_not_third_party constant pls_integer := -20204;  -- CMR Art. 1(1): the carrier is not the shipper or the consignee
    e_carrier_not_third_party exception;
    pragma exception_init ( e_carrier_not_third_party, -20204 );

    -- Claims -----------------------------------------------------------------
    c_invalid_transition constant pls_integer := -20301;  -- BR-01, status change not allowed
    e_invalid_transition exception;
    pragma exception_init ( e_invalid_transition, -20301 );
    c_invalid_amount constant pls_integer := -20302;  -- BR-11, amount rules
    e_invalid_amount exception;
    pragma exception_init ( e_invalid_amount, -20302 );
    c_document_immutable constant pls_integer := -20303;  -- D-41, file of a claim document cannot change
    e_document_immutable exception;
    pragma exception_init ( e_document_immutable, -20303 );

    -- Reference data ---------------------------------------------------------
    c_reference_not_valid constant pls_integer := -20401;  -- code outside its validity period (e.g. HRK in 2024)
    e_reference_not_valid exception;
    pragma exception_init ( e_reference_not_valid, -20401 );
    c_code_protected constant pls_integer := -20402;  -- D-82, a code named in EMK_CODES_PKG cannot be retired
    e_code_protected exception;
    pragma exception_init ( e_code_protected, -20402 );
    c_code_exists constant pls_integer := -20403;  -- D-82, code already in its list, also if retired (never reused)
    e_code_exists exception;
    pragma exception_init ( e_code_exists, -20403 );
end emk_errors_pkg;
/


-- sqlcl_snapshot {"hash":"bf636de69e73cf2c9010f5f19c0177a5a73e981e","type":"PACKAGE_SPEC","name":"EMK_ERRORS_PKG","schemaName":"EMK_API","sxml":""}