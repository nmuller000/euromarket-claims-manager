create or replace package body emk_api.emk_row_version_pkg as
    /**
     * Implementation of EMK_ROW_VERSION_PKG; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    function format_row_version (
        in_version in timestamp with time zone
    ) return varchar2 sql_macro ( scalar ) is
    begin
        return 'to_char(in_version, '''
               || c_format
               || ''')';
    end format_row_version;

    function parse_row_version (
        in_row_version in varchar2
    ) return timestamp with time zone is
    begin
        return to_timestamp_tz ( in_row_version,
                                 c_format );
    end parse_row_version;

end emk_row_version_pkg;
/


-- sqlcl_snapshot {"hash":"4366e1e71162510298a1abdc635200ae5a6b8707","type":"PACKAGE_BODY","name":"EMK_ROW_VERSION_PKG","schemaName":"EMK_API","sxml":""}