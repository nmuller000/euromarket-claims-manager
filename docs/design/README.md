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
| Reference data | [data-model-reference.md](data-model-reference.md) | `EMK_APP` | M1a | Accepted v1.0 |
| Operational data | [data-model-operational.md](data-model-operational.md) | `EMK_APP` | M1a | Accepted v1.1 |
| Audit, logs and journals | [data-model-audit.md](data-model-audit.md) | `EMK_APP` | M1a | Accepted v1.0 |
| Integration | data-model-integration.md | `EMK_INT` | M1b | Not started |

## Common Rules (spec §1.3)

- Keys: `<entity>_id NUMBER GENERATED ALWAYS AS IDENTITY`; reference tables keyed by ISO code; named constraints (`<TABLE>_PK`, `_FK`, `_UK`, `_CK`); an index on every foreign key (a primary key whose leading column is the foreign key counts).
- Text `VARCHAR2(n CHAR)`; amounts `NUMBER(p,s)`; business dates `DATE`; technical timestamps `TIMESTAMP WITH TIME ZONE`; flags `<name>_yn CHAR(1 CHAR)` with a check `IN ('Y','N')`.
- Audit block on every table (above); soft delete and journals on operational tables; validity periods on reference tables; monthly interval partitioning on append-only tables.
- No tablespace or storage clauses in the DDL (default tablespace of the schema).
- Data formats follow international standards (spec §1.3 *Data formats*).
