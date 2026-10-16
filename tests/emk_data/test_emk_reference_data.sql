create or replace package test_emk_reference_data as
    /**
     * Unit tests of the reference tables in EMK_DATA (M1a step 2, D-37, D-38):
     * the loaded data (counts and key business facts) and the constraints that
     * keep ISO codes valid. P-20 is tested by its root cause: no REGEXP check
     * constraint uses a character range, because a range follows the session
     * sort (NLS_SORT/NLS_COMP) while an explicit list does not. The session sort
     * is not changed in a test: utPLSQL keeps string-indexed associative arrays
     * that break if NLS_SORT or NLS_COMP change during the run (ORA-06502).
     * These tests insert and update reference rows, which only the owner may
     * do (the API only reads them, ADR-008): that is why they live here.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Reference data (EMK_DATA))
    --%suitepath(emk_data)

    --%test(Row counts: 60 countries, 60 German names, 32 currencies, 32 German names)
    procedure loads_expected_row_counts;

    --%test(58 CMR parties, 27 EU members, 30 EEA members)
    procedure loads_expected_memberships;

    --%test(31 currencies with an ECB rate, 2 closed currencies)
    procedure loads_expected_currencies;

    --%test(A lower-case country code is rejected)
    --%throws(-2290)
    procedure rejects_lower_case_country_code;

    --%test(EUR cannot have an ECB rate)
    --%throws(-2290)
    procedure rejects_ecb_rate_for_eur;

    --%test(A translation of an unknown country is rejected)
    --%throws(-2291)
    procedure rejects_translation_of_unknown_country;

    --%test(P-20: no REGEXP check constraint uses a character range such as [A-Z])
    procedure avoids_ranges_in_regexp_checks;
end test_emk_reference_data;
/

create or replace package body test_emk_reference_data as

    procedure loads_expected_row_counts is
        l_countries      pls_integer;
        l_country_names  pls_integer;
        l_currencies     pls_integer;
        l_currency_names pls_integer;
    begin
        select count(*) into l_countries from emk_countries;
        select count(*) into l_country_names from emk_country_names where language_code = 'de';
        select count(*) into l_currencies from emk_currencies;
        select count(*) into l_currency_names from emk_currency_names where language_code = 'de';
        ut.expect(l_countries).to_equal(60);
        ut.expect(l_country_names).to_equal(60);
        ut.expect(l_currencies).to_equal(32);
        ut.expect(l_currency_names).to_equal(32);
    end loads_expected_row_counts;

    procedure loads_expected_memberships is
        l_cmr pls_integer;
        l_eu  pls_integer;
        l_eea pls_integer;
    begin
        select count(cmr_party_since),
               count(case when eu_member_yn = 'Y' then 1 end),
               count(case when eea_member_yn = 'Y' then 1 end)
        into   l_cmr, l_eu, l_eea
        from   emk_countries;
        ut.expect(l_cmr).to_equal(58);
        ut.expect(l_eu).to_equal(27);
        ut.expect(l_eea).to_equal(30);
    end loads_expected_memberships;

    procedure loads_expected_currencies is
        l_ecb    pls_integer;
        l_closed pls_integer;
    begin
        select count(case when ecb_rate_yn = 'Y' then 1 end), count(valid_to)
        into   l_ecb, l_closed
        from   emk_currencies;
        ut.expect(l_ecb).to_equal(31);
        ut.expect(l_closed).to_equal(2);
    end loads_expected_currencies;

    procedure rejects_lower_case_country_code is
    begin
        insert into emk_countries (country_code, name, iso_name) values ('xx', 'X', 'X');
    end rejects_lower_case_country_code;

    procedure rejects_ecb_rate_for_eur is
    begin
        update emk_currencies set ecb_rate_yn = 'Y' where currency_code = 'EUR';
    end rejects_ecb_rate_for_eur;

    procedure rejects_translation_of_unknown_country is
    begin
        insert into emk_country_names (country_code, language_code, name) values ('ZZ', 'de', 'Z');
    end rejects_translation_of_unknown_country;

    procedure avoids_ranges_in_regexp_checks is
        c_alnum constant varchar2(62 char) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        l_ranges sys_refcursor;
    begin
        -- A range is "<letter or digit>-<letter or digit>" inside brackets; explicit lists only (P-20)
        open l_ranges for
            select table_name, constraint_name, search_condition_vc
            from   user_constraints
            where  constraint_type = 'C'
            and    upper(search_condition_vc) like '%REGEXP_LIKE%'
            and    regexp_like(search_condition_vc, '\[[^]]*[' || c_alnum || ']-[' || c_alnum || '][^]]*\]');
        ut.expect(l_ranges).to_be_empty();
    end avoids_ranges_in_regexp_checks;

end test_emk_reference_data;
/
