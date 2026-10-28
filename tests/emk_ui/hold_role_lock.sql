-- =============================================================================
-- tests/emk_ui/hold_role_lock.sql
-- Concurrency test through the application (D-73, browser test of step 7.9):
-- this script plays "another user who is saving a shipment". It locks the
-- role row of a company exactly as EMK_SHIPMENT_API does while it saves a
-- shipment (EMK_PARTY_API.lock_role), keeps the lock while you work in the
-- browser, and then releases it with ROLLBACK. Nothing is written.
--
-- In the browser, while this script waits:
--   1. remove that role from the company     -> "A shipment with this company
--                                               is being saved ... try again"
--   2. delete the company                     -> the same message
-- After pressing Enter here (lock released), repeat in the browser: the
-- change works, unless a real shipment uses the company in that role
-- ("Role ... is used by n shipment(s)").
--
-- Run from the repository root (DEV: through the proxy of EMK_UI):
--   sql -thin "EMK_DEV[EMK_UI]@localhost:1521/FREEPDB1" @tests/emk_ui/hold_role_lock.sql
-- Asks for the environment, the company name and the role. Refuses PROD.
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-21
-- =============================================================================

WHENEVER SQLERROR EXIT FAILURE ROLLBACK
SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON

-- PROD is not offered (tests never run there); the check below still refuses it.
ACCEPT emk_env CHAR PROMPT 'Environment (DEV, TEST or ACC): '
@@../../scripts/admin/00_config.sql

BEGIN
    IF '&emk_env' = 'PROD' THEN
        RAISE_APPLICATION_ERROR(-20000, 'Tests never run in PROD.');
    END IF;
    IF USER <> UPPER('&emk_ui_schema') THEN
        RAISE_APPLICATION_ERROR(-20000, 'Connect as the parsing schema: EMK_DEV[&emk_ui_schema], not ' || USER || '.');
    END IF;
END;
/

ACCEPT emk_party_name CHAR PROMPT 'Company name (exactly as in the application): '
ACCEPT emk_role_code  CHAR PROMPT 'Role to hold (e.g. CARRIER): '

DECLARE
    l_party_id &emk_api_schema..emk_v_parties.party_id%TYPE;
BEGIN
    SELECT party_id INTO l_party_id FROM &emk_api_schema..emk_v_parties WHERE name = q'[&emk_party_name]';   -- q-quote: a name with an apostrophe works
    IF NOT &emk_api_schema..emk_party_api.has_role(l_party_id, '&emk_role_code') THEN
        RAISE_APPLICATION_ERROR(-20000, 'The company does not have the role &emk_role_code.');
    END IF;
    &emk_api_schema..emk_party_api.lock_role(l_party_id, '&emk_role_code');
    DBMS_OUTPUT.PUT_LINE('LOCKED: role &emk_role_code of company ' || l_party_id || ' (' || q'[&emk_party_name]' || ').');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20000, 'No active company named ' || q'[&emk_party_name]' || '.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20000, 'More than one company named ' || q'[&emk_party_name]' || ': use a unique name.');
END;
/

PROMPT Now, in the browser: remove the role &emk_role_code from the company, or delete the company.
PAUSE  Expected: "... is being saved by another user: try again". Press Enter here to release the lock.

ROLLBACK;
PROMPT RELEASED: try again in the browser.
EXIT
