# Physical Data Model

Physical design of the database objects of Release 1: tables, columns, types, constraints, indexes, partitioning and expected volumes, with the reason for every non-obvious choice. Conventions come from [spec §1.3](../spec.md) and [ADR-007](../adr/ADR-007-integration-schema-and-account-hardening.md); terms are in the [glossary](../glossary.md).

## Standard Audit Block

Defined **once** here; every table document only states which part applies ("audit block: created + updated", or "+ soft delete"). The columns go **at the end** of each table: business columns are read first, and Oracle does not store trailing `NULL` columns of a row (`updated_*` and `deleted_*` are mostly empty).

| Column | Type | Null | Default | Applies to | Set by |
|--------|------|------|---------|------------|--------|
| `created_at` | `TIMESTAMP WITH TIME ZONE` | No | `DEFAULT ON NULL SYSTIMESTAMP` | Every table | Default |
| `created_by` | `VARCHAR2(255 CHAR)` | No | `DEFAULT ON NULL` *user expression* | Every table | Default |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | Yes | — | Tables whose rows are updated | Trigger `<TABLE>_BU` |
| `updated_by` | `VARCHAR2(255 CHAR)` | Yes | — | Tables whose rows are updated | Trigger `<TABLE>_BU` |
| `deleted_yn` | `CHAR(1 CHAR)` | No | `DEFAULT ON NULL 'N'` | Operational tables only | API (soft delete, BR-13) |
| `deleted_by` | `VARCHAR2(255 CHAR)` | Yes | — | Operational tables only | API |
| `deleted_at` | `TIMESTAMP WITH TIME ZONE` | Yes | — | Operational tables only | API |

- **User expression** (spec §1.3): `COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'), SYS_CONTEXT('USERENV','PROXY_USER'), SYS_CONTEXT('USERENV','SESSION_USER'))` — the APEX user, otherwise the proxy user (`EMK_DEV`), otherwise the session user. A `DEFAULT` cannot call PL/SQL, so the same expression is written in the defaults and in the trigger.
- **Constraints** (operational tables): `<TABLE>_DELETED_YN_CK` `CHECK (deleted_yn IN ('Y','N'))` and `<TABLE>_DELETED_CK` `CHECK ((deleted_yn = 'N' AND deleted_at IS NULL AND deleted_by IS NULL) OR (deleted_yn = 'Y' AND deleted_at IS NOT NULL AND deleted_by IS NOT NULL))` — a row is either active or completely marked as deleted.
- **Trigger `<TABLE>_BU`** (`BEFORE UPDATE … FOR EACH ROW`): sets `updated_at := SYSTIMESTAMP` and `updated_by` with the user expression. Technical only, no business rules (spec §1.3).
- **Journals** of operational tables (previous row on update and delete) are designed in [data-model-audit.md](data-model-audit.md).
- **Not every table gets every part:** reference tables have no soft delete (validity periods instead); append-only tables (logs, history, journals) have only `created_*`.

## Source of Truth

| Phase | Source of truth for the structure | This folder keeps |
|-------|-----------------------------------|-------------------|
| **Before** the objects exist | These documents (reviewed and accepted per area) | Full column-level design |
| **After** the objects exist | The DDL exported by SQLcl `project` in `src/` | The **reasons**: decisions, volumes, partitioning, indexes. Column details are not maintained here; a design change gets a new version of the area document |

## Areas

| Area | Document | Schema | Milestone | Status |
|------|----------|--------|-----------|--------|
| Reference data | [data-model-reference.md](data-model-reference.md) | `EMK_DATA` | M1a | Accepted v1.4 |
| Operational data | [data-model-operational.md](data-model-operational.md) | `EMK_DATA` | M1a | Accepted v1.8 |
| Audit, logs and journals | [data-model-audit.md](data-model-audit.md) | `EMK_DATA`, `EMK_API` (log) | M1a | Accepted v1.3 |
| Personal data inventory (GDPR) | [personal-data.md](personal-data.md) | `EMK_DATA`, `EMK_API`, `EMK_INT` | M1a | Accepted v1.0 |
| Integration | data-model-integration.md | `EMK_INT` | M1b | Not started |
| PL/SQL APIs (architecture, packages, flows, views for the application) | [api-design.md](api-design.md) | `EMK_API` | M1a | Accepted v1.4 |

## Common Rules (spec §1.3)

- Keys: `<entity>_id NUMBER GENERATED ALWAYS AS IDENTITY`; reference tables keyed by ISO code; named constraints (`<TABLE>_PK`, `_FK`, `_UK`, `_CK`).
- **Indexes only after analysis** (D-72): each index is justified by a query that needs it or by Oracle's rule for foreign keys — index a foreign key unless the parent key is never updated or deleted ([Database Concepts 26ai, *Data Integrity*](https://docs.oracle.com/en/database/oracle/oracle-database/26/cncpt/data-integrity.html)); a primary key whose leading column is the foreign key counts. Foreign keys to code lists and other reference tables (keys never updated, rows never deleted) get no index unless a query needs one (D-72, D-81).
- **Partitions only after analysis** (D-72): only for tables that keep growing and are purged by period (logs, journals of operational tables, inbound records); never for small tables such as code lists and their journals.
- **Data scripts never overwrite production data** (D-72): reference data is loaded by insert-only `MERGE` scripts (missing rows only), added to a release once; a change to existing rows is a separate change script, run once, that cites the authorized change request (ITIL change enablement; Liquibase: roll forward, `runOnChange` not for data).
- **Business value lists are code lists:** a reference table with a validity period per list and a foreign key, never `CHECK (col IN (...))`; check constraints only for technical values set by programs (`Y`/`N` flags, journal operation, log level). A check cannot retire a value that old rows use; a validity period can (D-68, [reference data §6](data-model-reference.md#6-code-lists-d-68)).
- Text `VARCHAR2(n CHAR)`; amounts `NUMBER(p,s)`; business dates `DATE`; technical timestamps `TIMESTAMP WITH TIME ZONE`; flags `<name>_yn CHAR(1 CHAR)` with a check `IN ('Y','N')`.
- Audit block on every table (above); soft delete and journals on operational tables; validity periods on reference tables; monthly interval partitioning on append-only tables.
- No tablespace or storage clauses in the DDL (default tablespace of the schema).
- **Optional columns in check constraints need an explicit `IS NOT NULL`.** A check constraint is satisfied when its condition is TRUE **or unknown**, and every comparison with `NULL` (`=`, `<=`, `IN`, `BETWEEN`) is unknown. Example: `(claim_type = 'DAMAGE' AND damage_apparent_yn IN ('Y','N'))` accepts `DAMAGE` without the flag; write `damage_apparent_yn IS NOT NULL AND damage_apparent_yn IN ('Y','N')`. Found in M1a step 5 (BR-11, apparent flag, carriage charges); the tests run each negative case in its own savepoint.
- **REGEXP patterns in constraints use explicit character lists and the match parameter `'c'`, never ranges** (`[ABCDEFGHIJKLMNOPQRSTUVWXYZ]`, not `[A-Z]`). Oracle evaluates ranges with the session sort (`NLS_SORT`): with a linguistic sort such as `GERMAN`, `[A-Z]` also matches lower-case letters, so the same constraint accepts or rejects a value depending on the client. Character classes without ranges (`[:space:]`) are not affected. Found in M1a step 2 (tested with `GERMAN`, `BINARY_CI`, `GERMAN_AI`, `BINARY`).
- Data formats follow international standards (spec §1.3 *Data formats*).
