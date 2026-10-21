create or replace package emk_api.emk_row_version_pkg as
    /**
     * Text form of row_version, the version for optimistic locking (D-43,
     * api-design decision 14): the views write it, the APEX pages read it
     * back. A package of its own so that the connect user EMK_UI gets EXECUTE
     * on exactly what the pages need and nothing more (least privilege,
     * owner decision 2026-10-21).
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- The fixed format: independent of the session's NLS settings
    c_format constant varchar2(40 char) := 'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM';

    /**
     * row_version as text in the format c_format. A scalar SQL macro: the
     * views copy the expression into their query, so it costs no call per
     * row. Use it in SQL only.
     *
     * @param  in_version NVL(updated_at, created_at) of the row
     * @return the text kept by an APEX page in a hidden item
     */
    function format_row_version (
        in_version in timestamp with time zone
    ) return varchar2 sql_macro ( scalar );

    /**
     * Converts the row_version text read from a view back to the timestamp
     * that the APIs expect as in_expected_updated_at.
     *
     * @param  in_row_version text in the format c_format
     * @return the timestamp; NULL if the text is NULL
     * @throws ORA-01830 and related conversion errors if the text has another format
     * @usage  APEX page processes: in_expected_updated_at => emk_row_version_pkg.parse_row_version(:P11_ROW_VERSION)
     */
    function parse_row_version (
        in_row_version in varchar2
    ) return timestamp with time zone;

end emk_row_version_pkg;
/


-- sqlcl_snapshot {"hash":"a5b169f00ec804eac3a270e1c87ce76c57c5423e","type":"PACKAGE_SPEC","name":"EMK_ROW_VERSION_PKG","schemaName":"EMK_API","sxml":""}