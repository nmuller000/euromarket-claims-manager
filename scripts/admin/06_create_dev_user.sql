-- =============================================================================
-- 06_create_dev_user.sql
-- Developer account &emk_dev_user (ADR-005, hardened by ADR-007):
--   - created if missing (password asked only then);
--   - CREATE SESSION only, granted directly; no roles (Oracle guideline for
--     proxy accounts: in a proxy session the privileges of the target schema apply);
--   - password profile &emk_dev_profile (CIS baseline);
--   - proxy access to &emk_app_schema and &emk_int_schema;
--   - &emk_dev_role (development privileges in the proxy session, e.g. debugging)
--     granted to the target schemas.
-- Order matters: CREATE SESSION is granted directly BEFORE the roles are
-- revoked, so the account never loses the right to log in.
-- The personal account DEV_USER is outside the project and is not touched.
-- Called by install_admin.sql (requires 00_config.sql).
--
-- Author: Natalia Müller
-- Since:  2026-10-06
-- =============================================================================

-- Ask for a password only when the account must be created
SET SQLFORMAT DEFAULT
COLUMN next_step NEW_VALUE next_step NOPRINT
SELECT CASE WHEN COUNT(*) = 0 THEN '06a_create_dev_account.sql'
            ELSE '00_noop.sql' END AS next_step
FROM   dba_users
WHERE  username = UPPER('&emk_dev_user');

@@&next_step

BEGIN
    DBMS_OUTPUT.PUT_LINE('Account &emk_dev_user is present.');
END;
/

-- 1. Log-in right granted directly (first, see header)
GRANT CREATE SESSION TO &emk_dev_user;

-- 2. Password profile for people
ALTER USER &emk_dev_user PROFILE &emk_dev_profile;

-- 3. Proxy: &emk_dev_user may connect as each schema (EMK_DEV[EMK_APP], EMK_DEV[EMK_INT])
DECLARE
    PROCEDURE grant_proxy (p_client IN VARCHAR2) IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   proxy_users
        WHERE  proxy  = UPPER('&emk_dev_user')
        AND    client = UPPER(p_client);

        IF l_count = 0 THEN
            EXECUTE IMMEDIATE 'ALTER USER ' || p_client || ' GRANT CONNECT THROUGH &emk_dev_user';
            DBMS_OUTPUT.PUT_LINE('Proxy &emk_dev_user -> ' || p_client || ' granted.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Proxy &emk_dev_user -> ' || p_client || ' already exists.');
        END IF;
    END grant_proxy;
BEGIN
    grant_proxy('&emk_app_schema');
    grant_proxy('&emk_int_schema');
END;
/

-- 4. Development privileges for the proxy sessions go to the target schemas
GRANT &emk_dev_role TO &emk_app_schema;
GRANT &emk_dev_role TO &emk_int_schema;

-- 5. The developer account holds no roles (removes DB_DEVELOPER_ROLE and
--    &emk_dev_role granted by earlier versions of this script)
BEGIN
    FOR r IN (SELECT granted_role
              FROM   dba_role_privs
              WHERE  grantee = UPPER('&emk_dev_user'))
    LOOP
        EXECUTE IMMEDIATE 'REVOKE ' || r.granted_role || ' FROM &emk_dev_user';
        DBMS_OUTPUT.PUT_LINE('Role ' || r.granted_role || ' revoked from &emk_dev_user.');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Account &emk_dev_user: CREATE SESSION only, profile &emk_dev_profile.');
END;
/
