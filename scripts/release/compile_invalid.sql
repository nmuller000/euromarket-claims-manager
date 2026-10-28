-- =============================================================================
-- scripts/release/compile_invalid.sql
-- Makes the objects of the connected schema valid again after a change (a
-- new package specification, a changed table) and stops if one stays
-- invalid, with its errors:
--   1. DBMS_UTILITY.COMPILE_SCHEMA recompiles the invalid objects in the
--      order of their dependencies (UTL_RECOMP would need SYSDBA; a change is
--      run by the owner of the schema).
--   2. A view that is still invalid is created again from its own definition
--      (DBMS_METADATA.GET_DDL, CREATE OR REPLACE: the grants stay). Needed
--      for the views with the SQL macro EMK_ROW_VERSION_PKG.format_row_version:
--      a recompile does not expand the macro (ORA-62565, PLS-00201), a CREATE
--      in the session of the owner does (P-47).
--   3. COMPILE_SCHEMA again (dependants of the views), then the check: no
--      invalid object, else the list of objects and of USER_ERRORS.
-- The test packages TEST_EMK_* are left out: tests/install_tests.sql installs
-- them again after a change.
--
-- Run as the owner of the schema (DEV: EMK_DEV[EMK_DATA] or EMK_DEV[EMK_API]);
-- called with @@ at the end of a change script, so it does not end with EXIT.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-28 (M1a step 7.8, P-47)
-- =============================================================================

PROMPT === Invalid objects of the schema: compile, create invalid views again, check
BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(schema => USER, compile_all => FALSE);
END;
/

DECLARE
    l_ddl CLOB;
BEGIN
    FOR r IN (SELECT object_name
              FROM   user_objects
              WHERE  object_type = 'VIEW' AND status <> 'VALID'
              ORDER  BY object_name) LOOP
        l_ddl := DBMS_METADATA.GET_DDL('VIEW', r.object_name);
        EXECUTE IMMEDIATE l_ddl;
        DBMS_OUTPUT.PUT_LINE('View created again from its definition: ' || r.object_name);
    END LOOP;
END;
/

BEGIN
    DBMS_UTILITY.COMPILE_SCHEMA(schema => USER, compile_all => FALSE);
END;
/

DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO l_count
    FROM   user_objects
    WHERE  status <> 'VALID' AND object_name NOT LIKE 'TEST\_EMK\_%' ESCAPE '\';

    IF l_count > 0 THEN
        FOR r IN (SELECT o.object_type, o.object_name,
                         (SELECT SUBSTR(LISTAGG(e.text, ' | ' ON OVERFLOW TRUNCATE) WITHIN GROUP (ORDER BY e.sequence), 1, 400)
                          FROM   user_errors e
                          WHERE  e.name = o.object_name AND e.type = o.object_type) AS errors
                  FROM   user_objects o
                  WHERE  o.status <> 'VALID' AND o.object_name NOT LIKE 'TEST\_EMK\_%' ESCAPE '\'
                  ORDER  BY o.object_type, o.object_name) LOOP
            DBMS_OUTPUT.PUT_LINE('INVALID ' || r.object_type || ' ' || r.object_name || ': ' || NVL(r.errors, '(no error text)'));
        END LOOP;
        RAISE_APPLICATION_ERROR(-20000, 'Invalid objects in ' || USER || ' (test packages excluded): ' || l_count
                                        || '. See the list above.');
    END IF;
    DBMS_OUTPUT.PUT_LINE('OK: invalid objects in ' || USER || ' (test packages excluded) = 0');
END;
/
