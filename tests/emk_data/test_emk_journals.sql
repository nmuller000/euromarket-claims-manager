create or replace package test_emk_journals as
    /**
     * Unit tests of the journals in EMK_DATA (FR-09, D-39): every journaled
     * table has a journal <TABLE>_JN that keeps every column of the base table
     * (except the file and the extracted text of a document), and a delete
     * writes the previous row with operation D.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Journals (EMK_DATA))
    --%suitepath(emk_data)

    --%test(The six operational tables have a journal)
    procedure counts_six_journals;

    --%test(D-39: every journal keeps every column of its base table)
    procedure keeps_every_base_column;

    --%test(A delete writes the previous row to the journal with operation D)
    procedure records_delete_in_journal;
end test_emk_journals;
/

create or replace package body test_emk_journals as

    procedure counts_six_journals is
        l_count pls_integer;
    begin
        select count(*) into l_count
        from   user_tables j
        join   user_tables b on j.table_name = b.table_name || '_JN';
        ut.expect(l_count).to_equal(6);
    end counts_six_journals;

    procedure keeps_every_base_column is
        l_missing sys_refcursor;
    begin
        -- Columns of a base table that its journal does not have
        open l_missing for
            select b.table_name, b.column_name
            from   user_tab_columns b
            join   user_tables j on j.table_name = b.table_name || '_JN'
            where  not exists (select 1
                               from   user_tab_columns c
                               where  c.table_name = j.table_name
                               and    c.column_name = b.column_name)
            and    not (b.table_name = 'EMK_CLAIM_DOCUMENTS' and b.column_name in ('CONTENT', 'EXTRACTED_TEXT'));
        ut.expect(l_missing).to_be_empty();
    end keeps_every_base_column;

    procedure records_delete_in_journal is
        l_party emk_parties.party_id%type;
        l_count pls_integer;
    begin
        insert into emk_parties (name, country_code) values ('Test Party', 'DE') returning party_id into l_party;
        insert into emk_party_roles (party_id, role_code) values (l_party, 'CARRIER');
        delete from emk_party_roles where party_id = l_party and role_code = 'CARRIER';

        select count(*) into l_count
        from   emk_party_roles_jn
        where  party_id = l_party and role_code = 'CARRIER' and jn_operation = 'D';
        ut.expect(l_count).to_equal(1);
    end records_delete_in_journal;

end test_emk_journals;
/
