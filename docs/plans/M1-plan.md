# Plan — M1 Claims Core

| | |
|---|---|
| **SDLC stage** | 3 — Build ([docs/sdlc.md](../sdlc.md)) |
| **Status** | Accepted v1.13 (2026-10-13) |
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

## 3. Conventions (spec §1.3, §7)

- Keys: `<entity>_id NUMBER GENERATED ALWAYS AS IDENTITY`; reference tables keyed by ISO code with `valid_from` / `valid_to`.
- Every table: `created_*`; updated tables: `updated_*` (technical `BEFORE UPDATE` trigger); operational tables: `deleted_yn` + journal `<TABLE>_JN` (`AFTER UPDATE OR DELETE` trigger).
- Monthly interval partitioning only for append-only tables: `EMK_INBOUND_RECORDS`, `EMK_LOG`, `<TABLE>_JN`.
- Flags `<name>_yn CHAR(1)`; named constraints; an index on every foreign key; `COMMENT ON` for tables and non-obvious columns.
- Schemas (ADR-008): tables in `EMK_DATA`, code and views in `EMK_API`, `EMK_UI` owns nothing, inbound data in `EMK_INT`; another schema's objects with **schema-qualified names**, no synonyms; object grants from the owner (`EMK_DATA` → `EMK_API`, `EMK_API` → `EMK_UI` / `EMK_INT`), no schema-wide grants. Every change that adds a table, view or API includes its grants.
- PL/SQL: parameters `in_` / `out_` / `io_`; business errors `-20001…-20999` from `EMK_ERRORS`; no `COMMIT` in APIs (except the autonomous log and batch jobs); no nested subprograms in application code; privileges used in PL/SQL granted directly (roles are disabled in definer's-rights code).

## 4. Work Order

Application objects are created in `EMK_DATA`, `EMK_API` and `EMK_INT` (DEV: one proxy per schema, `EMK_DEV[EMK_DATA]`, `EMK_DEV[EMK_API]`, `EMK_DEV[EMK_INT]`), exported per schema with `project export` to `src/database/`, and staged with `project stage` to `dist/releases/next/` as one release for all schemas, deployed by `EMK_DEPLOY` (ADR-008 §5). Partition clauses are exported (`partitioning: true`). Steps 0–6 were built in the single schema `EMK_APP` and are moved by step M. Tests and the data generator live in `tests/` and are not part of the release artifact.

### 4.1 M1a — Data core

| # | Objects | Purpose | Depends on |
|---|---------|---------|------------|
| D | `docs/design/`: README (standard audit block, common rules), `data-model-reference.md`, `data-model-operational.md`, `data-model-audit.md` | **Physical data model** per area: every table with columns, types, sizes, constraints, indexes, partitioning, journals and expected volumes; each area reviewed and **accepted before its tables are created** | — |
| A | Admin layer extension (`scripts/admin`): tablespace `EMK_INT_DATA` (replaced by the encrypted `EMK_INT_TS` in phase M.2), schema-only `EMK_INT` with proxy from `EMK_DEV`, `ORA_CIS_PROFILE` for `EMK_DEV`, `EMK_DEV` reduced to `CREATE SESSION`, privileges needed in the proxy sessions granted to the target schemas; `verify_admin.sql` and `uninstall_admin.sql` updated | ADR-007; the proxy session to `EMK_INT` exists before M1b | — |
| 0 | APEX application 200 skeleton (`EMK_CLAIMS`): first check that ID 200 is free in the instance (`apex_applications`; if taken, choose another ID and record it); empty application with the four roles of spec §7.1 (`CLAIMS_HANDLER`, `COMPLIANCE_OFFICER`, `ANALYST`, `ADMINISTRATOR`), exported with `project export` | The roles exist before the APIs and tests that check them (BR-02) and before the generator, which changes statuses through the API | A |
| 1 | `EMK_ERRORS`, `EMK_LOG` (partitioned) + `EMK_LOG_PKG`, `EMK_SECURITY_PKG` | Error codes; application log (autonomous transaction); `has_role` over `APEX_ACL.HAS_USER_ROLE` (single place for role checks) | D, 0 |
| 2 | `EMK_COUNTRIES`, `EMK_COUNTRY_NAMES`, `EMK_CURRENCIES`, `EMK_CURRENCY_NAMES` + reference data (`MERGE` scripts, `project stage add-custom`) | ISO reference data with validity periods; German names in translation tables (F-15, M4 letters) | D |
| 3 | `EMK_PARTIES`, `EMK_PARTY_ROLES`, `EMK_CONTACTS` (+ `_JN` partitioned, triggers) | Companies, their roles (BR-16) and contact persons (PII isolated) | 2 |
| 4 | `EMK_SHIPMENTS` (+ `_JN`, triggers) | Shipments; `cmr_note_no` unique including soft-deleted rows (BR-03) | 2, 3 |
| 5 | `EMK_CLAIMS`, `EMK_CLAIM_DOCUMENTS`, `EMK_CLAIM_STATUS_HISTORY` (+ `_JN`, triggers) | Claims, documents (BLOB), status history; amount check constraints (BR-11) | 4 |
| 6 | `EMK_EXCHANGE_RATES` | Daily ECB rates (filled in M1b) | 2 |
| M | **Migration to the separated schemas** ([ADR-008](../adr/ADR-008-schema-separation.md) to [ADR-011](../adr/ADR-011-tablespace-encryption.md)), branch `feature/m1a-schema-separation`, phases below | Steps 7–12 are built on the final architecture | 0–6 |
| 7 | `EMK_PARTY_API`, `EMK_SHIPMENT_API` | Create, update, soft delete (BR-13), restore (D-39); party roles (BR-16); CMR applicability (BR-17) | 3, 4 |
| 8 | `EMK_CLAIM_API` + sequence `EMK_CLAIM_NO_SEQ` | Create claim (`claim_no` = `CLM-YYYY-NNNNNN`, BR-04, BR-11), state machine (BR-01, BR-02 through `EMK_SECURITY_PKG`), status history, soft delete | 1, 5 |
| 9 | Views `EMK_V_PARTIES`, `EMK_V_SHIPMENTS`, `EMK_V_CLAIMS` | Active rows only (`deleted_yn = 'N'`) | 3–5 |
| 10 | `tests/`: `TEST_EMK_*` suites, `install_tests.sql`, `run_tests.sql` | Unit tests; one command (SC-QA-02); coverage report | 1–9 |
| 11 | `tests/`: `EMK_DATA_GEN_PKG` | Synthetic data with a fixed seed (≈ 500 shipments, 100 claims by default) | 3–8 |
| 12 | `project.filters`, `project.config.json` | Exclude `TEST_EMK_%` and `EMK_DATA_GEN_PKG` from the export; schemas `EMK_DATA`, `EMK_API`, `EMK_INT` and the APEX application as set up in phase M.4 (`partitioning: true` was set in step 1, with the first partitioned table `EMK_LOG`) | 10, 11 |

#### Step M — Migration phases

The phases M.1–M.5 are steps inside milestone M1, not milestones: phase M.3 is unrelated to milestone M3 (legal search).

| Phase | Work | Proven by |
|-------|------|-----------|
| M.1 | Safety and operations (CDB, one restart): OS-authentication check, cold backup; `ARCHIVELOG`, `ARCHIVE_LAG_TARGET`, `WALLET_ROOT`, `TABLESPACE_ENCRYPTION`; keystore, master keys, local auto-login, two keystore copies; RMAN configuration, first level 0, validation; small restore of a lab tablespace | `log_mode = ARCHIVELOG`; keystore `OPEN`; `RESTORE DATABASE VALIDATE`; lab restore; T-M1-35, T-M1-36. **Done 2026-10-12:** [drill protocol](../operations/drills/2026-10-12-m1-dev.md), scripts in `scripts/operations/` |
| M.2 | Admin scripts per environment (`EMK_ENV`): encrypted `EMK_DATA_TS`, `EMK_INT_TS`; schemas `EMK_DATA`, `EMK_API`, `EMK_UI`; `EMK_DEPLOY`; developer proxies (DEV only); audit policies; debugger ACL; `verify_admin.sql`, `uninstall_admin.sql` | `verify_admin.sql`; T-M1-34, T-M1-35. **Done 2026-10-13:** 29/29 checks, idempotent second run, T-M1-34 6/6 (`tests/admin/t_m1_34_audit.sql`); data files in a folder per environment apart from Oracle's (D-53). `verify_admin.sql` has 33 checks since the security fixes (fail-safe passwords, `rotate_password.sql`) |
| M.3 | Steps 1–6 moved to `EMK_DATA` / `EMK_API` with Data Pump (structure only, `REMAP_SCHEMA`, `REMAP_TABLESPACE`, run as `SYSTEM`, DDL reviewed first with `SQLFILE`); reference data reloaded with the `MERGE` scripts (object grants `EMK_DATA` → `EMK_API`, schema-qualified names, document trigger with a literal error code, ADR-008); the checks of steps 1–6 become utPLSQL suites in `EMK_API` (open point 1); utPLSQL access for `EMK_API` | utPLSQL suites green |
| M.4 | APEX parsing schema `EMK_UI`; SQLcl project configured for the separated schemas (export per schema, one release, ADR-008 §5); export; `EMK_APP` and `src/database/emk_app/` retired | Export without `EMK_APP`; application opens |
| M.5 | PDB `EMKTEST` from the seed with the admin scripts, APEX 24.2 runtime and ORDS pool (ADR-009); first deployment of the artifact by `EMK_DEPLOY`, including application 200 (open point 10); flashback of a failed deployment; restore drill with the keystore copy | T-M1-01, T-M1-31, T-M1-33 |

`EMKACC` (ACCEPTANCE) stays defined in ADR-009 and is created when customer acceptance starts (M5), like PROD. Runbooks are reduced to what was executed in M.1 and M.5.

### 4.2 M1b — Import (integration schema `EMK_INT`, ADR-007)

| # | Objects | Purpose | Depends on |
|---|---------|---------|------------|
| 0 | `docs/design/data-model-integration.md` | Physical design of the integration area, accepted before its tables are created | M1a |
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
| T-M1-01 | The schemas install on a clean environment | `project deploy` of the release on a rebuilt environment; all objects of `EMK_DATA`, `EMK_API` and `EMK_INT` valid; application 200 opens | SC-DEP-01, 03 | a |
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
| T-M1-31 | A failed deployment is undone completely | Guaranteed PDB restore point, deployment with a deliberate error, `FLASHBACK PLUGGABLE DATABASE`; objects and data identical to before (count and checksum per table) | ADR-010 §2 | a |
| T-M1-32 | The previous application version can be redeployed | Redeploy of the previous APEX application artifact over a newer one; application opens, data unchanged | ADR-010 §2 | c |
| T-M1-33 | A backup can be restored within the targets | Restore drill in DEV following the [recovery runbook](../operations/recovery-runbook.md) with marker rows; protocol with measured RPO ≤ 1 h and RTO ≤ 4 h | ADR-010 §1 | a |
| T-M1-34 | Privileged activity is audited and attributed | DDL, object grant and proxy logon as `<developer>[EMK_DATA]` produce records in `UNIFIED_AUDIT_TRAIL` with `DBPROXY_USERNAME` | ADR-010 §3 | a |
| T-M1-35 | Project tablespaces are encrypted | `DBA_TABLESPACES.ENCRYPTED = 'YES'` for every `EMK_%` tablespace (AES256); a known test string is found in the data file of an unencrypted test tablespace and not in the encrypted one; timing of the same full scan with cold cache in both, recorded | ADR-011 | a |
| T-M1-36 | Losing the auto-login file loses no data | `cwallet.sso` removed → `ORA-28365` → auto-login recreated from the password keystore → data readable; restore drill T-M1-33 uses the keystore backup, not the live keystore | ADR-011 | a |

## 6. Definition of Done

- Each increment: its tests pass, pull request reviewed and merged.
- M1: all tests T-M1-01 to T-M1-36 pass with evidence in the pull requests; spec §8.1 criteria for M1 (SC-DEP-01 to 04, SC-QA-01 to 03, 06) pass.
- `docs/setup.md`, the glossary and the Spanish copies describe the new steps.

## 7. Open Points

| # | Point | Proposal |
|---|-------|----------|
| 1 | Location of tests and generator | **Decided (2026-10-13, replaces the `EMK_APP` decision of v0.2):** test packages `TEST_EMK_<PACKAGE>` and `EMK_DATA_GEN_PKG` live in **`EMK_API`**: utPLSQL's documented practice is test code in the same schema as the tested code (no test-only privileges), and the tests of `EMK_DATA` constraints and triggers use the DML privileges the APIs need anyway (plus `SELECT` on the journals). Tests and code in separate packages; sources in `tests/`; installed with `tests/install_tests.sql`, which **refuses the PROD environment** (tests change data); run with `tests/run_tests.sql`; excluded from the export and the release artifact by `project.filters` (`TEST_EMK%`). Sources: [utPLSQL best practices](https://www.utplsql.org/utPLSQL/v3.1.6/userguide/best-practices.html), [coverage across schemas](http://www.utplsql.org/utPLSQL/develop/userguide/coverage.html) |
| 2 | Claim number format | **Decided:** `CLM-YYYY-NNNNNN` (hyphens, no spaces; year of registration; six zero-padded digits so that text order equals numeric order) from the global sequence `EMK_CLAIM_NO_SEQ` (no yearly reset, gaps allowed); `UNIQUE` and `CHECK (REGEXP_LIKE(claim_no, '^CLM-[0-9]{4}-[0-9]{6}$'))`. Business reference shown to users; `claim_id` stays internal |
| 3 | Role check in PL/SQL (BR-02) outside APEX (tests, SQLcl) | **Decided:** defence in depth: APEX hides actions, `EMK_CLAIM_API` enforces the rule. `EMK_SECURITY_PKG.has_role` wraps `APEX_ACL.HAS_USER_ROLE`; tests and the generator create an APEX session with `APEX_SESSION.CREATE_SESSION` (both verified in the APEX 24.2 source). The application 200 skeleton with its roles moves to M1a (step 0). **Verified in step 1 (2026-10-08):** `APEX_SESSION.CREATE_SESSION` works for a user that is not an APEX account, so tests need no real users; `APEX_ACL.ADD_USER_ROLE` does not commit, so a `ROLLBACK` (utPLSQL default after each test) removes the assignment; without an APEX session `has_role` returns `FALSE` |
| 4 | Reference data scope | **Decided:** 60 countries = the 58 CMR parties ([UN Treaty Collection](https://treaties.un.org/Pages/ViewDetails.aspx?src=TREATY&mtdsg_no=XI-B-11&chapter=11&clang=_en)) plus Iceland and Liechtenstein (EEA, not CMR parties); `cmr_party_since` (date from which the CMR applies to the country; `NULL` = not a party) from that list (CMR Art. 1: applies if loading **or** delivery is in a party). Currencies: EUR and those with an ECB reference rate (`ecb_rate_yn`), so that BR-12 always has a rate; historic HRK (until 2022-12-31, [ECB](https://www.ecb.europa.eu/press/pr/date/2022/html/ecb.pr220712~b97dd38de3.en.html)) and BGN (until 2025-12-31, [ECB](https://www.ecb.europa.eu/euro/changeover/bulgaria/html/index.en.html)) |
| 5 | ECB exchange rates | **Decided:** ECB historical reference-rate CSV ([ECB](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html): units per 1 EUR, dot decimal, TARGET working days ~16:00 CET), downloaded manually in the MVP (no outbound network access before M2); one column per currency → unpivoted in the source view; EUR = 1. **Rule for BR-12:** without a rate on the registration date, the latest earlier rate is used (weekends, TARGET holidays). File header to verify at the start of M1b |
| 6 | Reference data deployment | **Decided:** one `MERGE` script per reference table, added with `project stage add-custom` and `runOnChange:true`: the same file is edited and re-applied without duplicates. Without `runOnChange`, a changed script fails the Liquibase checksum validation ([SQLcl PROJECT](https://docs.oracle.com/en/database/oracle/sql-developer-command-line/25.1/sqcug/project.html)) |
| 7 | Documents (BLOB) | **Decided:** maximum 10 MB per file (Free edition: 12 GB of user data; documents are the main storage driver, spec §12.2); PDF, JPEG and PNG only (no Office files: macros); checked in the APEX upload item **and** in the API (`DBMS_LOB.GETLENGTH`, MIME type allow-list); MIME type and file name stored. APEX item attributes to verify in M1c |
| 8 | Data formats | **Decided:** international standards for every data format (spec §1.3 *Data formats*): ISO 3166-1, ISO 4217, ISO 8601, ISO 639, ITU-T E.164, RFC 5322, VIES, SI (kg), RFC 4180, UTF-8 / AL32UTF8. Database character set verified: `AL32UTF8` (2026-10-06) |
| 9 | Integration, staging, partitioning, accounts | **Decided ([ADR-007](../adr/ADR-007-integration-schema-and-account-hardening.md)):** integration schema `EMK_INT` calling `EMK_APP` APIs only (`EMK_API` since ADR-008, with schema-qualified names instead of private synonyms); generic landing with versioned source views and a job per batch; monthly interval partitioning for append-only tables; `ORA_CIS_PROFILE` for people, `DEFAULT` for services; `EMK_DEV` with `CREATE SESSION` only. To verify while building: PL/SQL debugging in a proxy session; export of interval partitions by the SQLcl project |
| 10 | Installation of application 200 by `EMK_DEPLOY` (phase M.5) | **To verify before M.5:** the APEX 24.2 Administration Guide names `APEX_240200`, `SYS`, `SYSTEM` or a schema with `APEX_ADMINISTRATOR_ROLE` as the accounts that install an exported application in a runtime environment ([source](https://docs.oracle.com/en/database/oracle/apex/24.2/aeadm/installing-exported-applications-in-a-runtime-environment.html)); `EMK_DEPLOY` has none of them. Options to be researched and decided against ADR-008 §5 (nobody deploys as owner in shared environments) |

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
