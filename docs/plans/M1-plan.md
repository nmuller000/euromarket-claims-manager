# Plan — M1 Claims Core

| | |
|---|---|
| **SDLC stage** | 3 — Build ([docs/sdlc.md](../sdlc.md)) |
| **Status** | Accepted v1.20 (2026-10-21); v1.19 (2026-10-21) |
| **Owner** | Natalia Müller ([@nmuller000](https://github.com/nmuller000)) |
| **Date** | 2026-10-06 |
| **Input** | [spec.md](../spec.md) v1.15 §1.3, §2.1, §2.7, §3, §4, §7, §8 · [ADR-005](../adr/ADR-005-deployment-and-database-setup.md) · [ADR-007](../adr/ADR-007-integration-schema-and-account-hardening.md) · [ADR-008](../adr/ADR-008-schema-separation.md) to [ADR-011](../adr/ADR-011-tablespace-encryption.md) · [M0 plan](M0-plan.md) |
| **Branches** | `feature/m1a-data-core`, `feature/m1b-import`, `feature/m1c-apex-app` |

## 1. Goal

Deliver the claims core (F-01 to F-04): the operational data model, the PL/SQL APIs that enforce the business rules, shipment import through the integration schema, and the APEX application with roles and dashboards, all versioned with the SQLcl project and covered by utPLSQL tests.

## 2. Scope and Increments

M1 is delivered in three increments. Each has its own branch, tests and pull request; the milestone is done when all three are merged.

| Increment | Content | Features / Requirements | Rules |
|-----------|---------|-------------------------|-------|
| **M1a — Data core** | **Physical data model design (approved before any table is created)**; admin layer extension (`EMK_INT`, `EMK_INT_DATA`, profiles, `EMK_DEV` privileges, ADR-007); migration to the separated schemas (step M, ADR-008 to ADR-011); reference and operational tables, audit triggers and journals (partitioned); `EMK_ERRORS`, `EMK_LOG_PKG`, `EMK_SECURITY_PKG`, `EMK_PARTY_API`, `EMK_SHIPMENT_API`, `EMK_CLAIM_API` (state machine); APEX application 200 **skeleton with its roles**; synthetic data generator; unit tests | F-01, F-02 (data) · FR-01, 02, 04, 05, 09 | BR-01 to 04, 11, 13, 16, 17 |
| **M1b — Import** | Integration schema `EMK_INT`: generic landing (`EMK_INBOUND_RECORDS`, JSON as received, partitioned), batches, source contracts, versioned source views, `EMK_INBOUND_PKG`, job per batch; batch APIs in `EMK_API`; two sources: shipment file and ECB rates | F-03 · FR-03 | BR-12 (rates), BR-14 |
| **M1c — APEX app** | Application 200 pages on the M1a skeleton: authorization schemes, parties, shipments, claims and documents, file import with batch status, KPI views in EUR and dashboards; export through the SQLcl project | F-01 to F-04 (UI) · FR-08 | BR-02 (UI), BR-12 |

| Not in M1 | Milestone |
|-----------|-----------|
| CMR deadlines, public holidays, alerts, email, network ACL | M2 |
| Legal search (corpus, ONNX model, HNSW) | M3 |
| Letters, SDR rates, liability cap (BR-10) | M4 |
| German translation, security checklist, volume test | M5 |
| REST API in `EMK_INT` (ORDS + OAuth2) | X3 |
| **Deferred 2026-10-16 (focus on the MVP components of the intent):** phase M.5 — PDB `EMKTEST` built from the repository, first deployment by `EMK_DEPLOY`, flashback of a failed deployment, restore drill — with tests T-M1-01, T-M1-31, T-M1-33 and open points 10 and 11 | M5 (MVP release), if time allows; otherwise an improvement after Release 1 |
| First `project stage` (release changelog for all schemas) with the reference data scripts and the column privileges of `EMK_API` (`scripts/release/emk_data_column_grants.sql`; SQLcl project export writes no column privileges, D-82) added by `add-custom` (open point 6): `stage` compares Git branches and its result is only proven by a deployment, which is phase M.5 | M5, with phase M.5 |
| Environments ACCEPTANCE and PROD (ADR-009) | Improvement (growth path); the MVP is built in DEV only |
| Unit tests for every check of steps 1–6 (M.3 ports only the key checks) | Improvement |
| Test of `EMK_SECURITY_PKG` with an APEX session (needs workspace access for the calling schema) | Step 8, with `EMK_CLAIM_API` |
| Separate test schema (`EMK_TEST`) instead of tests in the schema of the tested objects | Improvement (larger teams) |
| Automatic check of the PL/SQL and SQL code against the Trivadis coding guidelines (db\* CODECOP), instead of a manual review | M5 (quality checklist of the release), otherwise improvement |

## 3. Conventions (spec §1.3, §7)

- Keys: `<entity>_id NUMBER GENERATED ALWAYS AS IDENTITY`; reference tables keyed by ISO code with `valid_from` / `valid_to`.
- Every table: `created_*`; updated tables: `updated_*` (technical `BEFORE UPDATE` trigger); operational tables: `deleted_yn` + journal `<TABLE>_JN` (`AFTER UPDATE OR DELETE` trigger).
- Monthly interval partitioning only for append-only tables: `EMK_INBOUND_RECORDS`, `EMK_LOG`, `<TABLE>_JN`.
- Flags `<name>_yn CHAR(1)`; named constraints; indexes and partitions only where an analysis justifies them (D-72); `COMMENT ON` for tables and non-obvious columns.
- Schemas (ADR-008): tables in `EMK_DATA`, code and views in `EMK_API`, `EMK_UI` owns nothing, inbound data in `EMK_INT`; another schema's objects with **schema-qualified names**, no synonyms; object grants from the owner (`EMK_DATA` → `EMK_API`, `EMK_API` → `EMK_UI` / `EMK_INT`), no schema-wide grants. Every change that adds a table, view or API includes its grants.
- PL/SQL: parameters `in_` / `out_` / `io_`; business errors `-20001…-20999` from `EMK_ERRORS_PKG`; no `COMMIT` in APIs (except the autonomous log and batch jobs); no nested subprograms in application code; privileges used in PL/SQL granted directly (roles are disabled in definer's-rights code).

## 4. Work Order

Application objects are created in `EMK_DATA`, `EMK_API` and `EMK_INT` (DEV: one proxy per schema, `EMK_DEV[EMK_DATA]`, `EMK_DEV[EMK_API]`, `EMK_DEV[EMK_INT]`; the APEX application through `EMK_DEV[EMK_UI]`, its parsing schema), exported per schema with `project export` to `src/database/`, and staged with `project stage` to `dist/releases/next/` as one release for all schemas, deployed by `EMK_DEPLOY` (ADR-008 §5). Partition clauses are exported (`partitioning: true`). Steps 0–6 were built in the single schema `EMK_APP` and are moved by step M. Tests and the data generator live in `tests/` and are not part of the release artifact.

### 4.1 M1a — Data core

| # | Objects | Purpose | Depends on |
|---|---------|---------|------------|
| D | `docs/design/`: README (standard audit block, common rules), `data-model-reference.md`, `data-model-operational.md`, `data-model-audit.md` | **Physical data model** per area: every table with columns, types, sizes, constraints, indexes, partitioning, journals and expected volumes; each area reviewed and **accepted before its tables are created** | — |
| A | Admin layer extension (`scripts/admin`): tablespace `EMK_INT_DATA` (replaced by the encrypted `EMK_INT_TS` in phase M.2), schema-only `EMK_INT` with proxy from `EMK_DEV`, `ORA_CIS_PROFILE` for `EMK_DEV`, `EMK_DEV` reduced to `CREATE SESSION`, privileges needed in the proxy sessions granted to the target schemas; `verify_admin.sql` and `uninstall_admin.sql` updated | ADR-007; the proxy session to `EMK_INT` exists before M1b | — |
| 0 | APEX application 200 skeleton (`EMK_CLAIMS`): first check that ID 200 is free in the instance (`apex_applications`; if taken, choose another ID and record it); empty application with the four roles of spec §7.1 (`CLAIMS_HANDLER`, `COMPLIANCE_OFFICER`, `ANALYST`, `ADMINISTRATOR`), exported with `project export` | The roles exist before the APIs and tests that check them (BR-02) and before the generator, which changes statuses through the API | A |
| 1 | `EMK_ERRORS` (renamed `EMK_ERRORS_PKG` in phase M.3), `EMK_LOG` (partitioned) + `EMK_LOG_PKG`, `EMK_SECURITY_PKG` | Error codes; application log (autonomous transaction); `has_role` over `APEX_ACL.HAS_USER_ROLE` (single place for role checks) | D, 0 |
| 2 | `EMK_COUNTRIES`, `EMK_COUNTRY_NAMES`, `EMK_CURRENCIES`, `EMK_CURRENCY_NAMES` + reference data (`MERGE` scripts, `project stage add-custom`) | ISO reference data with validity periods; German names in translation tables (F-15, M4 letters) | D |
| 3 | `EMK_PARTIES`, `EMK_PARTY_ROLES`, `EMK_CONTACTS` (+ `_JN` partitioned, triggers) | Companies, their roles (BR-16) and contact persons (PII isolated) | 2 |
| 4 | `EMK_SHIPMENTS` (+ `_JN`, triggers) | Shipments; `cmr_note_no` unique including soft-deleted rows (BR-03) | 2, 3 |
| 5 | `EMK_CLAIMS`, `EMK_CLAIM_DOCUMENTS`, `EMK_CLAIM_STATUS_HISTORY` (+ `_JN`, triggers) | Claims, documents (BLOB), status history; amount check constraints (BR-11) | 4 |
| 6 | `EMK_EXCHANGE_RATES` | Daily ECB rates (filled in M1b) | 2 |
| M | **Migration to the separated schemas** ([ADR-008](../adr/ADR-008-schema-separation.md) to [ADR-011](../adr/ADR-011-tablespace-encryption.md)), branch `feature/m1a-schema-separation`, phases below | Steps 7–12 are built on the final architecture | 0–6 |
| 7 | `EMK_PARTY_API`, `EMK_SHIPMENT_API` (7.1–7.3), views and grants (7.4), application-context test (7.5); **7.6 code lists** (D-68 to D-74): `EMK_LANGUAGES`, `EMK_PARTY_ROLE_TYPES`, `EMK_CLAIM_STATUSES`, `EMK_CLAIM_TYPES`, `EMK_DOCUMENT_TYPES`, `EMK_FILE_TYPES`, `EMK_FILE_EXTENSIONS` replace the value lists in check constraints, with insert-only data scripts, journals and views; common packages `EMK_CODES_PKG`, `EMK_UTILITIES_PKG`, `EMK_ROW_VERSION_PKG`; language and at least one role required; role locks between shipments and companies; shipments: declared value and special interest in delivery (D-78), date of the consignment note (required) and date of disposal (D-79); **7.7** master data API `EMK_MASTER_DATA_API` (administrator only, checked in the API; adds party roles and document types; retires, never deletes or re-codes; codes named by the rules protected; D-82); **7.8** APEX pages (companies, shipments, master data, restore, technical log; error handling function; demo users per role); **7.9** browser test with screenshots (T-M1-39 included); **7.10** documentation and pull request | Create, update, soft delete (BR-13), restore (D-39); party roles (BR-16); CMR applicability (BR-17); values that can be retired while old records keep them; file type allowlist for step 8 (BR-18); an application that can be used | 3, 4, 5 |
| 8 | `EMK_CLAIM_API` + sequence `EMK_CLAIM_NO_SEQ` | Create claim (`claim_no` = `CLM-YYYY-NNNNNN`, BR-04, BR-11), state machine (BR-01, BR-02 through `EMK_SECURITY_PKG`), status history, soft delete; documents with the file checks of BR-18 (allowlist, extension and content signature, [api-design §9](../design/api-design.md#9-claim-documents-file-checks-br-18-built-in-step-8)); wilful misconduct flag `wilful_misconduct_yn` (D-75, spec §5.3); claimant, shipper or consignee of the shipment (BR-19, D-76); partial admission, settlement date and `EMK_CLAIM_RECOVERIES` (payments, corrections by negative entries, conversion at the ECB rate of the payment day), interest view (BR-11, D-77); role `INSURER` in `EMK_CODES_PKG` (protected, D-82) | 1, 5, 7 |
| 9 | Views `EMK_V_PARTIES`, `EMK_V_SHIPMENTS`, `EMK_V_CLAIMS` | Active rows only (`deleted_yn = 'N'`) | 3–5 |
| 10 | `tests/`: `TEST_EMK_*` suites, `install_tests.sql`, `run_tests.sql` | Unit tests; one command per schema (SC-QA-02); coverage report. **Started in phase M.3** (suites of steps 1–6, install and run scripts); every new API adds its suite | 1–9 |
| 11 | `tests/`: `EMK_DATA_GEN_PKG` | Synthetic data with a fixed seed (≈ 500 shipments, 100 claims by default); with it, measure the restore page (`EMK_V_DELETED_RECORDS` reads every shipment) at the design volume before deciding an index (D-74) | 3–8 |
| 12 | `project.filters`, `project.config.json` | Exclude `TEST_EMK_%` and `EMK_DATA_GEN_PKG` from the export; schemas `EMK_DATA`, `EMK_API`, `EMK_UI` (the APEX application) and `EMK_INT` (with its first objects) as set up in phase M.4 (`partitioning: true` was set in step 1, with the first partitioned table `EMK_LOG`) | 10, 11 |

#### Step M — Migration phases

The phases M.1–M.5 are steps inside milestone M1, not milestones: phase M.3 is unrelated to milestone M3 (legal search).

| Phase | Work | Proven by |
|-------|------|-----------|
| M.1 | Safety and operations (CDB, one restart): OS-authentication check, cold backup; `ARCHIVELOG`, `ARCHIVE_LAG_TARGET`, `WALLET_ROOT`, `TABLESPACE_ENCRYPTION`; keystore, master keys, local auto-login, two keystore copies; RMAN configuration, first level 0, validation; small restore of a lab tablespace | `log_mode = ARCHIVELOG`; keystore `OPEN`; `RESTORE DATABASE VALIDATE`; lab restore; T-M1-35, T-M1-36. **Done 2026-10-12:** [drill protocol](../operations/drills/2026-10-12-m1-dev.md), scripts in `scripts/operations/` |
| M.2 | Admin scripts per environment (`EMK_ENV`): encrypted `EMK_DATA_TS`, `EMK_INT_TS`; schemas `EMK_DATA`, `EMK_API`, `EMK_UI`; `EMK_DEPLOY`; developer proxies (DEV only); audit policies; debugger ACL; `verify_admin.sql`, `uninstall_admin.sql` | `verify_admin.sql`; T-M1-34, T-M1-35. **Done 2026-10-13:** 29/29 checks, idempotent second run, T-M1-34 6/6 (`tests/admin/t_m1_34_audit.sql`); data files in a folder per environment apart from Oracle's (D-53). `verify_admin.sql` has 33 checks since the security fixes (fail-safe passwords, `rotate_password.sql`) |
| M.3 | Steps 1–6 moved to `EMK_DATA` / `EMK_API` with Data Pump through the `DBMS_DATAPUMP` API run as `SYSTEM` from SQLcl (structure only, `REMAP_SCHEMA`, `REMAP_TABLESPACE`, DDL reviewed first with `SQL_FILE`; the dump could not be encrypted in Free (`ORA-00439`), so it held structure only and was deleted after the import); reference data reloaded with the `MERGE` scripts (object grants `EMK_DATA` → `EMK_API`, schema-qualified names, document trigger with a literal error code, ADR-008); the key checks of steps 1–6 become utPLSQL suites in the schema of the tested objects, `EMK_DATA` and `EMK_API` (open point 1); utPLSQL access for both | utPLSQL suites green. **Structure moved 2026-10-15:** imports with 0 errors and 0 invalid objects, `08_check` all PASS (19 tables, 41 indexes, 16 triggers, 5 program units, all in the encrypted `EMK_DATA_TS`), grants and the `-20303` trigger in place, reference data 60/60/32/32, `verify_admin.sql` 33/33. **Done 2026-10-16:** utPLSQL suites green, 42 tests (33 in `EMK_DATA`: shipments, journals, exchange rates, claims and documents, reference data; 9 in `EMK_API`: role checks without session, log, error codes); utPLSQL access for `EMK_DATA` and `EMK_API`, refused in PROD; naming fixes `EMK_ERRORS` → `EMK_ERRORS_PKG` and `purge` → `purge_entries` (spec §1.3 *Naming*). At table level these suites already prove T-M1-05 (BR-03), the order of amounts of T-M1-07 (BR-11) and T-M1-10 (journals); the API tests of steps 7–8 prove them again through the APIs |
| M.4 | APEX parsing schema `EMK_UI`; SQLcl project configured for the separated schemas (export per schema, one release, ADR-008 §5); export; `EMK_APP` and `src/database/emk_app/` retired | Export without `EMK_APP`; application opens. **Done 2026-10-16:** DEV proxy `EMK_DEV[EMK_UI]` (`CREATE SESSION` only) and its sessions audited; project schemas `EMK_DATA`, `EMK_API`, `EMK_UI` (`EMK_INT` with its first objects, M1b); export filter: each schema exports the grants it makes, `TEST_EMK_%` excluded; export identical to M.3 apart from the schema names; APEX does not allow removing the first schema of a workspace (`ORA-20987`), so the DEV workspace was created again by `install_admin.sql` with `EMK_UI` and application 200 imported from Git as its parsing schema (a new export showed no change of the components); `EMK_APP` and the unencrypted tablespaces `EMK_DATA` and `EMK_INT_DATA` dropped after checks (no dependency, no session, no other workspace); admin scripts without the M1a layout; scripts run from the command line end with `EXIT`; reference data scripts versioned in `data/reference/`; `verify_admin.sql` 35/35, unit tests 42/42 |
| M.5 | **Moved to milestone M5 (2026-10-16), if time allows.** PDB `EMKTEST` from the seed with the admin scripts, APEX 24.2 runtime and ORDS pool (ADR-009); first deployment of the artifact by `EMK_DEPLOY`, including application 200 (open point 10); flashback of a failed deployment; restore drill with the keystore copy | T-M1-01, T-M1-31, T-M1-33 |

`EMKACC` (ACCEPTANCE) stays defined in ADR-009 and is created when customer acceptance starts (M5), like PROD. Runbooks are reduced to what was executed in M.1 and M.5.

### 4.2 M1b — Import (integration schema `EMK_INT`, ADR-007)

| # | Objects | Purpose | Depends on |
|---|---------|---------|------------|
| 0 | `docs/design/data-model-integration.md` | Physical design of the integration area, accepted before its tables are created | M1a |
| 0a | **Data contract per source**, in the integration design: columns and their order, mandatory columns, format of each value (ISO 8601 dates, ISO 3166 countries, ISO 4217 currencies, CSV RFC 4180 in UTF-8; spec §1.3), allowed values of the code lists (read from the reference tables), version (a new format is a new version; the old one keeps working). A **downloadable template** per source (header row and a sheet with the allowed values); a REST source [EXT] publishes its contract in OpenAPI. Decide whether the import creates companies (then language and roles are columns of the file). Exchange standards (EU eFTI common data set, UN/EDIFACT) researched before deciding | Nobody sends data "as they like": every source follows a versioned contract, and `EMK_API` validates every value again (owner, 2026-10-20) | 0 |
| 1 | `EMK_INBOUND_BATCHES`, `EMK_INBOUND_RECORDS` (monthly interval partitions), `EMK_INBOUND_SOURCES` | Landing: one row per record, payload `JSON` as received (never modified), status `PENDING → PROCESSING → LOADED / REJECTED`, errors, attempts; source contracts | M1a |
| 2 | Batch interfaces in `EMK_API`: collection types and `upsert_*` procedures in `EMK_PARTY_API`, `EMK_SHIPMENT_API`; `EMK_EXCHANGE_RATES` load procedure | Business validation and set-based `MERGE` (`FORALL`); one result per row; `EXECUTE` granted directly to `EMK_INT` | M1a |
| 3 | `EXECUTE` grants from `EMK_API` to `EMK_INT`; schema-qualified calls (ADR-008) | One-direction contract `EMK_INT → EMK_API` | 2 |
| 4 | `EMK_V_IN_SHIPMENTS_V1`, `EMK_V_IN_ECB_RATES_V1` | `JSON_TABLE` views with typed columns and safe conversions (ISO 8601, `DEFAULT NULL ON CONVERSION ERROR`); the ECB view unpivots one column per currency | 1 |
| 5 | `EMK_INBOUND_PKG` | Intake from a file (`APEX_DATA_PARSER`: CSV, XLSX), technical validation, batch processing through the `EMK_API` interfaces, status per record, reprocessing of a batch | 1–4 |
| 6 | Job per batch (`DBMS_SCHEDULER`) | Started after intake; calls the batch procedure; tests call the procedure directly | 5 |
| 7 | Tests | Valid, invalid and repeated files; ECB file; reprocessing; privilege boundary; partition purge | 1–6 |

### 4.3 M1c — APEX application

| # | Component | Purpose | Depends on |
|---|-----------|---------|------------|
| 1 | Application 200 (from the M1a skeleton): Universal Theme, APEX accounts authentication, navigation | Application shell | M1a |
| 2 | Authorization schemes per role (spec §7.1) on pages and components | BR-02 in the UI | 1 |
| 3 | Pages: parties and contacts, shipments, claims (list, detail, status actions, documents), reference data | F-01, F-02; all changes through the APIs | 1, 2 |
| 4 | Shipment import page: upload → `EMK_INT` intake (granted `EXECUTE`) → batch status and error report (granted view) | F-03 | M1b |
| 5 | KPI views in EUR (BR-12) and dashboard page: by carrier, route, country, type, status, ageing; recovery rate | F-04, FR-08 | M1b (rates) |
| 6 | Home page: open claims of the user | Spec §2.6 | 3 |
| 7 | Export through the SQLcl project (`READABLE_YAML` + application source) | SC-DEP-04 | 1–6 |

## 5. Tests and Traceability

| Test | What it proves | How | Rule / Criterion | Inc. |
|------|----------------|-----|------------------|------|
| T-M1-01 | The schemas install on a clean environment | `project deploy` of the release on a rebuilt environment; all objects of `EMK_DATA`, `EMK_API` and `EMK_INT` valid; application 200 opens | SC-DEP-01, 03 | M5 (moved 2026-10-16) |
| T-M1-02 | Every allowed transition works and is logged | One test per transition of spec §4 (8) | BR-01, SC-QA-01 (100% transitions) | a |
| T-M1-03 | Every other transition is rejected | Negative tests, including from final states (`--%throws`) | BR-01, SC-QA-03 | a |
| T-M1-04 | Only `CLAIMS_HANDLER` changes a status | APEX session created in the test (`APEX_SESSION.CREATE_SESSION`) for a user with and without the role; the API accepts / rejects | BR-02 | a |
| T-M1-05 | A carrier never reuses a CMR note number | Duplicate (carrier, note number) fails, also against a soft-deleted shipment; the same number for another carrier is accepted | BR-03 | a |
| T-M1-06 | Claim dates required by type | Damage / partial loss / delay without delivery date rejected; total loss rules | BR-04 | a |
| T-M1-07 | Amount rules | settled ≤ claimed, recovered ≤ settled, amounts ≥ 0 | BR-11 | a |
| T-M1-08 | Soft delete hides but keeps rows | API soft delete; views exclude the row; row still in the table | BR-13 | a |
| T-M1-09 | Audit columns record the real user | Through proxy: `created_by` = `EMK_DEV`; update sets `updated_*` | Spec §1.3 | a |
| T-M1-10 | Journals keep previous values | Update and delete write the old row to `<TABLE>_JN` | FR-09 | a |
| T-M1-11 | Reference validity is enforced | Claim in a currency outside its validity period rejected (e.g., HRK in 2024); ISO format checks | Spec §1.3 | a |
| T-M1-12 | Synthetic data is reproducible | Two runs with the same seed give the same data | Spec §8.4 | a |
| T-M1-13 | Valid records load, invalid records are rejected with a reason | File with mixed rows; technical and business errors reported per record | BR-14, SC-QA-06 | b |
| T-M1-14 | Re-import creates no duplicates | Same file twice | BR-14 | b |
| T-M1-15 | ECB rates load | Sample ECB file; rates per currency and date; latest earlier rate when a date has none | BR-12 | b |
| T-M1-16 | KPIs in EUR use the rate of the registration date | Unit test on the KPI view | BR-12 | c |
| T-M1-17 | Role access as designed | Checklist per role against spec §7.1 | BR-02, spec §7.1 | c |
| T-M1-18 | Import through the UI | Upload a CSV and an Excel file; batch status and error report shown | F-03 | c |
| T-M1-19 | Dashboards show the indicators | Screenshots with synthetic data | F-04, FR-08 | c |
| T-M1-20 | Application versioned | App 200 exported with `project export` and committed | SC-DEP-04 | c |
| T-M1-21 | All tests, one command, coverage | `tests/run_tests.sql`: all green; PL/SQL coverage ≥ 80% | SC-QA-01, 02 | a–c |
| T-M1-22 | Clean rebuild | `install_admin.sql` → `09_install_utplsql.sql` → `project deploy` → tests green | SC-DEP-02 | c |
| T-M1-23 | Admin extension is idempotent and as designed | `install_admin.sql` twice; `verify_admin.sql`: `EMK_INT` schema-only with proxy, `EMK_INT_TS` (was `EMK_INT_DATA` before phase M.2), `EMK_DEV` with `CREATE SESSION` only and `ORA_CIS_PROFILE`, `ORDS_PUBLIC_USER` on `DEFAULT` | ADR-007, SC-DEP-03 | a |
| T-M1-24 | Development works through proxy without own privileges | As `EMK_DEV[EMK_DATA]`, `EMK_DEV[EMK_API]` and `EMK_DEV[EMK_INT]`: create, compile and debug PL/SQL; as plain `EMK_DEV`: object creation fails | ADR-007 | a |
| T-M1-25 | Integration cannot change operational data directly | As `EMK_INT`: `INSERT`/`UPDATE` on `EMK_DATA` tables fails; calling the granted APIs succeeds | ADR-007 | b |
| T-M1-26 | A batch is processed in the background and can be reprocessed | Intake creates a job; statuses move to `LOADED` / `REJECTED`; reprocessing a corrected batch creates no duplicates | BR-14, ADR-007 | b |
| T-M1-27 | The raw payload is kept unchanged | Payload after processing equals the payload received | ADR-007 | b |
| T-M1-28 | Old inbound and log data is purged by partition | Data older than the retention is removed with `DROP PARTITION`; newer data remains | Spec §1.3 (Partitioning) | b |
| T-M1-29 | Shipment parties have the matching role | Shipment with a carrier without the `CARRIER` role rejected; a company with several roles accepted; removing a role used by a shipment rejected | BR-16 | a |
| T-M1-30 | A shipment outside the CMR is rejected | Iceland → Liechtenstein rejected (no CMR party); Oman → Germany before 2020-12-22 accepted only because Germany is a party; a pickup date before both parties' dates rejected | BR-17 | a |
| T-M1-31 | A failed deployment is undone completely | Guaranteed PDB restore point, deployment with a deliberate error, `FLASHBACK PLUGGABLE DATABASE`; objects and data identical to before (count and checksum per table) | ADR-010 §2 | M5 (moved 2026-10-16) |
| T-M1-32 | The previous application version can be redeployed | Redeploy of the previous APEX application artifact over a newer one; application opens, data unchanged | ADR-010 §2 | c |
| T-M1-33 | A backup can be restored within the targets | Restore drill in DEV following the [recovery runbook](../operations/recovery-runbook.md) with marker rows; protocol with measured RPO ≤ 1 h and RTO ≤ 4 h | ADR-010 §1 | M5 (moved 2026-10-16) |
| T-M1-34 | Privileged activity is audited and attributed | DDL, object grant and proxy logon as `<developer>[EMK_DATA]` produce records in `UNIFIED_AUDIT_TRAIL` with `DBPROXY_USERNAME` | ADR-010 §3 | a |
| T-M1-35 | Project tablespaces are encrypted | `DBA_TABLESPACES.ENCRYPTED = 'YES'` for every `EMK_%` tablespace (AES256); a known test string is found in the data file of an unencrypted test tablespace and not in the encrypted one; timing of the same full scan with cold cache in both, recorded | ADR-011 | a |
| T-M1-36 | Losing the auto-login file loses no data | `cwallet.sso` removed → `ORA-28365` → auto-login recreated from the password keystore → data readable; restore drill T-M1-33 uses the keystore backup, not the live keystore | ADR-011 | a |
| T-M1-37 | A retired code is not given to new records, and old records keep it | Unknown or retired language or role rejected by the API; a role retired after it was given stays on the company; the lists of values offer only valid values; an unknown code rejected by the foreign key | D-68, spec §1.3 (Code lists) | a |
| T-M1-38 | Only allowed files are stored as claim documents | Extension outside the allowlist rejected; a file whose content does not start with the signature of its extension (e.g., a text file named `.pdf`) rejected; the stored type is the server's, not the browser's; an empty or oversized file rejected | BR-18, OWASP ASVS 5.0 V5.2.2 | a |
| T-M1-39 | A role cannot be removed, nor a company deleted, while a shipment that needs it is being saved | Through the application: `tests/emk_ui/hold_role_lock.sql` holds the role lock as a shipment being saved does; in the browser, removing the role and deleting the company answer "try again"; after the release they work, or are rejected if a shipment uses the role | D-73, BR-16 | a |
| T-M1-40 | The consignment note particulars are kept | Shipment without the date of the consignment note rejected; declared value and special interest stored with their currency; a currency without an ECB rate rejected; an amount without its currency rejected | D-78, D-79, FR-02 | a (done in step 7.6) |
| T-M1-41 | The claimant is a party of the shipment | A claim whose claimant is not the shipper or the consignee of its shipment rejected | BR-19, D-76 | a (step 8) |
| T-M1-42 | Recovery payments add up and are never changed | Payments in another currency converted at the ECB rate of the payment day; recovered sum above the settled amount rejected; a payment cannot be updated or deleted; a correction needs a negative amount, the corrected payment and a reason; admitted amount ≤ claimed | BR-11, D-77 | a (step 8) |
| T-M1-43 | Alleged wilful misconduct is recorded by a person | The flag is set only by a user, kept in the claim journal with who and when; the deadline view of M2 shows the 3-year date as information only | D-75, spec §5.3 | a (step 8; dates in M2) |
| T-M1-44 | Master data is maintained only by the administrator | A user without the administrator role is refused by the API and the refusal logged; a code named in `EMK_CODES_PKG` cannot be retired; a code is never changed or deleted, and the database refuses it even to `EMK_API`; a retired value stays where it is used and is no longer offered (a role on its company; a document type on its documents in step 8); each change is in the journal with who and when | D-82, spec §7.1 | a (step 7.7; documents in step 8) |

## 6. Definition of Done

- Each increment: its tests pass, pull request reviewed and merged.
- M1: all tests T-M1-01 to T-M1-44 pass with evidence in the pull requests, except T-M1-01, T-M1-31 and T-M1-33, moved to M5 with phase M.5 (2026-10-16); spec §8.1 criteria for M1 (SC-DEP-01 to 04, SC-QA-01 to 03, 06) pass.
- `docs/setup.md`, the glossary and the Spanish copies describe the new steps.

## 7. Open Points

| # | Point | Proposal |
|---|-------|----------|
| 1 | Location of tests and generator | **Decided (2026-10-16, replaces the `EMK_API`-only decision of 2026-10-13):** test packages `TEST_EMK_<NAME>` live in the **schema of the tested objects**: tests of tables, constraints, triggers and journals in `EMK_DATA`, tests of packages in `EMK_API`. utPLSQL's documented practice is test code in the same schema as the tested code ("removes the need to manage privileges for the tests"); the tests of the reference and exchange-rate constraints insert and update rows, which `EMK_API` must not do (it only reads them, ADR-008), and a grant for the tests would reach PROD with the release. The generator `EMK_DATA_GEN_PKG` works through the APIs and lives in `EMK_API`. Tests and code in separate packages; sources in `tests/`; installed with `tests/install_tests.sql`, which **refuses PROD**; run with `tests/run_tests.sql`; excluded from the export and the release artifact by `project.filters` (`TEST_EMK%`). Rejected: all tests in `EMK_API` (test-only grants in PROD); separate `EMK_TEST` schema (grant script per table, coverage needs a broad system privilege) — kept as an improvement. Sources: [utPLSQL best practices](https://www.utplsql.org/utPLSQL/latest/userguide/best-practices.html), [running tests](https://www.utplsql.org/utPLSQL/latest/userguide/running-unit-tests.html), [coverage](https://www.utplsql.org/utPLSQL/latest/userguide/coverage.html) |
| 2 | Claim number format | **Decided:** `CLM-YYYY-NNNNNN` (hyphens, no spaces; year of registration; six zero-padded digits so that text order equals numeric order) from the global sequence `EMK_CLAIM_NO_SEQ` (no yearly reset, gaps allowed); `UNIQUE` and `CHECK (REGEXP_LIKE(claim_no, '^CLM-[0-9]{4}-[0-9]{6}$'))`. Business reference shown to users; `claim_id` stays internal |
| 3 | Role check in PL/SQL (BR-02) outside APEX (tests, SQLcl) | **Decided:** defence in depth: APEX hides actions, `EMK_CLAIM_API` enforces the rule. `EMK_SECURITY_PKG.has_role` wraps `APEX_ACL.HAS_USER_ROLE`; tests and the generator create an APEX session with `APEX_SESSION.CREATE_SESSION` (both verified in the APEX 24.2 source). The application 200 skeleton with its roles moves to M1a (step 0). **Verified in step 1 (2026-10-08):** `APEX_SESSION.CREATE_SESSION` works for a user that is not an APEX account, so tests need no real users; `APEX_ACL.ADD_USER_ROLE` does not commit, so a `ROLLBACK` (utPLSQL default after each test) removes the assignment; without an APEX session `has_role` returns `FALSE` |
| 4 | Reference data scope | **Decided:** 60 countries = the 58 CMR parties ([UN Treaty Collection](https://treaties.un.org/Pages/ViewDetails.aspx?src=TREATY&mtdsg_no=XI-B-11&chapter=11&clang=_en)) plus Iceland and Liechtenstein (EEA, not CMR parties); `cmr_party_since` (date from which the CMR applies to the country; `NULL` = not a party) from that list (CMR Art. 1: applies if loading **or** delivery is in a party). Currencies: EUR and those with an ECB reference rate (`ecb_rate_yn`), so that BR-12 always has a rate; historic HRK (until 2022-12-31, [ECB](https://www.ecb.europa.eu/press/pr/date/2022/html/ecb.pr220712~b97dd38de3.en.html)) and BGN (until 2025-12-31, [ECB](https://www.ecb.europa.eu/euro/changeover/bulgaria/html/index.en.html)) |
| 5 | ECB exchange rates | **Decided:** ECB historical reference-rate CSV ([ECB](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html): units per 1 EUR, dot decimal, TARGET working days ~16:00 CET), downloaded manually in the MVP (no outbound network access before M2); one column per currency → unpivoted in the source view; EUR = 1. **Rule for BR-12:** without a rate on the registration date, the latest earlier rate is used (weekends, TARGET holidays). File header to verify at the start of M1b |
| 6 | Reference data deployment | **Superseded (2026-10-20, D-72):** insert-only `MERGE` scripts, added to a release once; a change to existing rows is a separate change script with an authorized request (reference data design, open point 10). Earlier decision: one `MERGE` script per reference table, added with `project stage add-custom` and `runOnChange:true`: the same file is edited and re-applied without duplicates. The scripts are kept in `data/reference/` and loaded in DEV with `load_reference_data.sql` (phase M.4); the first `project stage` is part of the first release (M5). Without `runOnChange`, a changed script fails the Liquibase checksum validation ([SQLcl PROJECT](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.1/sqcug/project.html)) |
| 7 | Documents (BLOB) | **Decided:** maximum 10 MB per file (Free edition: 12 GB of user data; documents are the main storage driver, spec §12.2); PDF, JPEG and PNG only (no Office files: macros); checked in the APEX upload item **and** in the API (`DBMS_LOB.GETLENGTH`, MIME type allow-list); MIME type and file name stored. APEX item attributes to verify in M1c |
| 8 | Data formats | **Decided:** international standards for every data format (spec §1.3 *Data formats*): ISO 3166-1, ISO 4217, ISO 8601, ISO 639, ITU-T E.164, RFC 5322, VIES, SI (kg), RFC 4180, UTF-8 / AL32UTF8. Database character set verified: `AL32UTF8` (2026-10-06) |
| 9 | Integration, staging, partitioning, accounts | **Decided ([ADR-007](../adr/ADR-007-integration-schema-and-account-hardening.md)):** integration schema `EMK_INT` calling `EMK_APP` APIs only (`EMK_API` since ADR-008, with schema-qualified names instead of private synonyms); generic landing with versioned source views and a job per batch; monthly interval partitioning for append-only tables; `ORA_CIS_PROFILE` for people, `DEFAULT` for services; `EMK_DEV` with `CREATE SESSION` only. To verify while building: PL/SQL debugging in a proxy session; export of interval partitions by the SQLcl project |
| 10 | Installation of application 200 by `EMK_DEPLOY` (phase M.5) | **Deferred with M.5 to M5 (2026-10-16). To verify before M.5:** the APEX 24.2 Administration Guide names `APEX_240200`, `SYS`, `SYSTEM` or a schema with `APEX_ADMINISTRATOR_ROLE` as the accounts that install an exported application in a runtime environment ([source](https://docs.oracle.com/en/database/oracle/apex/24.2/aeadm/installing-exported-applications-in-a-runtime-environment.html)); `EMK_DEPLOY` has none of them. Options to be researched and decided against ADR-008 §5 (nobody deploys as owner in shared environments). Found in phase M.4: the export file itself allows the parsing schema ("connected to the database as the owner (parsing schema) of the application or as a database user with the APEX_ADMINISTRATOR_ROLE role"); the import as `EMK_DEV[EMK_UI]` worked in DEV |
| 11 | Logical copy (Data Pump) in 26ai Free | **Deferred to M5 (2026-10-16). To decide before the first release in ACCEPTANCE:** [ADR-010](../adr/ADR-010-operations-and-release-strategy.md) plans a Data Pump export before each release and [ADR-011](../adr/ADR-011-tablespace-encryption.md) encrypts it with its own password, but export encryption is **not enabled** in 26ai Free in any mode (`ORA-00439`, `PASSWORD` and `TRANSPARENT` tested 2026-10-15). Options to be researched (for example, no logical copy and reliance on encrypted RMAN backups plus two keystore copies, or an export encrypted outside Oracle) and decided with their sources; growth path: Enterprise Edition + Advanced Security, or Oracle Cloud |

## 8. Revision History

| Version | Date | Change |
|---------|------|--------|
| v0.1 | 2026-10-06 | First draft: three increments, work order, tests T-M1-01 to 22, open points. |
| v0.2 | 2026-10-06 | Open points 1–3 decided: tests in `tests/` excluded from the release, claim number format, role check with `EMK_SECURITY_PKG`; application skeleton moved to M1a. |
| v1.0 | 2026-10-06 | Open points 4–8 decided (reference data scope, ECB rates and BR-12 rule, reference data deployment, documents, data formats). Accepted by the owner. |
| v1.1 | 2026-10-07 | ADR-007 and spec v1.3: physical data model design step (D) and admin layer extension (A) in M1a; M1b redesigned around `EMK_INT` (generic landing, source views, job per batch, batch interfaces); partitioned logs and journals; tests T-M1-23 to 28. Accepted by the owner. |
| v1.2 | 2026-10-07 | Physical design split into area documents in `docs/design/` (integration designed at the start of M1b); translation tables for country and currency names; `cmr_party_since` instead of `cmr_party_yn`; soft-delete flag renamed `deleted_yn`. Accepted by the owner. |
| v1.3 | 2026-10-07 | Reference and operational data areas accepted (`docs/design/`); T-M1-05 updated to BR-03 unique per carrier (spec v1.5). Accepted by the owner. |
| v1.4 | 2026-10-07 | Party roles (`EMK_PARTY_ROLES`, BR-16) in step 3; test T-M1-29; places of taking over and delivery (spec v1.6). Accepted by the owner. |
| v1.5 | 2026-10-08 | Step 0: check that the application ID is free; open point 3 verified (APEX session and role assignment behaviour); export option `partitioning: true` moved from step 12 to step 1. Accepted by the owner. |
| v1.6 | 2026-10-09 | Step 7: restore, BR-16 and BR-17 in the APIs; test T-M1-30 (CMR applicability). Accepted by the owner. |
| v1.7 | 2026-10-11 | ADR-010: tests T-M1-31 to T-M1-34 (flashback of a failed deployment, redeploy of the previous application, restore drill with measured RPO and RTO, audit of privileged activity). Accepted by the owner. |
| v1.8 | 2026-10-12 | ADR-011: tests T-M1-35 (encrypted tablespaces) and T-M1-36 (keystore loss without data loss). Accepted by the owner. |
| v1.9 | 2026-10-12 | Step M: migration to the separated schemas in five phases (ADR-008 to ADR-011); checks of steps 1–6 committed as utPLSQL suites; `EMKACC` created at customer acceptance (M5). Accepted by the owner. |
| v1.10 | 2026-10-12 | Phase M.1 done: `ARCHIVELOG`, keystore, encrypted level 0, lab restore; T-M1-35 and T-M1-36 passed (drill protocol). Accepted by the owner. |
| v1.11 | 2026-10-13 | Phase M.2 done: admin scripts per environment (asked at run time), encrypted tablespaces in a separate data folder, separated schemas, `EMK_DEPLOY`, audit policies; T-M1-34 and T-M1-35 passed. Accepted by the owner. |
| v1.12 | 2026-10-13 | Open point 1: tests in `EMK_API` (utPLSQL best practice), installer refuses PROD; phase M.3 detailed. Accepted by the owner. |
| v1.13 | 2026-10-13 | Aligned with ADR-008 (sweep of outdated references): conventions, work order, step 12, M1b steps 2, 3, 5, tests T-M1-01, 23, 24, 25 and open point 9 use the separated schemas; phase M.3 by Data Pump; M.5 with APEX runtime, ORDS pool and application 200; phase vs milestone note; open point 10 (application install by `EMK_DEPLOY`). |
| v1.14 | 2026-10-15 | Phase M.3, structure moved with Data Pump (API from SQLcl as `SYSTEM`, table mode for the tables, the document trigger created by script, strict checks: 0 errors and 0 invalid objects); dump not encrypted (not available in Free) and deleted; open point 11 (logical copy in Free). |
| v1.15 | 2026-10-16 | Focus on the MVP components of the intent: tests in the schema of the tested objects (open point 1, replaces the `EMK_API`-only decision); M.3 ports the key checks only; phase M.5, tests T-M1-01/31/33 and open points 10–11 moved to M5; ACCEPTANCE and PROD, a full port of the checks and a separate test schema documented as improvements; MVP built in DEV only. Accepted by the owner. |
| v1.16 | 2026-10-16 | Phase M.3 done: 42 utPLSQL tests green in `EMK_DATA` and `EMK_API`; naming fixes `EMK_ERRORS_PKG`, `purge_entries`; step 10 started; automatic coding-guideline check listed as an improvement. |
| v1.17 | 2026-10-16 | Phase M.4 done: `EMK_APP` and the M1a tablespaces retired; DEV workspace created again with `EMK_UI` (first schema); SQLcl project per schema with the APEX application in `EMK_UI`; reference data scripts in `data/reference/` (open point 6); first `project stage` moved to M5 with M.5; finding for open point 10. |
| v1.18 | 2026-10-18/21 | Step 7 split into 7.1–7.10; 7.6 code lists (D-68): business value lists as reference tables with validity, insert-only data scripts, journals without partitions, no indexes on their foreign keys (D-72), common packages (D-69), required language and roles (D-71), role locks (D-73); step 11 measures the restore page (D-74); M1b data contract per source (0a); tests T-M1-37 (code lists), T-M1-38 (file checks of claim documents, BR-18, built in step 8), T-M1-39 (concurrency through the application) and T-M1-40 to T-M1-43 (consignment note particulars, claimant, recovery payments, wilful misconduct). Accepted by the owner. |
| v1.19 | 2026-10-21 | Step 7.7 master data API (D-82): administrator role checked in the API, what the administrator adds and changes, protected codes; test T-M1-44; step 8: role `INSURER` in `EMK_CODES_PKG`. Accepted by the owner. |
| v1.20 | 2026-10-21 | Step 7.7 as built: the first release also adds the column privileges of `EMK_API` with `add-custom`; T-M1-44 checks that the database refuses codes and deletes, and the document part moves to step 8 (documents are created by `EMK_CLAIM_API`). Accepted by the owner. |
