create or replace package test_emk_security_pkg as
    /**
     * Unit tests of EMK_SECURITY_PKG in EMK_API (M1a step 1, BR-02): without
     * an APEX session every role check is refused (deny by default). The tests
     * with an APEX session and an assigned role follow in step 8, with
     * EMK_CLAIM_API: creating an APEX session needs workspace access for the
     * calling schema (M1 plan, §2). A refused check is logged (committed), so
     * the suite deletes the log entries it caused.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Role checks EMK_SECURITY_PKG without APEX session (EMK_API))
    --%suitepath(emk_api)

    --%beforeall
    procedure remember_start;

    --%afterall
    procedure delete_test_entries;

    --%test(has_role is FALSE without an APEX session)
    procedure denies_role_without_session;

    --%test(assert_role raises emk_errors_pkg.c_not_authorized without an APEX session)
    --%throws(emk_errors_pkg.c_not_authorized)
    procedure refuses_assert_without_session;
end test_emk_security_pkg;
/

create or replace package body test_emk_security_pkg as

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

    procedure denies_role_without_session is
    begin
        ut.expect(emk_security_pkg.has_role(emk_security_pkg.c_claims_handler)).to_be_false();
    end denies_role_without_session;

    procedure refuses_assert_without_session is
    begin
        emk_security_pkg.assert_role(emk_security_pkg.c_claims_handler);
    end refuses_assert_without_session;

end test_emk_security_pkg;
/
