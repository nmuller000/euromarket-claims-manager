create or replace package emk_api.emk_codes_pkg as
    /**
     * The codes that the business rules name, declared once (owner decision,
     * 2026-10-20). Specification only, no body.
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
    c_role_shipper constant emk_data.emk_party_roles.role_code%type := 'SHIPPER';
    c_role_carrier constant emk_data.emk_party_roles.role_code%type := 'CARRIER';
    c_role_consignee constant emk_data.emk_party_roles.role_code%type := 'CONSIGNEE';

    -- Currency: the ECB publishes every reference rate against the euro (BR-12) ---
    c_currency_euro constant emk_data.emk_currencies.currency_code%type := 'EUR';

    -- EU VAT: traders in Northern Ireland use the prefix XI with country GB --------
    c_country_gb constant emk_data.emk_countries.country_code%type := 'GB';
    c_vat_prefix_northern_ireland constant emk_data.emk_countries.eu_vat_prefix%type := 'XI';
end emk_codes_pkg;
/


-- sqlcl_snapshot {"hash":"03426919068147f79f999ef00994205eb8823f88","type":"PACKAGE_SPEC","name":"EMK_CODES_PKG","schemaName":"EMK_API","sxml":""}