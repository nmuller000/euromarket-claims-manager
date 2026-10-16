-- =============================================================================
-- 10_create_encrypted_ts.sql
-- Creates the tablespaces of the separated schemas (ADR-008), encrypted
-- (ADR-011), in the data folder of the environment (00_config.sql, D-53):
--   &emk_data_ts  tables, journals and log (EMK_DATA, EMK_API)
--   &emk_int_ts   inbound data of the integration schema (EMK_INT)
-- Idempotent: an existing tablespace is left as it is; the check also reports
-- whether it is encrypted.
-- The keystore must be open (scripts/operations, migration phase M.1).
-- The data folder is created only when this client runs on the database server
-- itself; otherwise it is a prerequisite and the script stops with a message.
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

-- Keystore open: an encrypted tablespace cannot be created without it
DECLARE
    l_status v$encryption_wallet.status%TYPE;
BEGIN
    SELECT status INTO l_status FROM v$encryption_wallet WHERE ROWNUM = 1;
    IF l_status <> 'OPEN' THEN
        RAISE_APPLICATION_ERROR(-20005,
            'Keystore status ' || l_status || ': open the keystore first (ADR-011, scripts/operations).');
    END IF;
END;
/

-- Create the data folder when client and server are the same machine
SET TERMOUT OFF
COLUMN next_step NEW_VALUE next_step NOPRINT
-- client HOST may be DOMAIN\MACHINE or machine.domain: compare the short names
SELECT CASE WHEN UPPER(REGEXP_SUBSTR(SYS_CONTEXT('USERENV', 'SERVER_HOST'), '^[^.]+'))
                 = UPPER(REGEXP_SUBSTR(REGEXP_SUBSTR(SYS_CONTEXT('USERENV', 'HOST'), '[^\]+$'), '^[^.]+'))
            THEN '10a_create_data_folder.sql'
            ELSE '00_noop.sql' END AS next_step
FROM   dual;
SET TERMOUT ON
@@&next_step

DECLARE
    PROCEDURE create_tablespace (
        p_name    IN VARCHAR2,
        p_file    IN VARCHAR2,
        p_initial IN VARCHAR2,
        p_next    IN VARCHAR2,
        p_max     IN VARCHAR2
    ) IS
        l_count     PLS_INTEGER;
        l_encrypted dba_tablespaces.encrypted%TYPE;
        e_file_create EXCEPTION;             -- ORA-01119: error in creating database file
        PRAGMA EXCEPTION_INIT(e_file_create, -1119);
    BEGIN
        SELECT COUNT(*), MAX(encrypted)
        INTO   l_count, l_encrypted
        FROM   dba_tablespaces
        WHERE  tablespace_name = UPPER(p_name);

        IF l_count = 0 THEN
            BEGIN
                EXECUTE IMMEDIATE
                    'CREATE TABLESPACE ' || p_name
                    || ' DATAFILE ''&emk_datafile_dir.\' || p_file || ''''
                    || ' SIZE ' || p_initial || ' AUTOEXTEND ON NEXT ' || p_next || ' MAXSIZE ' || p_max
                    || ' ENCRYPTION USING ''&emk_tde_algorithm'' ENCRYPT';
            EXCEPTION
                WHEN e_file_create THEN
                    RAISE_APPLICATION_ERROR(-20003,
                        'Cannot create the data file in &emk_datafile_dir. '
                        || 'Create that folder on the database server and run again. ' || SQLERRM);
            END;
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' created (encrypted, &emk_tde_algorithm).');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Tablespace ' || p_name || ' already exists (encrypted: ' || l_encrypted || ').');
        END IF;
    END create_tablespace;
BEGIN
    create_tablespace('&emk_data_ts', '&emk_data_ts_file',
                      '&emk_data_ts_initial', '&emk_data_ts_next', '&emk_data_ts_max');
    create_tablespace('&emk_int_ts', '&emk_int_ts_file',
                      '&emk_int_ts_initial', '&emk_int_ts_next', '&emk_int_ts_max');
END;
/
