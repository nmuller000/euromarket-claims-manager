-- =============================================================================
-- 00_set_password.sql
-- Asks for a password (hidden) and runs ONE statement that contains it:
--   &emk_pwd_stmt_head IDENTIFIED BY "<password>"&emk_pwd_stmt_tail
-- e.g. head = 'CREATE USER EMK_DEV', tail = ' PROFILE ORA_CIS_PROFILE'.
-- Called by the scripts that create accounts or change passwords. The caller
-- defines emk_pwd_stmt_head, emk_pwd_stmt_tail and emk_pwd_prompt, and pauses
-- its log (SPOOL OFF) before calling.
--
-- Fail-safe pattern: SQLcl repeats the text of a FAILED statement or PL/SQL
-- block in its error report, after substitution - with the password in it.
-- So the block that holds the password never ends in an error: it catches any
-- failure, prints only the Oracle message (which never contains the password)
-- and sets a flag. The password variable is then removed, and a second block
-- WITHOUT the password stops the run if the flag says so.
-- Accepted: 16+ characters of letters, digits and the safe special characters
-- - _ . ! # % + = : ? @ - so the password can never break the syntax of the block
-- (excluded: " ' ~ & \ $ and space). The profile ORA_CIS_PROFILE (people) uses
-- ORA12C_VERIFY_FUNCTION, which requires at least one special character.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-13
-- =============================================================================

VARIABLE emk_pwd_ok NUMBER
PROMPT Copy the password from the password manager only when the prompt appears
PROMPT (16+ characters: letters, digits and - _ . ! # % + = : ? @; at least one special
PROMPT character for personal accounts; no quotes, tilde, ampersand, backslash, dollar or space).
ACCEPT emk_pwd CHAR PROMPT '&emk_pwd_prompt: ' HIDE

DECLARE
    l_pwd VARCHAR2(200) := q'~&emk_pwd~';
BEGIN
    :emk_pwd_ok := 0;
    IF NVL(LENGTH(l_pwd), 0) < 16
       OR NOT REGEXP_LIKE(l_pwd, '^[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.!#%+=:?@-]+$', 'c')
    THEN
        DBMS_OUTPUT.PUT_LINE('Password not accepted: use 16+ characters of letters, digits and - _ . ! # % + = : ? @. Nothing changed.');
    ELSE
        EXECUTE IMMEDIATE '&emk_pwd_stmt_head IDENTIFIED BY "' || l_pwd || '"&emk_pwd_stmt_tail';
        :emk_pwd_ok := 1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        :emk_pwd_ok := 0;
        DBMS_OUTPUT.PUT_LINE('Password not set: ' || SQLERRM);
END;
/
UNDEFINE emk_pwd

BEGIN
    IF :emk_pwd_ok <> 1 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Password not set (reason above). Nothing was changed.');
    END IF;
END;
/
