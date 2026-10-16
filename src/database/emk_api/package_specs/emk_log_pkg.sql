create or replace package emk_api.emk_log_pkg as
    /**
     * Technical application log (spec §1.3 Logging, data-model-audit.md §3, D-33).
     * Every entry is written in an autonomous transaction, so it survives a
     * rollback of the caller. INFO, WARN and ERROR are always written; DEBUG
     * only when enabled for the session (set_level) or when the APEX session
     * runs in debug mode. A failure of the log itself is raised, never hidden.
     * Messages and context never contain personal data or secrets.
     * The module (PACKAGE.SUBPROGRAM of the caller) is taken from the call stack.
     *
     * @author Natalia Müller
     * @since  2026-10-08
     */

    c_debug constant varchar2(10 char) := 'DEBUG';
    c_info constant varchar2(10 char) := 'INFO';
    c_warn constant varchar2(10 char) := 'WARN';
    c_error constant varchar2(10 char) := 'ERROR';

    /**
     * Writes a DEBUG entry if DEBUG is enabled for the session or APEX debug is on.
     *
     * @param in_message short message (truncated to 1000 characters)
     * @param in_context optional JSON text, e.g. JSON_OBJECT('claim_id' VALUE l_id)
     */
    procedure log_debug (
        in_message in varchar2,
        in_context in varchar2 default null
    );

    /**
     * Writes an INFO entry.
     *
     * @param in_message short message (truncated to 1000 characters)
     * @param in_context optional JSON text
     */
    procedure log_info (
        in_message in varchar2,
        in_context in varchar2 default null
    );

    /**
     * Writes a WARN entry.
     *
     * @param in_message short message (truncated to 1000 characters)
     * @param in_context optional JSON text
     */
    procedure log_warn (
        in_message in varchar2,
        in_context in varchar2 default null
    );

    /**
     * Writes an ERROR entry with the error stack and backtrace of the current
     * exception. Call it inside an exception handler, then re-raise.
     *
     * @param in_message short message (truncated to 1000 characters)
     * @param in_context optional JSON text
     */
    procedure log_error (
        in_message in varchar2,
        in_context in varchar2 default null
    );

    /**
     * Sets the minimum level written in this database session.
     *
     * @param  in_level DEBUG, INFO, WARN or ERROR
     * @throws emk_errors_pkg.e_invalid_argument unknown level
     */
    procedure set_level (
        in_level in varchar2
    );

    /**
     * Returns the minimum level written in this database session.
     *
     * @return DEBUG, INFO, WARN or ERROR
     */
    function get_level return varchar2;

    /**
     * Drops the monthly partitions whose rows are all older than in_days days
     * (UTC). The initial partition P_INITIAL is never dropped. Runs in an
     * autonomous transaction because DROP PARTITION commits implicitly.
     *
     * @param  in_days retention in days (default 90)
     * @throws emk_errors_pkg.e_invalid_argument in_days below 1
     * @usage  Scheduled job (M2); test T-M1-28
     */
    procedure purge_entries (
        in_days in pls_integer default 90
    );

end emk_log_pkg;
/


-- sqlcl_snapshot {"hash":"de4110797e5ffebf783cef46380b80e509be26c2","type":"PACKAGE_SPEC","name":"EMK_LOG_PKG","schemaName":"EMK_API","sxml":""}