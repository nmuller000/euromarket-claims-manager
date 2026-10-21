create or replace package test_emk_code_lists as
    /**
     * Unit tests of the code lists in EMK_DATA (M1a step 7.6, D-68): business
     * value lists are reference tables with a validity period and a foreign
     * key, not check constraints. Tested: the loaded values, the file type
     * allowlist with its signatures (BR-18), the foreign keys, the format
     * checks, and that retiring a value keeps the rows that use it (validity
     * is checked by the APIs when a value is chosen, not by the foreign key).
     * These tests insert and update reference rows, which only the owner may
     * do (the API only reads them, ADR-008): that is why they live here.
     * utPLSQL rolls everything back.
     *
     * @author Natalia Müller
     * @since  2026-10-18
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Code lists (EMK_DATA))
    --%suitepath(emk_data)

    --%test(Row counts: 2 languages, 6 roles, 7 claim statuses (3 final), 4 claim types, 6 document types, 3 file types, 4 extensions)
    procedure loads_expected_code_lists;

    --%test(Codes used by the program are valid today: every status of the state machine, every claim type (the roles: TEST_EMK_CODES_PKG))
    procedure keeps_program_codes_valid;

    --%test(BR-18: each allowed file type has its standard signature and its extensions)
    procedure loads_file_signatures;

    --%test(BR-18: every allowed file type has at least one extension)
    procedure links_file_types_and_extensions;

    --%test(D-68: a company with an unknown language is rejected by the foreign key)
    --%throws(-2291)
    procedure rejects_unknown_language;

    --%test(D-68: an unknown role is rejected by the foreign key)
    --%throws(-2291)
    procedure rejects_unknown_role;

    --%test(BR-18: an extension of an unknown file type is rejected by the foreign key)
    --%throws(-2291)
    procedure rejects_extension_of_unknown_file_type;

    --%test(A code in lower case is rejected)
    --%throws(-2290)
    procedure rejects_lower_case_code;

    --%test(The end of validity cannot be before its start)
    --%throws(-2290)
    procedure rejects_validity_end_before_start;

    --%test(D-68: retiring a role keeps the companies that have it; the foreign key does not check validity)
    procedure keeps_rows_with_retired_value;

    --%test(D-72: a file type added to the catalog without valid_from is not allowed)
    procedure adds_file_type_not_allowed;

    --%test(D-72: a file type cannot end its allowed period without a start)
    --%throws(-2290)
    procedure rejects_end_without_start;

    --%test(D-72: a change of a code list is kept in its journal with the previous value)
    procedure records_change_in_journal;
end test_emk_code_lists;
/

create or replace package body test_emk_code_lists as

    -- Test data helper -------------------------------------------------------------

    function new_party return emk_parties.party_id%type is
        l_id emk_parties.party_id%type;
    begin
        insert into emk_parties (name, country_code, language_code) values ('Test Code Lists GmbH', 'DE', 'en')
        returning party_id into l_id;
        return l_id;
    end new_party;

    -- Tests ------------------------------------------------------------------------

    procedure loads_expected_code_lists is
        l_count pls_integer;
    begin
        select count(*) into l_count from emk_languages;
        ut.expect(l_count, 'languages').to_equal(2);
        select count(*) into l_count from emk_party_role_types;
        ut.expect(l_count, 'party role types').to_equal(6);
        select count(*) into l_count from emk_claim_statuses;
        ut.expect(l_count, 'claim statuses').to_equal(7);
        select count(*) into l_count from emk_claim_statuses where final_yn = 'Y';
        ut.expect(l_count, 'final claim statuses').to_equal(3);
        select count(*) into l_count from emk_claim_types;
        ut.expect(l_count, 'claim types').to_equal(4);
        select count(*) into l_count from emk_document_types;
        ut.expect(l_count, 'document types').to_equal(6);
        select count(*) into l_count from emk_file_types where valid_from is not null;
        ut.expect(l_count, 'allowed file types').to_equal(3);
        select count(*) into l_count from emk_file_extensions;
        ut.expect(l_count, 'file extensions').to_equal(4);
    end loads_expected_code_lists;

    procedure keeps_program_codes_valid is
        l_count pls_integer;
    begin
        -- A retired code that the program uses would break it: retire such a code only with a code change
        select count(*) into l_count
        from   emk_claim_statuses
        where  status_code in ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION', 'RESOLVED', 'REJECTED', 'ESCALATED')
        and    valid_from <= trunc(sysdate) and (valid_to is null or valid_to >= trunc(sysdate));
        ut.expect(l_count, 'statuses of the state machine (spec §4)').to_equal(7);

        select count(*) into l_count
        from   emk_claim_types
        where  claim_type in ('TOTAL_LOSS', 'PARTIAL_LOSS', 'DAMAGE', 'DELAY')
        and    valid_from <= trunc(sysdate) and (valid_to is null or valid_to >= trunc(sysdate));
        ut.expect(l_count, 'claim types of the deadline rules (spec §5)').to_equal(4);
    end keeps_program_codes_valid;

    procedure loads_file_signatures is
        l_list varchar2(4000 char);
    begin
        select listagg(e.file_extension || '=' || t.mime_type || '=' || rawtohex(t.signature), ', ')
                   within group (order by e.file_extension)
        into   l_list
        from   emk_file_extensions e
        join   emk_file_types t on t.mime_type = e.mime_type;
        ut.expect(l_list).to_equal('jpeg=image/jpeg=FFD8FF, jpg=image/jpeg=FFD8FF, pdf=application/pdf=255044462D, '
                                   || 'png=image/png=89504E470D0A1A0A');
    end loads_file_signatures;

    procedure links_file_types_and_extensions is
        l_count pls_integer;
    begin
        select count(*) into l_count
        from   emk_file_types t
        where  t.valid_from <= trunc(sysdate) and (t.valid_to is null or t.valid_to >= trunc(sysdate))
        and    not exists (select null from emk_file_extensions e where e.mime_type = t.mime_type);
        ut.expect(l_count, 'allowed file types without an extension').to_equal(0);
    end links_file_types_and_extensions;

    procedure rejects_unknown_language is
    begin
        insert into emk_parties (name, country_code, language_code) values ('Test Code Lists SARL', 'FR', 'fr');
    end rejects_unknown_language;

    procedure rejects_unknown_role is
        l_party emk_parties.party_id%type := new_party;
    begin
        insert into emk_party_roles (party_id, role_code) values (l_party, 'DRIVER');
    end rejects_unknown_role;

    procedure rejects_extension_of_unknown_file_type is
    begin
        insert into emk_file_extensions (file_extension, mime_type) values ('exe', 'application/x-msdownload');
    end rejects_extension_of_unknown_file_type;

    procedure rejects_lower_case_code is
    begin
        insert into emk_party_role_types (role_code, name, sort_order) values ('driver', 'Driver', 99);
    end rejects_lower_case_code;

    procedure rejects_validity_end_before_start is
    begin
        update emk_claim_types set valid_from = date '2026-01-01', valid_to = date '2025-12-31' where claim_type = 'DELAY';
    end rejects_validity_end_before_start;

    procedure keeps_rows_with_retired_value is
        l_party emk_parties.party_id%type := new_party;
        l_count pls_integer;
    begin
        insert into emk_party_roles (party_id, role_code) values (l_party, 'SURVEYOR');
        update emk_party_role_types set valid_to = trunc(sysdate) - 1 where role_code = 'SURVEYOR';

        select count(*) into l_count from emk_party_roles where party_id = l_party and role_code = 'SURVEYOR';
        ut.expect(l_count, 'role row kept after the role is retired').to_equal(1);
    end keeps_rows_with_retired_value;

    procedure adds_file_type_not_allowed is
        l_valid_from emk_file_types.valid_from%type;
    begin
        insert into emk_file_types (mime_type, name, signature) values ('image/tiff', 'TIFF image', hextoraw('49492A00'));
        select valid_from into l_valid_from from emk_file_types where mime_type = 'image/tiff';
        ut.expect(l_valid_from, 'in the catalog, not allowed').to_be_null();
    end adds_file_type_not_allowed;

    procedure rejects_end_without_start is
    begin
        insert into emk_file_types (mime_type, name, signature, valid_to)
        values ('image/tiff', 'TIFF image', hextoraw('49492A00'), date '2026-12-31');
    end rejects_end_without_start;

    procedure records_change_in_journal is
        l_old_name emk_document_types_jn.name%type;
        l_by       emk_document_types_jn.jn_by%type;
    begin
        update emk_document_types set name = 'Survey report' where doc_type = 'DAMAGE_REPORT';
        select name, jn_by into l_old_name, l_by
        from   emk_document_types_jn
        where  doc_type = 'DAMAGE_REPORT' and jn_operation = 'U';
        ut.expect(l_old_name, 'previous name').to_equal('Damage report');
        ut.expect(l_by, 'who').to_be_not_null();
    end records_change_in_journal;

end test_emk_code_lists;
/
