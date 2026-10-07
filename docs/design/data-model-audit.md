# Data Model — Audit, Logs and Journals

| | |
|---|---|
| **Status** | Accepted v1.0 (2026-10-07) |
| **Date** | 2026-10-07 |
| **Schema** | `EMK_APP` |
| **Milestone** | M1a (plan steps 1, 3–5) |
| **Input** | [spec.md](../spec.md) v1.6 §1.3 (*Change history*, *Partitioning*, *Logging*), §4, FR-09 · [Standard audit block](README.md#standard-audit-block) · [Operational data](data-model-operational.md) |

Append-only tables: the application log, the business history of claim statuses, and one journal per operational table. Audit block: **created only** (rows are never updated). Logs and journals use monthly interval partitioning (spec §1.3).

## 1. Overview

| Table | Rows per year (estimate) | Partitioned | Retention in Release 1 | Purpose |
|-------|--------------------------|-------------|------------------------|---------|
| `EMK_LOG` | ≈ 500,000 | Monthly interval | **90 days** (purge by partition) | Technical log for troubleshooting (spec §1.3 *Logging*) |
| `EMK_CLAIM_STATUS_HISTORY` | ≈ 40,000 (≈ 4 transitions per claim) | No | Kept | Business history of statuses (spec §4); claim ageing and dashboards |
| `<TABLE>_JN` (6 journals) | Depends on updates; ≈ 1–2 per business row | Monthly interval | Kept (retention decided in X4) | Previous version of each updated or deleted row (FR-09) |

## 2. Partitioning Design

**Finding (Oracle documentation):** an interval-partitioned table needs **one** partitioning key column of type `NUMBER`, `DATE`, `FLOAT`, `TIMESTAMP` or `TIMESTAMP WITH LOCAL TIME ZONE`, and it cannot be `NULL`. `TIMESTAMP WITH TIME ZONE` — the type of our audit timestamps — **cannot** be the key. Interval partitioning is supported on a **virtual column** whose expression does not call PL/SQL.

| Option | Pros | Cons |
|--------|------|------|
| A. `created_at` as `TIMESTAMP WITH LOCAL TIME ZONE` in append-only tables | Partition on the audit column directly | Breaks the standard audit block (one exception per table type) |
| **B. Virtual column `created_on DATE` = UTC day of `created_at`** | Keeps the standard audit block; no storage (virtual); the partition boundaries are UTC days | One more column per table |
| C. Interval on the numeric id (e.g., every 1,000,000 rows) | Simple | Partitions are not aligned with time, so retention "older than 90 days" cannot drop whole partitions |

**Proposed: B.**

```sql
created_on DATE GENERATED ALWAYS AS (CAST(SYS_EXTRACT_UTC(created_at) AS DATE)) VIRTUAL
…
PARTITION BY RANGE (created_on) INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
  (PARTITION p_initial VALUES LESS THAN (DATE '2026-01-01'))
```

| Rule | Reason |
|------|--------|
| Initial partition `p_initial` below the first data | The highest partition of the range section cannot be dropped; an empty initial partition never needs to be |
| Other partitions are created **automatically** each month (system names) | No maintenance job for creating partitions |
| Purge: `ALTER TABLE … DROP PARTITION FOR (DATE '…') UPDATE INDEXES` | Removes a month in one metadata operation, without deleting row by row; with `UPDATE INDEXES` the global primary-key index stays valid (asynchronous global index maintenance, Oracle 12c+) |
| Primary key: **global** index on the id; lookup indexes **local** | A local unique index would need the partition key in the key; local lookup indexes are dropped together with their partition |
| To verify while building | The exact virtual-column expression compiles and partitions as expected; the SQLcl export keeps the partitioning clause (`partitioning: true`) — test T-M1-28 |

## 3. `EMK_LOG`

| Column | Type | Null | Rule / reason |
|--------|------|------|---------------|
| `log_id` | `NUMBER` | No | **PK**, identity |
| `log_level` | `VARCHAR2(10 CHAR)` | No | `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `module` | `VARCHAR2(200 CHAR)` | No | `PACKAGE.SUBPROGRAM` that wrote the entry |
| `message` | `VARCHAR2(1000 CHAR)` | No | Short message |
| `context` | `JSON` | Yes | Technical context (ids, parameters, APEX app/page/session). **No personal data, no secrets** |
| `error_stack` | `CLOB` | Yes | `DBMS_UTILITY.FORMAT_ERROR_STACK` + `FORMAT_ERROR_BACKTRACE` for errors |
| *audit block* | — | — | `created_at`, `created_by` |
| `created_on` | `DATE` (virtual) | — | Partition key (§2) |

| Constraint / index | Definition |
|--------------------|------------|
| `EMK_LOG_PK` | `PRIMARY KEY (log_id)` (global index) |
| `EMK_LOG_LEVEL_CK` | `log_level IN ('DEBUG','INFO','WARN','ERROR')` |
| Partitioning | Monthly interval on `created_on`; purge after 90 days |

**Rules:** written by `EMK_LOG_PKG` in an **autonomous transaction**, so entries survive a rollback (spec §1.3). Messages never contain personal data or passwords (GDPR data minimisation; spec §1.3 *Secrets*). **Why 90 days:** long enough to investigate incidents, short enough to limit stored user identifiers.

## 4. `EMK_CLAIM_STATUS_HISTORY`

| Column | Type | Null | Rule / reason |
|--------|------|------|---------------|
| `history_id` | `NUMBER` | No | **PK**, identity |
| `claim_id` | `NUMBER` | No | FK `EMK_CLAIMS` (claims are never physically deleted) |
| `from_status` | `VARCHAR2(20 CHAR)` | Yes | `NULL` for the creation of the claim (→ `DRAFT`) |
| `to_status` | `VARCHAR2(20 CHAR)` | No | New status |
| `reason` | `VARCHAR2(1000 CHAR)` | Yes | Optional comment (e.g., reason for a rejection) |
| *audit block* | — | — | `created_at`, `created_by` = **when and who** changed the status |

| Constraint / index | Definition | Reason |
|--------------------|------------|--------|
| `EMK_CLAIM_STATUS_HISTORY_PK` | `PRIMARY KEY (history_id)` | |
| `…_CLAIMS_FK` | FK to `EMK_CLAIMS` | |
| `…_FROM_CK`, `…_TO_CK` | Same status list as `EMK_CLAIMS.status` | |
| `…_CLAIM_IX` | `(claim_id, created_at)` | History of one claim in order; also serves the foreign key |

Written by `EMK_CLAIM_API` in the same transaction as the status change (spec §4). **Not partitioned** (small) and **never purged** (business history used for ageing KPIs). The spec diagram names the columns `changed_at` / `changed_by`; the audit block already holds them as `created_at` / `created_by` (no duplicate columns). Decided: open point 3.

## 5. Journal Tables `<TABLE>_JN`

One journal per operational table: `EMK_PARTIES_JN`, `EMK_PARTY_ROLES_JN`, `EMK_CONTACTS_JN`, `EMK_SHIPMENTS_JN`, `EMK_CLAIMS_JN`, `EMK_CLAIM_DOCUMENTS_JN`.

| Column | Type | Null | Rule / reason |
|--------|------|------|---------------|
| `jn_id` | `NUMBER` | No | **PK**, identity |
| `jn_operation` | `CHAR(1 CHAR)` | No | `U` = update, `D` = delete |
| `jn_at` | `TIMESTAMP WITH TIME ZONE` | No | `DEFAULT ON NULL SYSTIMESTAMP`: when the change happened |
| `jn_by` | `VARCHAR2(255 CHAR)` | No | User expression of the audit block: who made the change |
| `jn_on` | `DATE` (virtual) | — | UTC day of `jn_at`; partition key (§2) |
| *all columns of the base table* | Same types | Yes | The **previous** values (`:OLD`), including its audit columns; no constraints |

| Constraint / index | Definition | Reason |
|--------------------|------------|--------|
| `<TABLE>_JN_PK` | `PRIMARY KEY (jn_id)` (global) | |
| `<TABLE>_JN_OP_CK` | `jn_operation IN ('U','D')` | |
| `<TABLE>_JN_KEY_IX` (local) | `(<entity>_id, jn_at)` | "Previous values of row X" in order |
| No foreign keys | — | The journal must keep its rows whatever happens to the base rows |

**Trigger `<TABLE>_JN_AUD`:** `AFTER UPDATE OR DELETE … FOR EACH ROW`, inserts `:OLD` with the operation, time and user. Technical only (spec §1.3).

| Design rule | Reason |
|-------------|--------|
| **Inserts are not journaled** | The current row holds the latest values and the first journal row holds the values before the first change, so every version can be rebuilt; journaling inserts would duplicate every row |
| **`EMK_CLAIM_DOCUMENTS_JN` excludes `content` and `extracted_text`** | Copying the BLOB on every update (e.g., a soft delete) would double the storage. The file of a document is **immutable** (the API does not replace it; a new file is a new document row) |
| `EMK_CONTACTS_JN` holds personal data | Erasure and pseudonymisation (FR-41, X4) must also process this journal |
| Journal columns mirror the base table | When a column is added to a base table, it is added to its journal and trigger in the same change (checklist item) |

## 6. Open Points

| # | Point | Decision (2026-10-07) |
|---|-------|----------|
| 1 | Partition key for append-only tables | **Decided: B** — virtual UTC date column (§2) |
| 2 | Retention in Release 1 | **Decided:** `EMK_LOG` 90 days (purge procedure in `EMK_LOG_PKG`, tested in T-M1-28; a scheduled job comes with the other jobs in M2); journals and status history kept; legal retention periods decided in X4 (FR-40) |
| 3 | Column names of the status history | **Decided:** use the audit block (`created_at`, `created_by`) instead of `changed_at`, `changed_by`; spec diagram updated (v1.7) |
| 4 | Journals only on update and delete | **Decided: yes** (§5) |
| 5 | Document journal without the file | **Decided: yes**; file content immutable (§5) |
| 6 | Log content | **Decided:** `context` as `JSON`; no personal data or secrets in logs |

## 7. Sources

- Oracle VLDB and Partitioning Guide — [Creating Interval-Partitioned Tables](https://docs.oracle.com/database/121/VLDBG/GUID-F83CB777-F92C-43AB-A20D-EB2BCC82C32C.htm) · [Partition Administration (26ai)](https://docs.oracle.com/en/database/oracle/oracle-database/26/vldbg/partition-admin.html) · [Using Virtual Column-Based Partitioning](https://docs.oracle.com/database/121/VLDBG/GUID-AF6D08D7-5E0F-4E08-B682-74CCCAEC64D1.htm) · [Dropping Table Partitions](https://docs.oracle.com/database/121/VLDBG/GUID-9E40E1DD-2844-4298-8897-86ED66F293DB.htm) · [Asynchronous Global Index Maintenance](https://docs.oracle.com/database/121/VLDBG/GUID-087B87A6-959A-40C6-82AF-36E401FD089B.htm)
- Oracle SQL Language Reference 26ai — [CREATE TABLE](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlrf/CREATE-TABLE.html)
- Oracle JSON Developer's Guide 26ai — [JSON data type](https://docs.oracle.com/en/database/oracle/oracle-database/26/adjsn/overview-json-oracle-ai-database.html)
