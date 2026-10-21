create or replace package test_emk_codes_pkg as
    /**
     * Unit tests of EMK_CODES_PKG (owner decision 2026-10-20): every code that
     * a rule names exists in its reference table and is valid today. If one is
     * retired or renamed in the data without changing the code, this suite
     * fails before a user meets the error.
     *
     * @author Natalia Müller
     * @since  2026-10-20
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Codes named by the rules EMK_CODES_PKG (EMK_API))
    --%suitepath(emk_api)

    --%test(BR-16: the roles SHIPPER, CARRIER and CONSIGNEE exist and are valid today)
    procedure keeps_rule_roles_valid;

    --%test(BR-12: EUR exists, is valid today and has no ECB rate (it is the base))
    procedure keeps_euro_as_base;

    --%test(EU VAT: GB is a valid country outside the EU, so that the prefix XI is the only VAT number it accepts)
    procedure keeps_gb_for_northern_ireland;

    --%test(D-82: the roles named by the rules, and only they, are protected in the master data)
    procedure protects_rule_roles;
end test_emk_codes_pkg;
/

create or replace package body test_emk_codes_pkg as

    -- 1 if the role exists and is valid today, otherwise 0
    function count_valid_role (
        in_role_code in emk_data.emk_party_role_types.role_code%type
    ) return pls_integer is
        l_count pls_integer;
    begin
        select count(*)
        into   l_count
        from   emk_data.emk_party_role_types
        where  role_code = in_role_code
        and    valid_from <= trunc(sysdate)
        and    (valid_to is null or valid_to >= trunc(sysdate));
        return l_count;
    end count_valid_role;

    procedure keeps_rule_roles_valid is
    begin
        ut.expect(count_valid_role(emk_codes_pkg.c_role_shipper), 'SHIPPER').to_equal(1);
        ut.expect(count_valid_role(emk_codes_pkg.c_role_carrier), 'CARRIER').to_equal(1);
        ut.expect(count_valid_role(emk_codes_pkg.c_role_consignee), 'CONSIGNEE').to_equal(1);
    end keeps_rule_roles_valid;

    procedure keeps_euro_as_base is
        l_ecb_rate_yn emk_data.emk_currencies.ecb_rate_yn%type;
        l_valid_to    emk_data.emk_currencies.valid_to%type;
    begin
        select ecb_rate_yn, valid_to
        into   l_ecb_rate_yn, l_valid_to
        from   emk_data.emk_currencies
        where  currency_code = emk_codes_pkg.c_currency_euro;
        ut.expect(l_ecb_rate_yn, 'EUR has no ECB rate').to_equal('N');
        ut.expect(l_valid_to, 'EUR still valid').to_be_null();
    end keeps_euro_as_base;

    procedure keeps_gb_for_northern_ireland is
        l_eu_member_yn  emk_data.emk_countries.eu_member_yn%type;
        l_eu_vat_prefix emk_data.emk_countries.eu_vat_prefix%type;
    begin
        select eu_member_yn, eu_vat_prefix
        into   l_eu_member_yn, l_eu_vat_prefix
        from   emk_data.emk_countries
        where  country_code = emk_codes_pkg.c_country_gb;
        ut.expect(l_eu_member_yn, 'GB outside the EU').to_equal('N');
        ut.expect(l_eu_vat_prefix, 'GB has no EU VAT prefix of its own').to_be_null();
    end keeps_gb_for_northern_ireland;

    procedure protects_rule_roles is
    begin
        ut.expect(emk_codes_pkg.is_protected_role(emk_codes_pkg.c_role_shipper), 'SHIPPER').to_be_true();
        ut.expect(emk_codes_pkg.is_protected_role(emk_codes_pkg.c_role_carrier), 'CARRIER').to_be_true();
        ut.expect(emk_codes_pkg.is_protected_role(emk_codes_pkg.c_role_consignee), 'CONSIGNEE').to_be_true();
        ut.expect(emk_codes_pkg.is_protected_role('SURVEYOR'), 'a role no rule names').to_be_false();
        ut.expect(emk_codes_pkg.is_protected_role(null), 'an empty code').to_be_false();
    end protects_rule_roles;

end test_emk_codes_pkg;
/
