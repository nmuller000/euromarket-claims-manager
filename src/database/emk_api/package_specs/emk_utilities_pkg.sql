create or replace package emk_api.emk_utilities_pkg as
    /**
     * Common functions of the APIs, written once (owner decision, 2026-10-20):
     * the user behind a change, change detection, validity periods of
     * reference data and the named exceptions for locked rows. No business
     * rule lives here. The text form of row_version is in EMK_ROW_VERSION_PKG,
     * the only one of these that the connect user EMK_UI may execute.
     *
     * @author Natalia Müller
     * @since  2026-10-20
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- ORA-00054: the row is locked by another transaction (FOR UPDATE NOWAIT)
    e_resource_busy exception;
    pragma exception_init ( e_resource_busy, -54 );

    -- ORA-30006: the row stayed locked longer than FOR UPDATE WAIT n allowed
    e_lock_timeout exception;
    pragma exception_init ( e_lock_timeout, -30006 );

    /**
     * The person behind a change, as in the audit defaults of the tables: the
     * APEX user, otherwise the proxy user (EMK_DEV), otherwise the session user.
     *
     * @return the user name
     */
    function get_current_user return varchar2;

    /**
     * Tells whether a value changed. NULL and NULL count as equal; never
     * returns NULL, so a condition "nothing changed" built with it never
     * becomes NULL. Versions for text, numbers and dates.
     *
     * @param  in_old value stored
     * @param  in_new value received
     * @return TRUE if the values differ
     */
    function is_changed (
        in_old in varchar2,
        in_new in varchar2
    ) return boolean;

    function is_changed (
        in_old in number,
        in_new in number
    ) return boolean;

    function is_changed (
        in_old in date,
        in_new in date
    ) return boolean;

    /**
     * Tells whether a row of reference data is valid on a date: valid_from on
     * or before the date, and valid_to empty or on or after it (spec §1.3).
     *
     * @param  in_valid_from start of validity
     * @param  in_valid_to   end of validity; NULL = still valid
     * @param  in_on_date    business date to check
     * @return TRUE if valid on that date; FALSE if a date is missing
     */
    function is_valid_on (
        in_valid_from in date,
        in_valid_to   in date,
        in_on_date    in date
    ) return boolean;

end emk_utilities_pkg;
/


-- sqlcl_snapshot {"hash":"6b4f50ee476446a6df15a5e8cddb6c14151c7f1d","type":"PACKAGE_SPEC","name":"EMK_UTILITIES_PKG","schemaName":"EMK_API","sxml":""}