create or replace package test_emk_row_version_pkg as
    /**
     * Unit tests of EMK_ROW_VERSION_PKG (owner decision 2026-10-21): the text
     * form of row_version written by the views and read back by the pages.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Text form of row_version EMK_ROW_VERSION_PKG (EMK_API))
    --%suitepath(emk_api)

    --%test(row_version: the text of the views converts back to the same timestamp, fractions included)
    procedure round_trips_row_version;
end test_emk_row_version_pkg;
/

create or replace package body test_emk_row_version_pkg as

    procedure round_trips_row_version is
        l_version timestamp with time zone := timestamp '2026-10-20 09:15:30.123456 +02:00';
        l_text    varchar2(40 char);
    begin
        select emk_row_version_pkg.format_row_version(l_version) into l_text from dual;
        ut.expect(l_text, 'text').to_equal('2026-10-20T09:15:30.123456+02:00');
        ut.expect(emk_row_version_pkg.parse_row_version(l_text), 'back to the timestamp').to_equal(l_version);
    end round_trips_row_version;

end test_emk_row_version_pkg;
/
