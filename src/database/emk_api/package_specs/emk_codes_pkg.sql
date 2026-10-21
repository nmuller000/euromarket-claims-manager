create or replace package emk_api.emk_codes_pkg as
    /**
     * The codes that the business rules name, declared once (owner decision,
     * 2026-10-20), and which of them are protected in the master data
     * (D-82): a code a rule names cannot be retired.
     *
     * What belongs here:
     *   - codes of a code list that a rule names, e.g. "the carrier of a
     *     shipment has the role CARRIER" (BR-16). The list itself, with names,
     *     descriptions, order and validity, stays in its reference table and
     *     is maintained in the application (master data); these codes are
     *     protected there, because retiring one would break the rule;
     *   - values fixed by a law or an official source, e.g. EUR, the base of
     *     the ECB reference rates.
     * What does not: lists of values (reference tables), error codes
     * (EMK_ERRORS_PKG), application roles (EMK_SECURITY_PKG), log levels
     * (EMK_LOG_PKG).
     *
     * @author Natalia Müller
     * @since  2026-10-20
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Party roles named by BR-16 (EMK_PARTY_ROLE_TYPES) --------------------------
    c_role_sender constant emk_data.emk_party_roles.role_code%type := 'SENDER';
    c_role_carrier constant emk_data.emk_party_roles.role_code%type := 'CARRIER';
    c_role_consignee constant emk_data.emk_party_roles.role_code%type := 'CONSIGNEE';

    -- Currency: the ECB publishes every reference rate against the euro (BR-12) ---
    c_currency_euro constant emk_data.emk_currencies.currency_code%type := 'EUR';

    -- EU VAT: traders in Northern Ireland use the prefix XI with country GB --------
    c_country_gb constant emk_data.emk_countries.country_code%type := 'GB';
    c_vat_prefix_northern_ireland constant emk_data.emk_countries.eu_vat_prefix%type := 'XI';

    /**
     * Tells whether a party role is named by a rule, so the master data
     * cannot retire it (D-82). A role constant added above is added here too,
     * in the same change; a unit test checks every one.
     *
     * @param  in_role_code role code, as stored (upper case)
     * @return TRUE for the roles named by the rules
     */
    function is_protected_role (
        in_role_code in emk_data.emk_party_role_types.role_code%type
    ) return boolean;

end emk_codes_pkg;
/


-- sqlcl_snapshot {"hash":"b1578deea93c3d48f03a1667eda815d88b3fe894","type":"PACKAGE_SPEC","name":"EMK_CODES_PKG","schemaName":"EMK_API","sxml":""}