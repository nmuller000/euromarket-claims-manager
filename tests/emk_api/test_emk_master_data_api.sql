create or replace package test_emk_master_data_api as
    /**
     * Unit tests of EMK_MASTER_DATA_API in EMK_API (T-M1-44, D-82): what can
     * be checked without an APEX session. Every subprogram refuses a caller
     * without the administrator role (deny by default), and the database
     * itself refuses what the API never does: changing a code, final_yn or a
     * signature, and deleting a value (column privileges of EMK_API, script
     * 20 of step 7.7). The checks with the administrator role need an APEX
     * session: tests/emk_ui/master_data_test.sql. A refused role check is
     * logged (committed), so the suite deletes the log entries it caused.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Master data API EMK_MASTER_DATA_API without APEX session (EMK_API))
    --%suitepath(emk_api)

    --%beforeall
    procedure remember_start;

    --%afterall
    procedure delete_test_entries;

    --%test(D-82: without the administrator role a change is refused before anything is read or written)
    --%throws(emk_errors_pkg.c_not_authorized)
    procedure refuses_without_administrator;

    --%test(D-82: without the administrator role a new value is refused)
    --%throws(emk_errors_pkg.c_not_authorized)
    procedure refuses_create_without_administrator;

    --%test(D-82: the database refuses a change of a code, even by EMK_API (column privileges))
    procedure database_refuses_code_change;

    --%test(D-82: the database refuses a change of final_yn, of a signature and of a file type name)
    procedure database_refuses_rule_columns;

    --%test(D-82: the database refuses deleting a value of a code list)
    procedure database_refuses_delete;
end test_emk_master_data_api;
/

create or replace package body test_emk_master_data_api as

    g_start timestamp with time zone;

    procedure remember_start is
    begin
        g_start := systimestamp;
    end remember_start;

    -- Refusals of this run only: written by this session after the suite started
    procedure delete_test_entries is
        pragma autonomous_transaction;
    begin
        delete from emk_log
        where  message = 'Role check refused'
        and    created_at >= g_start
        and    created_by = coalesce(sys_context('USERENV', 'PROXY_USER'), sys_context('USERENV', 'SESSION_USER'));
        commit;
    end delete_test_entries;

    -- Error code of the statement: 0 if it runs; a missing object privilege is
    -- ORA-41900 (named privilege and object, 23ai) or ORA-01031
    function error_code_of (
        in_sql in varchar2
    ) return pls_integer is
    begin
        execute immediate in_sql;   -- WHERE 1 = 0: changes nothing even if it runs
        return 0;
    exception
        when others then
            return sqlcode;
    end error_code_of;

    procedure expect_refused (
        in_sql  in varchar2,
        in_what in varchar2
    ) is
        l_code pls_integer := error_code_of(in_sql);
    begin
        ut.expect(l_code in ( -41900, -1031 ), in_what || ' (error ' || l_code || ')').to_be_true();
    end expect_refused;

    procedure refuses_without_administrator is
    begin
        emk_master_data_api.update_claim_status(in_status_code         => 'DRAFT',
                                                in_expected_updated_at => systimestamp,
                                                in_name                => 'Draft',
                                                in_description         => null,
                                                in_sort_order          => 10);
    end refuses_without_administrator;

    procedure refuses_create_without_administrator is
    begin
        emk_master_data_api.create_document_type(in_doc_type    => 'MD_TEST_DOC',
                                                 in_name        => 'Test',
                                                 in_description => null,
                                                 in_sort_order  => 99,
                                                 in_valid_from  => trunc(sysdate));
    end refuses_create_without_administrator;

    procedure database_refuses_code_change is
    begin
        expect_refused('update emk_data.emk_party_role_types set role_code = role_code where 1 = 0', 'role code');
        expect_refused('update emk_data.emk_claim_statuses set status_code = status_code where 1 = 0', 'status code');
        expect_refused('update emk_data.emk_claim_types set claim_type = claim_type where 1 = 0', 'claim type');
        expect_refused('update emk_data.emk_document_types set doc_type = doc_type where 1 = 0', 'document type');
        expect_refused('update emk_data.emk_file_types set mime_type = mime_type where 1 = 0', 'media type');
    end database_refuses_code_change;

    procedure database_refuses_rule_columns is
    begin
        expect_refused('update emk_data.emk_claim_statuses set final_yn = final_yn where 1 = 0', 'final_yn');
        expect_refused('update emk_data.emk_claim_statuses set valid_to = valid_to where 1 = 0', 'validity of a status');
        expect_refused('update emk_data.emk_file_types set signature = signature where 1 = 0', 'signature');
        expect_refused('update emk_data.emk_file_types set name = name where 1 = 0', 'file type name');
    end database_refuses_rule_columns;

    procedure database_refuses_delete is
    begin
        expect_refused('delete from emk_data.emk_party_role_types where 1 = 0', 'roles');
        expect_refused('delete from emk_data.emk_document_types where 1 = 0', 'document types');
        expect_refused('delete from emk_data.emk_file_types where 1 = 0', 'file types');
    end database_refuses_delete;

end test_emk_master_data_api;
/
