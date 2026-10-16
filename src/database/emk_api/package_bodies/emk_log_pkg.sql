create or replace package body emk_api.emk_log_pkg as

    g_level varchar2(10 char) := c_info;   -- minimum level of this session

    -- Numeric rank of a level; NULL for an unknown level.
    function get_rank (
        in_level in varchar2
    ) return pls_integer is
    begin
        return
            case in_level
                when c_debug then
                    1
                when c_info  then
                    2
                when c_warn  then
                    3
                when c_error then
                    4
            end;
    end get_rank;

    -- TRUE if an entry of this level must be written.
    function is_enabled (
        in_level in varchar2
    ) return boolean is
    begin
        return get_rank(in_level) >= get_rank(g_level)
        or (
            in_level = c_debug
            and apex_application.g_debug
        );
    end is_enabled;

    -- Inserts one entry and commits it independently of the caller.
    -- Call stack: 1 = write_entry, 2 = log_<level>, 3 = the caller.
    procedure write_entry (
        in_level       in varchar2,
        in_message     in varchar2,
        in_context     in varchar2,
        in_error_stack in clob
    ) is
        pragma autonomous_transaction;
        l_module emk_log.module%type;
    begin
        if utl_call_stack.dynamic_depth >= 3 then
            l_module := substr(
                utl_call_stack.concatenate_subprogram(utl_call_stack.subprogram(3)),
                1,
                200
            );
        end if;

        insert into emk_log (
            log_level,
            module,
            message,
            context,
            error_stack
        ) values ( in_level,
                   nvl(l_module, 'ANONYMOUS'),
                   substr(
                       nvl(in_message, '(no message)'),
                       1,
                       1000
                   ),
                   json(in_context),
                   in_error_stack );

        commit;
    exception
        when others then
            rollback;   -- end the autonomous transaction (avoids ORA-06519), then propagate (D-33)
            raise;
    end write_entry;

    procedure log_debug (
        in_message in varchar2,
        in_context in varchar2 default null
    ) is
    begin
        if is_enabled(c_debug) then
            write_entry(c_debug, in_message, in_context, null);
        end if;
    end log_debug;

    procedure log_info (
        in_message in varchar2,
        in_context in varchar2 default null
    ) is
    begin
        if is_enabled(c_info) then
            write_entry(c_info, in_message, in_context, null);
        end if;
    end log_info;

    procedure log_warn (
        in_message in varchar2,
        in_context in varchar2 default null
    ) is
    begin
        if is_enabled(c_warn) then
            write_entry(c_warn, in_message, in_context, null);
        end if;
    end log_warn;

    procedure log_error (
        in_message in varchar2,
        in_context in varchar2 default null
    ) is
    begin
        write_entry(c_error, in_message, in_context, dbms_utility.format_error_stack || dbms_utility.format_error_backtrace);
    end log_error;

    procedure set_level (
        in_level in varchar2
    ) is
    begin
        if get_rank(upper(in_level)) is null then
            raise_application_error(emk_errors_pkg.c_invalid_argument,
                                    'Unknown log level: '
                                    || substr(in_level, 1, 20));
        end if;

        g_level := upper(in_level);
    end set_level;

    function get_level return varchar2 is
    begin
        return g_level;
    end get_level;

    procedure purge_entries (
        in_days in pls_integer default 90
    ) is
        pragma autonomous_transaction;
        l_cutoff  date;
        l_dropped pls_integer := 0;
    begin
        if in_days is null
           or in_days < 1 then
            raise_application_error(emk_errors_pkg.c_invalid_argument, 'Retention must be at least 1 day');
        end if;

        l_cutoff := cast ( sys_extract_utc(systimestamp) as date ) - in_days;

        -- A partition can be dropped when its upper bound (exclusive) is not after the cutoff
        for p in (
            select
                partition_name
            from
                user_tab_partitions
            where
                    table_name = 'EMK_LOG'
                and partition_name <> 'P_INITIAL'
                and json_value(high_value_json, '$.high_value' returning date) <= l_cutoff
            order by
                partition_position
        ) loop
            execute immediate 'ALTER TABLE emk_log DROP PARTITION '
                              || dbms_assert.enquote_name(p.partition_name, false)
                              || ' UPDATE INDEXES';

            l_dropped := l_dropped + 1;
        end loop;

        commit;
        log_info('Log purge finished',
                 json_object(
                'retention_days' value in_days,
                             'cutoff_utc' value to_char(l_cutoff, 'YYYY-MM-DD"T"HH24:MI:SS'),
                             'partitions' value l_dropped
            )
        );

    end purge_entries;

end emk_log_pkg;
/


-- sqlcl_snapshot {"hash":"a29e189ab5b9aaa93b2ffe3ed1a87fc4e52923ff","type":"PACKAGE_BODY","name":"EMK_LOG_PKG","schemaName":"EMK_API","sxml":""}