create or replace package body emk_api.emk_utilities_pkg as
    /**
     * Implementation of EMK_UTILITIES_PKG; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-20
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    function get_current_user return varchar2 is
    begin
        return coalesce(
            sys_context('APEX$SESSION', 'APP_USER'),
            sys_context('USERENV', 'PROXY_USER'),
            sys_context('USERENV', 'SESSION_USER')
        );
    end get_current_user;

    function is_changed (
        in_old in varchar2,
        in_new in varchar2
    ) return boolean is
    begin
        if
            in_old is null
            and in_new is null
        then
            return false;
        elsif in_old is null
              or in_new is null then
            return true;
        else
            return in_old <> in_new;
        end if;
    end is_changed;

    function is_changed (
        in_old in number,
        in_new in number
    ) return boolean is
    begin
        if
            in_old is null
            and in_new is null
        then
            return false;
        elsif in_old is null
              or in_new is null then
            return true;
        else
            return in_old <> in_new;
        end if;
    end is_changed;

    function is_changed (
        in_old in date,
        in_new in date
    ) return boolean is
    begin
        if
            in_old is null
            and in_new is null
        then
            return false;
        elsif in_old is null
              or in_new is null then
            return true;
        else
            return in_old <> in_new;
        end if;
    end is_changed;

    function is_valid_on (
        in_valid_from in date,
        in_valid_to   in date,
        in_on_date    in date
    ) return boolean is
    begin
        if in_valid_from is null
           or in_on_date is null then
            return false;   -- explicit: a comparison with NULL would return NULL
        end if;
        return
            in_valid_from <= in_on_date
            and ( in_valid_to is null
                  or in_valid_to >= in_on_date );
    end is_valid_on;

end emk_utilities_pkg;
/


-- sqlcl_snapshot {"hash":"fa8d20807e4ba53d2e201a0cb988b4c4ca04a655","type":"PACKAGE_BODY","name":"EMK_UTILITIES_PKG","schemaName":"EMK_API","sxml":""}