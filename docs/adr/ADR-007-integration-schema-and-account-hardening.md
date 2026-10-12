# ADR-007: Integration Schema and Account Hardening

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-10-07 |
| **Deciders** | Solution Architect (project owner) |
| **Related** | [spec.md](../spec.md) §1.3, §7, §12 · [ADR-005](ADR-005-deployment-and-database-setup.md) (amends the developer-account privileges) · [M1 plan](../plans/M1-plan.md) (M1b) · FR-03, FR-12, BR-14, SC-SEC-08 |

---

## Context

Milestone M1b loads external data (shipment files, ECB exchange rates) and extension X3 adds a REST API for claim intake. External input is the largest growing data set and the most exposed part of the system. With a single schema (`EMK_APP`), inbound data, its processing code and the operational tables share one owner, one tablespace and one set of privileges.

M0 also left the accounts with the `DEFAULT` profile, and the developer account `EMK_DEV` with `DB_DEVELOPER_ROLE`, although it only works in `EMK_APP` through proxy.

**Decision drivers**

| Driver | Source |
|--------|--------|
| Least privilege; grant to roles, keep schemas schema-only | Oracle Security Guide (see Sources) |
| External input must not reach operational tables directly; business rules live in one place | Spec §1.3 (ELT), CLAUDE.md, BR-01 to BR-14 |
| Inbound data grows without limit and must be purged by retention | Spec §12, FR-40 [EXT] |
| Privileges used by PL/SQL must be granted directly (roles are disabled in definer's-rights units) | Oracle Security Guide, PL/SQL Language Reference |
| Proxy accounts should hold `CREATE SESSION` only | Oracle Security Guide |
| Password policy based on a recognised baseline | CIS Benchmark (`ORA_CIS_PROFILE`, Oracle 23ai/26ai) |

---

## Options Considered

### Integration layer

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. Same schema** | Landing, processing and operational tables in `EMK_APP` | Simplest; no cross-schema grants | No boundary between external input and operational data; inbound growth shares the operational tablespace; the REST API would expose `EMK_APP` |
| **B. Integration schema with DML on operational tables** | `EMK_INT` owns landing and processing, and gets `INSERT/UPDATE` on `EMK_APP` tables | Separate growth and REST surface | Business rules duplicated or bypassed; broad cross-schema privileges |
| **C. Integration schema calling `EMK_APP` APIs only** | `EMK_INT` owns landing and processing and only has `EXECUTE` on `EMK_APP` APIs and types | Boundary for external input; one door to operational data; separate growth; REST API isolated (X3) | Cross-schema grants and collection types; two schemas to test |

### Staging design

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. One typed staging table per operational table** | `EMK_SHIPMENTS_STG`, `EMK_PARTIES_STG`… | Simple SQL | One inbound row usually feeds several tables (a shipment row carries shipper, carrier and consignee); every source format change needs `ALTER TABLE` |
| **B. One generic landing table, JSON only** | Whole row stored as JSON; code reads JSON paths | One table; format-independent | Code full of JSON paths; harder to read and validate |
| **C. Generic landing table + one view per source and version** | Row stored as JSON as received; `JSON_TABLE` views give typed columns per source version | One table and one pipeline for files, ECB and REST; format changes become a new view version; raw data kept for audit and reprocessing | More abstract; limited to the sources needed (two in M1b) to avoid over-design |

### Account hardening

| Option | Pros | Cons |
|--------|------|------|
| Keep `DEFAULT` for all accounts | No change | No baseline-based password policy for people |
| One strict profile for all accounts | Simple | Expiry or lockout of the ORDS service account stops the application (seen in P-11); session and idle limits break the ORDS connection pool |
| **Profile per account type** | Strict where useful; services stay available | Two profiles to explain |

---

## Decision

### 1. Integration schema `EMK_INT` (option C)

| Object | Rule |
|--------|------|
| `EMK_INT` | **Schema-only** (`NO AUTHENTICATION`); proxy from `EMK_DEV`; own tablespace **`EMK_INT_DATA`** (autoextend, maximum size in `00_config.sql`) |
| Contract | **One direction:** `EMK_INT` calls `EMK_APP` APIs; `EMK_APP` stored code never references `EMK_INT` |
| Privileges | Direct `EXECUTE` on the `EMK_APP` APIs and collection types it needs (no roles, no DML on operational tables) |
| References | **Private synonyms** in `EMK_INT` for `EMK_APP` objects; no schema prefix in the code; no public synonyms |
| Validation | **Technical** in `EMK_INT` (format, type, mandatory fields, ISO formats); **business** in `EMK_APP` APIs |
| Bulk interface | `EMK_APP` APIs accept a batch as a collection and return one result per row; set-based processing (`FORALL` / `MERGE`) |
| REST [X3] | Only `EMK_INT` is REST-enabled in ORDS; `EMK_APP` is never exposed |
| APEX | Primary schema stays `EMK_APP`; the import page calls `EMK_INT` intake with a granted `EXECUTE` and reads batch status through a granted view |

### 2. Generic landing with versioned source views (staging option C)

| Object | Purpose |
|--------|---------|
| `EMK_INBOUND_RECORDS` | One row per inbound record: batch, source, line, **payload `JSON` as received (never modified)**, status `PENDING → PROCESSING → LOADED / REJECTED`, errors, attempts. **Interval partitioning by month** for retention |
| `EMK_INBOUND_BATCHES` | One row per batch: source, file, user, counts, timestamps |
| `EMK_INBOUND_SOURCES` | Source contract: code, version, format, view, processing procedure |
| `EMK_V_IN_<SOURCE>_V<n>` | `JSON_TABLE` view per source version with safe conversions (`DEFAULT NULL ON CONVERSION ERROR`, ISO 8601) |
| `EMK_INBOUND_PKG` | Intake (`APEX_DATA_PARSER` for CSV/XLSX/JSON/XML), batch processing, status updates |
| Job per batch | `DBMS_SCHEDULER` job started after intake; calls the batch procedure; tests call the procedure directly |

M1b implements two sources: the shipment file and the ECB historical rates file.

### 3. Account hardening

| Account type | Accounts | Profile / privileges |
|--------------|----------|----------------------|
| People | `EMK_DEV` (and `DEV_USER`) | **`ORA_CIS_PROFILE`** (5 failed logins, 90-day lifetime, 5 grace days, reuse after 365 days and 20 changes, `ORA12C_VERIFY_FUNCTION`, lock after 120 inactive days, 10 sessions) |
| Proxy account | `EMK_DEV` | **`CREATE SESSION` only**; it works in `EMK_APP` / `EMK_INT` through proxy, where the privileges of the target schema apply. **Amends ADR-005**, which granted `DB_DEVELOPER_ROLE` |
| Services | `ORDS_PUBLIC_USER` | **`DEFAULT`** + controlled rotation (`rotate_ords_password.sql`, `check_password_expiry.sql`) |
| Schema-only | `EMK_APP`, `EMK_INT`, `UT3` | Not applicable (no password) |

Privileges that development needs in the proxy session (e.g., `DEBUG CONNECT SESSION`) are granted to the target schema. **To verify while building:** PL/SQL debugging from VS Code works in a proxy session.

### 4. Other rules

- No schema-wide grants (`… ANY TABLE ON SCHEMA`) on `EMK_APP` or `EMK_INT`; grants on specific views and APIs.
- Interval partitioning only for append-only, ever-growing tables (inbound records, logs, journals); operational tables are not partitioned at the design volume (spec §12.1).
- The SQLcl project exports both schemas (`schemas: EMK_APP, EMK_INT`) and partition clauses (`partitioning: true`); interval partition export behaviour to verify.

---

## Consequences

**Positive**
- External input is contained in a schema that cannot change operational data except through the business APIs.
- Business rules apply identically to the UI, file imports and the future REST API.
- Inbound growth is isolated in its own tablespace and purged by dropping monthly partitions.
- Raw inbound data is kept for audit and reprocessing; source format changes need a new view version, not a table change.
- Account policy follows Oracle guidance and the CIS baseline.

**Negative / trade-offs**
- More admin objects: tablespace, schema, proxy, grants, synonyms, profile assignment, verification and uninstall steps.
- Cross-schema collection types and grants must be maintained when APIs change.
- Two schemas to test; estimated extra effort 10–15 h (mostly M1b).
- `EMK_DEV` loses its own development privileges; all work happens through proxy.

---

## Sources

- Oracle AI Database Security Guide 26ai — [Schema-Only Accounts](https://docs.oracle.com/en/database/oracle/oracle-database/26/dbseg/schema-only-accounts.html)
- Oracle Database Security Guide — [Proxy User Accounts and the Authorization of Users to Connect Through Them](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/proxy-user-accounts-and-authorization-users-connect-them.html) · [Guidelines for Securing User Accounts and Privileges](https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/guidelines-securing-user-accounts-and-privileges.html)
- Oracle AI Database Security Guide 26ai — [Configuring Privilege and Role Authorization](https://docs.oracle.com/en/database/oracle/oracle-database/26/dbseg/configuring-privilege-and-role-authorization.html) (roles disabled in definer's-rights units)
- Oracle AI Database PL/SQL Language Reference 26ai — [Invoker's Rights and Definer's Rights](https://docs.oracle.com/en/database/oracle/oracle-database/26/lnpls/invokers-rights-and-definers-rights-authid-property.html)
- Oracle Database Security Guide — [Managing Security for Database Users](https://docs.oracle.com/en/database/oracle/oracle-database/23/dbseg/managing-security-for-oracle-database-users.html) (`ORA_CIS_PROFILE`) · [CREATE PROFILE](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/CREATE-PROFILE.html)
- Oracle AI Database Licensing Information 26 — [Oracle Partitioning: included option in Free](https://docs.oracle.com/en/database/oracle/oracle-database/26/dblic/Licensing-Information.html)
- Oracle APEX 24.2 API Reference — [APEX_DATA_PARSER](https://docs.oracle.com/en/database/oracle/apex/24.2/aeapi/APEX_DATA_PARSER.html)
- Oracle AI Database JSON Developer's Guide 26ai — [JSON data type](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/overview-json-oracle-ai-database.html)
- Oracle AI Database PL/SQL Packages and Types Reference 26ai — [DBMS_SCHEDULER](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/DBMS_SCHEDULER.html)

---

## Amendment (2026-10-07, before implementation)

- The personal account `DEV_USER` is **outside the project** (ADR-005) and is not changed: no profile, no grants, no scripts. "People" in §3 means `EMK_DEV` only.
