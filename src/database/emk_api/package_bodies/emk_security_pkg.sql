create or replace package body emk_api.emk_security_pkg as

    function has_role (
        in_role_static_id in varchar2
    ) return boolean is
    begin
        -- Deny by default: no APEX session, no application or no user
        if sys_context('APEX$SESSION', 'APP_SESSION') is null
           or apex_application.g_flow_id is null
        or apex_application.g_user is null
        or in_role_static_id is null then
            return false;
        end if;

        return apex_acl.has_user_role(
            p_application_id => apex_application.g_flow_id,
            p_user_name      => apex_application.g_user,
            p_role_static_id => in_role_static_id
        );

    end has_role;

    procedure assert_role (
        in_role_static_id in varchar2
    ) is
    begin
        if not has_role(in_role_static_id) then
            emk_log_pkg.log_warn('Role check refused',
                                 json_object(
                             'role' value in_role_static_id,
                             'app_id' value apex_application.g_flow_id
                         )
            );

            raise_application_error(emk_errors_pkg.c_not_authorized,
                                    'Not authorized: role '
                                    || substr(in_role_static_id, 1, 30)
                                    || ' required');

        end if;
    end assert_role;

end emk_security_pkg;
/


-- sqlcl_snapshot {"hash":"68f9061c859f742c49f76f92e2c68605c5f19d22","type":"PACKAGE_BODY","name":"EMK_SECURITY_PKG","schemaName":"EMK_API","sxml":""}