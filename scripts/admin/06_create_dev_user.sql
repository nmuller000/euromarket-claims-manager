-- =============================================================================
-- 06_create_dev_user.sql
-- Developer account &emk_dev_user: created if missing (password asked only then),
-- granted the developer roles, and allowed to work in &emk_app_schema through
-- proxy authentication. The personal account DEV_USER is not touched.
-- Called by install_admin.sql (requires 00_config.sql).
-- =============================================================================

-- Ask for a password only when the account must be created
SET SQLFORMAT
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

GRANT DB_DEVELOPER_ROLE, &emk_dev_role TO &emk_dev_user;

-- Proxy: &emk_dev_user may connect as &emk_app_schema (EMK_DEV[EMK_APP])
DECLARE
    l_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO   l_count
    FROM   proxy_users
    WHERE  proxy  = UPPER('&emk_dev_user')
    AND    client = UPPER('&emk_app_schema');

    IF l_count = 0 THEN
        EXECUTE IMMEDIATE 'ALTER USER &emk_app_schema GRANT CONNECT THROUGH &emk_dev_user';
        DBMS_OUTPUT.PUT_LINE('Proxy &emk_dev_user -> &emk_app_schema granted.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Proxy &emk_dev_user -> &emk_app_schema already exists.');
    END IF;
END;
/
