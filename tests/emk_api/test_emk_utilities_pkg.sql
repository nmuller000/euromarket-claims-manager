create or replace package test_emk_utilities_pkg as
    /**
     * Unit tests of EMK_UTILITIES_PKG, the common functions of the APIs
     * (owner decision 2026-10-20): current user, change detection with NULL
     * and validity periods. row_version: TEST_EMK_ROW_VERSION_PKG.
     *
     * @author Natalia Müller
     * @since  2026-10-20
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Common functions EMK_UTILITIES_PKG (EMK_API))
    --%suitepath(emk_api)

    --%test(Outside APEX the current user is the proxy user, otherwise the session user)
    procedure returns_current_user;

    --%test(is_changed: NULL and NULL are equal; NULL and a value differ; never NULL (text, number, date))
    procedure detects_changes_with_null;

    --%test(is_valid_on: from and to are inclusive; an open end is valid; a missing date is not valid)
    procedure checks_validity_period;

end test_emk_utilities_pkg;
/

create or replace package body test_emk_utilities_pkg as

    procedure returns_current_user is
    begin
        ut.expect(emk_utilities_pkg.get_current_user).to_equal(
            coalesce(sys_context('USERENV', 'PROXY_USER'), sys_context('USERENV', 'SESSION_USER')));
    end returns_current_user;

    procedure detects_changes_with_null is
        l_no_text   varchar2(1 char);   -- typed NULLs choose the overload
        l_no_number number;
        l_no_date   date;
    begin
        ut.expect(emk_utilities_pkg.is_changed(l_no_text, l_no_text), 'text NULL/NULL').to_be_false();
        ut.expect(emk_utilities_pkg.is_changed(l_no_text, 'a'), 'text NULL/a').to_be_true();
        ut.expect(emk_utilities_pkg.is_changed('a', l_no_text), 'text a/NULL').to_be_true();
        ut.expect(emk_utilities_pkg.is_changed('a', 'a'), 'text a/a').to_be_false();
        ut.expect(emk_utilities_pkg.is_changed('a', 'b'), 'text a/b').to_be_true();
        ut.expect(emk_utilities_pkg.is_changed(l_no_number, l_no_number), 'number NULL/NULL').to_be_false();
        ut.expect(emk_utilities_pkg.is_changed(1, l_no_number), 'number 1/NULL').to_be_true();
        ut.expect(emk_utilities_pkg.is_changed(1, 2), 'number 1/2').to_be_true();
        ut.expect(emk_utilities_pkg.is_changed(date '2026-01-01', date '2026-01-01'), 'date equal').to_be_false();
        ut.expect(emk_utilities_pkg.is_changed(date '2026-01-01', l_no_date), 'date d/NULL').to_be_true();
    end detects_changes_with_null;

    procedure checks_validity_period is
    begin
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', date '2026-12-31', date '2026-06-30'), 'inside').to_be_true();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', date '2026-12-31', date '2026-01-01'), 'first day').to_be_true();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', date '2026-12-31', date '2026-12-31'), 'last day').to_be_true();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', date '2026-12-31', date '2025-12-31'), 'before').to_be_false();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', date '2026-12-31', date '2027-01-01'), 'after').to_be_false();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', null, date '2099-01-01'), 'open end').to_be_true();
        ut.expect(emk_utilities_pkg.is_valid_on(date '2026-01-01', null, null), 'no date').to_be_false();
    end checks_validity_period;

end test_emk_utilities_pkg;
/
