create or replace package emk_api.emk_security_pkg as
    /**
     * Single place for role checks (BR-02, spec §7.1, D-33).
     * Wraps APEX_ACL.HAS_USER_ROLE for the application and user of the current
     * APEX session. Deny by default: without an APEX session every check
     * returns FALSE. The application id is taken from the session, never
     * hard-coded, so a deployment with another id (override_app_id) still works.
     * Defence in depth: APEX hides actions, the APIs enforce the rule here.
     *
     * @author Natalia Müller
     * @since  2026-10-08
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Static identifiers of the application roles (glossary, Application Roles)
    c_claims_handler constant varchar2(30 char) := 'CLAIMS_HANDLER';
    c_compliance_officer constant varchar2(30 char) := 'COMPLIANCE_OFFICER';
    c_analyst constant varchar2(30 char) := 'ANALYST';
    c_administrator constant varchar2(30 char) := 'ADMINISTRATOR';

    /**
     * Tells whether the user of the current APEX session has a role.
     *
     * @param  in_role_static_id role static identifier, e.g. c_claims_handler
     * @return TRUE if the role is assigned; FALSE without an APEX session or role
     * @usage  APEX authorization schemes (M1c)
     */
    function has_role (
        in_role_static_id in varchar2
    ) return boolean;

    /**
     * Raises "not authorized" unless the user of the current APEX session has
     * the role. The refusal is logged as WARN (without personal data; the
     * APEX user is recorded in EMK_LOG.created_by).
     *
     * @param  in_role_static_id role static identifier, e.g. c_claims_handler
     * @throws emk_errors_pkg.e_not_authorized role missing or no APEX session
     */
    procedure assert_role (
        in_role_static_id in varchar2
    );

end emk_security_pkg;
/


-- sqlcl_snapshot {"hash":"0c20de10eb25c86c34880d7c6e7829343e7c0d02","type":"PACKAGE_SPEC","name":"EMK_SECURITY_PKG","schemaName":"EMK_API","sxml":""}