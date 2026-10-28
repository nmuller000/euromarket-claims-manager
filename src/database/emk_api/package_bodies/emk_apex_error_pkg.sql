create or replace package body emk_api.emk_apex_error_pkg as
    /**
     * Implementation of EMK_APEX_ERROR_PKG; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-22
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    c_unexpected       constant varchar2(30 char) := 'EMK_ERROR_UNEXPECTED';
    c_business_prefix  constant varchar2(30 char) := 'EMK_ERROR_';
    c_value_too_long   constant varchar2(30 char) := 'EMK_ERROR_ORA_12899';
    c_number_too_large constant varchar2(30 char) := 'EMK_ERROR_ORA_01438';

    -- Text of a message of the application; NULL if it does not exist. The
    -- documentation does not say what APEX_LANG.MESSAGE returns for a missing
    -- message, so the name itself, NULL and an exception all count as missing.
    function get_text (
        in_name in varchar2,
        in_p0   in varchar2 default null
    ) return varchar2 is
        l_text varchar2(4000 char);
    begin
        l_text := apex_lang.message(
            p_name => in_name,
            p0     => in_p0
        );
        return
            case
                when l_text is null
                     or l_text = in_name then
                    null
                else
                    l_text
            end;
    exception
        when others then
            return null;
    end get_text;

    -- Name of the message for an error raised by the database or the APIs; NULL if none applies
    function get_message_name (
        in_error in apex_error.t_error
    ) return varchar2 is
    begin
        return
            case
                when in_error.ora_sqlcode between - 20999 and - 20001 then
                    c_business_prefix || to_char(-in_error.ora_sqlcode)
                when in_error.ora_sqlcode in ( - 1, - 2091, - 2290, - 2291, - 2292 ) then
                    apex_error.extract_constraint_name(p_error => in_error)
                when in_error.ora_sqlcode = - 12899                   then
                    c_value_too_long
                when in_error.ora_sqlcode = - 1438                    then
                    c_number_too_large
            end;
    end get_message_name;

    -- Generic message with the number of a log entry that keeps the details
    function get_unexpected_text (
        in_error  in apex_error.t_error,
        in_reason in varchar2
    ) return varchar2 is
        l_log_id emk_log.log_id%type;
    begin
        l_log_id := emk_log_pkg.log_error(
            in_message     => in_reason,
            in_context     =>
                        json_object(
                            'apex_error_code' value in_error.apex_error_code,
                            'ora_sqlcode' value in_error.ora_sqlcode,
                            'page_item' value in_error.page_item_name,
                            'app_id' value apex_application.g_flow_id,
                            'page_id' value apex_application.g_flow_step_id
                        ),
            in_error_stack => in_error.ora_sqlerrm
                              || chr(10)
                              || in_error.error_backtrace
                              || chr(10)
                              || in_error.message
        );

        return nvl(
            get_text(c_unexpected,
                     to_char(l_log_id)),
            'Something went wrong. Please try again; if it happens again, give your administrator this reference: '
            || l_log_id
            || '.'
        );   -- English base text, in case the message itself is missing
    end get_unexpected_text;

    function handle_error (
        p_error in apex_error.t_error
    ) return apex_error.t_error_result is
        l_result       apex_error.t_error_result;
        l_message_name varchar2(255 char);
        l_text         varchar2(4000 char);
    begin
        l_result := apex_error.init_error_result(p_error => p_error);
        if p_error.is_internal_error then
            -- Access denied and session errors of APEX are understandable as they are
            if not p_error.is_common_runtime_error then
                l_result.message := get_unexpected_text(p_error, 'Internal APEX error');
                l_result.additional_info := null;
            end if;

        else
            l_message_name := get_message_name(p_error);
            l_text :=
                case
                    when l_message_name is not null then
                        get_text(l_message_name)
                end;
            if l_text is not null then
                l_result.message := l_text;
            elsif p_error.ora_sqlcode is not null then
                -- An error of the database or the APIs without its friendly text: never shown as it is
                l_result.message := get_unexpected_text(p_error,
                                                        'No friendly message for '
                                                        || nvl(l_message_name,
                                                               'ORA' || to_char(p_error.ora_sqlcode)));
            end if;
            -- An error without ORA code was raised by APEX with a text of the application (e.g. a page validation)

            l_result.additional_info := null;
            if
                l_result.page_item_name is null
                and l_result.column_alias is null
            then
                apex_error.auto_set_associated_item(
                    p_error        => p_error,
                    p_error_result => l_result
                );
            end if;

        end if;

        return l_result;
    end handle_error;

end emk_apex_error_pkg;
/


-- sqlcl_snapshot {"hash":"cd3fb913b4a99c1ffa5c0a2ef481b4b6228934e4","type":"PACKAGE_BODY","name":"EMK_APEX_ERROR_PKG","schemaName":"EMK_API","sxml":""}