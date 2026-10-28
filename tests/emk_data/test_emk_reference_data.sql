create or replace package test_emk_reference_data as
    /**
     * Unit tests of the reference tables in EMK_DATA (M1a step 2, D-37, D-38;
     * VAT formats D-88; postcodes D-89, D-90):
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

    --%test(D-88: 28 VAT formats; every EU member has one valid today; EL belongs to GR and XI to GB)
    procedure loads_expected_vat_formats;

    --%test(D-88: a VAT format without anchors is rejected)
    --%throws(-2290)
    procedure rejects_vat_format_without_anchors;

    --%test(D-88: every VAT example follows its format, so every format is a valid pattern (not a check constraint: ORA-02436, P-46))
    procedure follows_vat_format_in_examples;

    --%test(D-88, P-20: no VAT format uses a character range such as [0-9])
    procedure avoids_ranges_in_vat_formats;

    --%test(D-89, D-90: a postcode rule for every country; every country requires a postcode except Syria (UPU list))
    procedure loads_postal_code_requirement;

    --%test(D-90: every postcode example follows the format of its country, so every format is a valid pattern)
    procedure follows_postal_format_in_examples;

    --%test(D-90: the example of a country with a prefix starts with the prefix (official form, e.g. LV-1050))
    procedure starts_postal_examples_with_prefix;

    --%test(D-90, P-20: no postcode format uses a character range such as [0-9])
    procedure avoids_ranges_in_postal_formats;

    --%test(D-90: a company postcode outside the general form is rejected (letters, digits, spaces, hyphens))
    --%throws(-2290)
    procedure rejects_postal_code_outside_general_form;

    --%test(D-90: a company postcode with two spaces in a row is rejected (normalised by the API))
    --%throws(-2290)
    procedure rejects_postal_code_with_double_space;
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

    procedure loads_expected_vat_formats is
        l_formats   pls_integer;
        l_eu_ok     pls_integer;
        l_prefix_gr emk_vat_formats.vat_prefix%type;
        l_prefix_gb emk_vat_formats.vat_prefix%type;
    begin
        select count(*) into l_formats from emk_vat_formats;
        select count(*)
        into   l_eu_ok
        from   emk_countries c
        where  c.eu_member_yn = 'Y'
        and    (select count(*)
                from   emk_vat_formats f
                where  f.country_code = c.country_code
                and    f.valid_from <= trunc(sysdate)
                and    (f.valid_to is null or f.valid_to >= trunc(sysdate))) = 1;
        select vat_prefix into l_prefix_gr from emk_vat_formats where country_code = 'GR';
        select vat_prefix into l_prefix_gb from emk_vat_formats where country_code = 'GB';
        ut.expect(l_formats).to_equal(28);
        ut.expect(l_eu_ok, 'EU members with one valid VAT format').to_equal(27);
        ut.expect(l_prefix_gr).to_equal('EL');
        ut.expect(l_prefix_gb).to_equal('XI');
    end loads_expected_vat_formats;

    procedure rejects_vat_format_without_anchors is
    begin
        insert into emk_vat_formats (vat_prefix, country_code, national_format, national_example)
        values ('QQ', 'DE', '[0123456789]{9}', '123456789');
    end rejects_vat_format_without_anchors;

    procedure follows_vat_format_in_examples is
        l_outside sys_refcursor;
    begin
        open l_outside for
            select vat_prefix, national_format, national_example
            from   emk_vat_formats
            where  not regexp_like(national_example, national_format, 'c');
        ut.expect(l_outside).to_be_empty();
    end follows_vat_format_in_examples;

    procedure avoids_ranges_in_vat_formats is
        c_alnum constant varchar2(62 char) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        l_ranges sys_refcursor;
    begin
        open l_ranges for
            select vat_prefix, national_format
            from   emk_vat_formats
            where  regexp_like(national_format, '\[[^]]*[' || c_alnum || ']-[' || c_alnum || '][^]]*\]');
        ut.expect(l_ranges).to_be_empty();
    end avoids_ranges_in_vat_formats;

    procedure loads_postal_code_requirement is
        l_rules   pls_integer;
        l_without varchar2(400 char);
    begin
        select count(*) into l_rules from emk_postal_formats;
        select listagg(country_code, ',') within group (order by country_code)
        into   l_without
        from   emk_postal_formats
        where  postal_code_required_yn = 'N';
        ut.expect(l_rules, 'a rule for every country').to_equal(60);
        ut.expect(l_without, 'countries without postcodes').to_equal('SY');
    end loads_postal_code_requirement;

    procedure follows_postal_format_in_examples is
        l_outside sys_refcursor;
    begin
        open l_outside for
            select country_code, postal_code_format, postal_code_example
            from   emk_postal_formats
            where  postal_code_format is not null
            and    not regexp_like(postal_code_example, postal_code_format, 'c');
        ut.expect(l_outside).to_be_empty();
    end follows_postal_format_in_examples;

    procedure starts_postal_examples_with_prefix is
        l_outside sys_refcursor;
    begin
        open l_outside for
            select country_code, postal_code_prefix, postal_code_example
            from   emk_postal_formats
            where  postal_code_prefix is not null
            and    substr(postal_code_example, 1, length(postal_code_prefix)) <> postal_code_prefix;
        ut.expect(l_outside).to_be_empty();
    end starts_postal_examples_with_prefix;

    procedure avoids_ranges_in_postal_formats is
        c_alnum constant varchar2(62 char) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        l_ranges sys_refcursor;
    begin
        open l_ranges for
            select country_code, postal_code_format
            from   emk_postal_formats
            where  regexp_like(postal_code_format, '\[[^]]*[' || c_alnum || ']-[' || c_alnum || '][^]]*\]');
        ut.expect(l_ranges).to_be_empty();
    end avoids_ranges_in_postal_formats;

    procedure rejects_postal_code_outside_general_form is
    begin
        insert into emk_parties (name, street, city, postal_code, country_code, language_code)
        values ('Test Postcode GmbH', 'Test Street 1', 'Test City', '{{{{', 'DE', 'en');
    end rejects_postal_code_outside_general_form;

    procedure rejects_postal_code_with_double_space is
    begin
        insert into emk_parties (name, street, city, postal_code, country_code, language_code)
        values ('Test Postcode BV', 'Test Street 1', 'Test City', '1012  AB', 'NL', 'en');
    end rejects_postal_code_with_double_space;

end test_emk_reference_data;
/
