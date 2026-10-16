-- =============================================================================
-- check_password_expiry.sql
-- Lists database accounts whose password has expired or will expire soon,
-- so they can be rotated before ORDS/APEX stop working. Read-only.
--
-- Run as SYS in FREEPDB1 (SQLcl, thin driver):
--   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/check_password_expiry.sql
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-04
-- =============================================================================

SET VERIFY OFF
SET FEEDBACK OFF
SET SQLFORMAT ansiconsole

DEFINE warn_days = 30

PROMPT
PROMPT === Accounts expired or expiring within &warn_days days ===
SELECT u.username,
       u.account_status,
       TO_CHAR(u.expiry_date, 'YYYY-MM-DD')         AS expiry_date,
       TRUNC(u.expiry_date - SYSDATE)               AS days_left,
       CASE
         WHEN u.expiry_date < SYSDATE                 THEN 'EXPIRED - rotate now'
         WHEN u.expiry_date < SYSDATE + &warn_days    THEN 'Rotate soon'
       END                                          AS action,
       NVL2(p.proxy, 'Proxied by ' || p.proxy, NULL) AS used_via
FROM   dba_users u
LEFT   JOIN proxy_users p ON p.client = u.username
WHERE  u.expiry_date < SYSDATE + &warn_days
AND    (u.oracle_maintained = 'N'
        OR u.username IN ('ORDS_PUBLIC_USER', 'APEX_PUBLIC_USER',
                          'APEX_REST_PUBLIC_USER', 'APEX_LISTENER'))
ORDER  BY u.expiry_date;

PROMPT
PROMPT === All relevant accounts ===
SELECT u.username,
       u.account_status,
       TO_CHAR(u.expiry_date, 'YYYY-MM-DD') AS expiry_date,
       TRUNC(u.expiry_date - SYSDATE)       AS days_left,
       u.profile
FROM   dba_users u
WHERE  u.oracle_maintained = 'N'
OR     u.username IN ('SYS', 'SYSTEM', 'ORDS_PUBLIC_USER', 'APEX_PUBLIC_USER',
                      'APEX_REST_PUBLIC_USER', 'APEX_LISTENER')
ORDER  BY u.expiry_date NULLS LAST;

SET SQLFORMAT
SET FEEDBACK ON

EXIT
