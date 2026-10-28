create or replace package test_emk_log_pkg as
    /**
     * Unit tests of EMK_LOG_PKG in EMK_API (M1a step 1, D-33): INFO is always
     * written, DEBUG only when enabled, every entry is committed on its own
     * (autonomous transaction, so it survives a rollback of the caller), and
     * invalid arguments are rejected with emk_errors_pkg.c_invalid_argument.
     * The entries are committed, so utPLSQL cannot roll them back: the suite
     * deletes them after the run (all messages start with c_marker).
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Technical log EMK_LOG_PKG (EMK_API))
    --%suitepath(emk_api)

    --%afterall
    procedure delete_test_entries;

    --%test(An INFO entry is committed on its own (survives a rollback of the caller))
    procedure commits_info_entry;

    --%test(DEBUG is not written at the default level INFO)
    procedure skips_debug_by_default;

    --%test(DEBUG is written after set_level('DEBUG'))
    --%aftertest(reset_level)
    procedure writes_debug_after_set_level;

    --%test(An unknown level is rejected)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_unknown_level;

    --%test(The purge needs a retention of at least one day)
    --%throws(emk_errors_pkg.c_invalid_argument)
    procedure rejects_retention_below_one_day;

    --%test(log_error with a given error stack returns the number of its committed ERROR entry)
    procedure returns_id_of_error_entry;

    procedure reset_level;
end test_emk_log_pkg;
/

create or replace package body test_emk_log_pkg as

    c_marker constant varchar2(30 char) := 'utPLSQL TEST_EMK_LOG_PKG: ';

    -- Counts committed entries only: an autonomous transaction does not see
    -- the uncommitted work of the test, so a hit proves the entry was committed
    function get_committed_count (in_message in varchar2) return pls_integer is
        pragma autonomous_transaction;
        l_count pls_integer;
    begin
        select count(*) into l_count from emk_log where message = in_message;
        commit;
        return l_count;
    end get_committed_count;

    procedure delete_test_entries is
        pragma autonomous_transaction;
    begin
        delete from emk_log where message like c_marker || '%';
        commit;
    end delete_test_entries;

    procedure reset_level is
    begin
        emk_log_pkg.set_level(emk_log_pkg.c_info);
    end reset_level;

    procedure commits_info_entry is
        c_message constant varchar2(100 char) := c_marker || 'info';
    begin
        emk_log_pkg.log_info(c_message);
        ut.expect(get_committed_count(c_message)).to_equal(1);
    end commits_info_entry;

    procedure skips_debug_by_default is
        c_message constant varchar2(100 char) := c_marker || 'debug at default level';
    begin
        emk_log_pkg.log_debug(c_message);
        ut.expect(get_committed_count(c_message)).to_equal(0);
    end skips_debug_by_default;

    procedure writes_debug_after_set_level is
        c_message constant varchar2(100 char) := c_marker || 'debug after set_level';
    begin
        emk_log_pkg.set_level(emk_log_pkg.c_debug);
        emk_log_pkg.log_debug(c_message);
        ut.expect(get_committed_count(c_message)).to_equal(1);
    end writes_debug_after_set_level;

    procedure returns_id_of_error_entry is
        c_message constant varchar2(100 char) := c_marker || 'error with a given stack';
        l_log_id  emk_log.log_id%type;
        l_level   emk_log.log_level%type;
        l_stack   varchar2(4000 char);
    begin
        l_log_id := emk_log_pkg.log_error(in_message     => c_message,
                                          in_context     => null,
                                          in_error_stack => 'ORA-20999: test stack');
        select log_level, dbms_lob.substr(error_stack, 4000, 1)
        into   l_level, l_stack
        from   emk_log
        where  log_id = l_log_id;
        ut.expect(l_level).to_equal(emk_log_pkg.c_error);
        ut.expect(l_stack).to_equal('ORA-20999: test stack');
        ut.expect(get_committed_count(c_message)).to_equal(1);
    end returns_id_of_error_entry;

    procedure rejects_unknown_level is
    begin
        emk_log_pkg.set_level('VERBOSE');
    end rejects_unknown_level;

    procedure rejects_retention_below_one_day is
    begin
        emk_log_pkg.purge_entries(0);
    end rejects_retention_below_one_day;

end test_emk_log_pkg;
/
