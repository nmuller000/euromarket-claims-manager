create or replace package emk_app.emk_errors as
    /**
     * Business error codes of the application (spec §1.3, D-33).
     * Specification only: one constant with the code and one named exception
     * per error, grouped by area:
     *   -20001 … -20099  general and security
     *   -20100 … -20199  parties
     *   -20200 … -20299  shipments
     *   -20300 … -20399  claims
     *   -20400 … -20499  reference data
     * Raise: RAISE_APPLICATION_ERROR(emk_errors.c_not_authorized, 'message');
     * Catch: WHEN emk_errors.e_not_authorized THEN …
     * PRAGMA EXCEPTION_INIT uses literals; a unit test checks that every
     * constant matches its exception.
     *
     * @author Natalia Müller
     * @since  2026-10-08
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

    -- Parties ----------------------------------------------------------------
    c_party_role_missing constant pls_integer := -20101;  -- BR-16, party lacks the required role
    e_party_role_missing exception;
    pragma exception_init ( e_party_role_missing, -20101 );
    c_party_role_in_use constant pls_integer := -20102;  -- BR-16, role used by a shipment
    e_party_role_in_use exception;
    pragma exception_init ( e_party_role_in_use, -20102 );

    -- Shipments --------------------------------------------------------------
    c_duplicate_cmr_note constant pls_integer := -20201;  -- BR-03, CMR note number reused by a carrier
    e_duplicate_cmr_note exception;
    pragma exception_init ( e_duplicate_cmr_note, -20201 );

    -- Claims -----------------------------------------------------------------
    c_invalid_transition constant pls_integer := -20301;  -- BR-01, status change not allowed
    e_invalid_transition exception;
    pragma exception_init ( e_invalid_transition, -20301 );
    c_invalid_amount constant pls_integer := -20302;  -- BR-11, amount rules
    e_invalid_amount exception;
    pragma exception_init ( e_invalid_amount, -20302 );

    -- Reference data ---------------------------------------------------------
    c_reference_not_valid constant pls_integer := -20401;  -- code outside its validity period (e.g. HRK in 2024)
    e_reference_not_valid exception;
    pragma exception_init ( e_reference_not_valid, -20401 );
end emk_errors;
/


-- sqlcl_snapshot {"hash":"10e3a02d944a781c2b1f60fcfe3f1d02f20a0ca4","type":"PACKAGE_SPEC","name":"EMK_ERRORS","schemaName":"EMK_APP","sxml":""}