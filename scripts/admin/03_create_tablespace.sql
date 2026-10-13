-- =============================================================================
-- 03_create_tablespace.sql
-- Creates the project tablespaces if they do not exist:
--   &emk_tablespace     application data (EMK_APP; single-schema layout, DEV only, retired in M.4)
--   &emk_int_tablespace inbound data of the integration schema (EMK_INT, ADR-007)
-- Prerequisite: the folder &emk_legacy_datafile_dir exists on the DATABASE SERVER
-- (see docs/setup.md). Folders are not created from SQL because the datafile
-- is written by the database server, not by the SQLcl client.
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-06
-- =============================================================================

DECLARE
    PROCEDURE create_tablespace (
        p_name    IN VARCHAR2,
        p_file    IN VARCHAR2,
        p_initial IN VARCHAR2,
        p_next    IN VARCHAR2,
        p_max     IN VARCHAR2
    ) IS
        l_count PLS_INTEGER;
        e_file_create EXCEPTION;             -- ORA-01119: error in creating database file
        PRAGMA EXCEPTION_INIT(e_file_create, -1119);
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_tablespaces
        WHERE  tablespace_name = UPPER(p_name);

        IF l_count = 0 THEN
            BEGIN
                EXECUTE IMMEDIATE
                    'CREATE TABLESPACE ' || p_name
                    || ' DATAFILE ''&emk_legacy_datafile_dir.\' || p_file || ''''
                    || ' SIZE ' || p_initial || ' AUTOEXTEND ON NEXT ' || p_next || ' MAXSIZE ' || p_max;
            EXCEPTION
                WHEN e_file_create THEN
                    RAISE_APPLICATION_ERROR(-20003,
                        'Cannot create the datafile in &emk_legacy_datafile_dir. '
                        || 'Create that folder on the database server (docs/setup.md) and run again. '
                        || SQLERRM);
            END;
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' created.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' already exists.');
        END IF;
    END create_tablespace;
BEGIN
    create_tablespace('&emk_tablespace', '&emk_datafile',
                      '&emk_ts_initial', '&emk_ts_next', '&emk_ts_max');
    create_tablespace('&emk_int_tablespace', '&emk_int_datafile',
                      '&emk_int_ts_initial_old', '&emk_int_ts_next_old', '&emk_int_ts_max_old');
END;
/
