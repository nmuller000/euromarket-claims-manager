-- =============================================================================
-- 03_create_tablespace.sql
-- Creates the project tablespace &emk_tablespace if it does not exist.
-- Prerequisite: the folder &emk_datafile_dir exists on the DATABASE SERVER
-- (see docs/setup.md). Folders are not created from SQL because the datafile
-- is written by the database server, not by the SQLcl client.
-- Called by install_admin.sql (requires 00_config.sql).
-- =============================================================================

DECLARE
    l_count PLS_INTEGER;
    e_file_create EXCEPTION;                 -- ORA-01119: error in creating database file
    PRAGMA EXCEPTION_INIT(e_file_create, -1119);
BEGIN
    SELECT COUNT(*)
    INTO   l_count
    FROM   dba_tablespaces
    WHERE  tablespace_name = UPPER('&emk_tablespace');

    IF l_count = 0 THEN
        BEGIN
            EXECUTE IMMEDIATE
                'CREATE TABLESPACE &emk_tablespace'
                || ' DATAFILE ''&emk_datafile_dir.\&emk_datafile'''
                || ' SIZE &emk_ts_initial AUTOEXTEND ON NEXT &emk_ts_next MAXSIZE &emk_ts_max';
        EXCEPTION
            WHEN e_file_create THEN
                RAISE_APPLICATION_ERROR(-20003,
                    'Cannot create the datafile in &emk_datafile_dir. '
                    || 'Create that folder on the database server (docs/setup.md) and run again. '
                    || SQLERRM);
        END;
        DBMS_OUTPUT.PUT_LINE('Tablespace &emk_tablespace created.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace &emk_tablespace already exists.');
    END IF;
END;
/
