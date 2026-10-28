create or replace package emk_api.emk_apex_error_pkg as
    /**
     * Error handling function of the APEX application (spec §1.3 Error
     * handling, step 7.8): every error a user sees is friendly and
     * understandable, never an ORA- code, a constraint name or a stack
     * (owner rule, 2026-10-22). The texts are text messages of the
     * application (Shared Components > Globalization > Text Messages),
     * maintained by the developer together with the rule they explain and
     * translated per language:
     *   - a business error -20001 … -20999 shows the message EMK_ERROR_<code>,
     *     e.g. EMK_ERROR_20402;
     *   - a constraint violation shows the message named as the constraint,
     *     e.g. EMK_SHIPMENTS_DATES_CK;
     *   - a value too long (ORA-12899) or a number too large (ORA-01438)
     *     shows EMK_ERROR_ORA_12899 or EMK_ERROR_ORA_01438;
     *   - any other error, or an error without its message, shows
     *     EMK_ERROR_UNEXPECTED with the number of a log entry (EMK_LOG) that
     *     keeps the details; access and session errors of APEX keep the text
     *     of APEX.
     * Based on the example of the APEX 24.2 API Reference ("Example of an
     * Error Handling Function"). The parameter is named p_error, not in_error,
     * because APEX fixes the signature of the function.
     *
     * @author Natalia Müller
     * @since  2026-10-22
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    /**
     * Turns an error into a friendly message for the user. Set as "Error
     * Handling Function" of the application: emk_api.emk_apex_error_pkg.handle_error.
     *
     * @param  p_error the error raised while APEX rendered or processed a page
     * @return the message to show, associated with the page item when it can
     *         be found
     */
    function handle_error (
        p_error in apex_error.t_error
    ) return apex_error.t_error_result;

end emk_apex_error_pkg;
/


-- sqlcl_snapshot {"hash":"3c1e125c0efdff548bacfdecbf462fbfaddc11bb","type":"PACKAGE_SPEC","name":"EMK_APEX_ERROR_PKG","schemaName":"EMK_API","sxml":""}