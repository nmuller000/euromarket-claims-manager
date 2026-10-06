# Plan — M0 Foundations

| | |
|---|---|
| **SDLC stage** | 3 — Build ([docs/sdlc.md](../sdlc.md)) |
| **Status** | Accepted v1.1 (2026-10-06) |
| **Owner** | Natalia Müller ([@nmuller000](https://github.com/nmuller000)) |
| **Date** | 2026-10-04 |
| **Input** | [spec.md](../spec.md) v1.0 §7.5, §8, §9 · [ADR-005](../adr/ADR-005-deployment-and-database-setup.md) |
| **Branch** | `feature/m0-foundations` |

## 1. Goal

Create the project's database foundation from scratch with idempotent scripts, install the test framework and initialise the SQLcl project, so that M1 can start building application objects.

Already done in Stages 1–2: intent, spec, glossary, setup guide, ADR-001/002/004/005, vector memory and account hardening scripts.

## 2. Scope

| In M0 | Not in M0 |
|-------|-----------|
| Tablespace, roles, schema `EMK_APP`, developer `EMK_DEV`, workspace `EMK_CLAIMS` | Application tables and packages (M1) |
| Orchestrators `install_admin.sql` / `uninstall_admin.sql` | Network ACL `08_network_acl.sql` (M2, with SMTP) |
| utPLSQL installation | APEX application 200 (M1) |
| SQLcl project initialisation (`project init`) | Synthetic data generator (moved to M1: it needs the M1 tables) |

## 3. Files and Order

| # | File | Purpose | Depends on |
|---|------|---------|------------|
| 1 | `scripts/admin/00_config.sql` | All names, paths and sizes (`DEFINE`), checked into Git without secrets | — |
| 2 | `scripts/admin/03_create_tablespace.sql` | `EMK_DATA` in `C:\db_files\ia_apex_project\` (100 MB, autoextend, max 2 GB); the folder is a documented prerequisite (`docs/setup.md`) | 1 |
| 3 | `scripts/admin/04_create_roles.sql` | `EMK_OWNER_ROLE`, `EMK_DEVELOPER_ROLE`, `EMK_READONLY_ROLE` with their privileges | 1 |
| 4 | `scripts/admin/05_create_schema.sql` | `EMK_APP` (`NO AUTHENTICATION`), default tablespace, quota, `EMK_OWNER_ROLE`, direct grants for PL/SQL (e.g., `CREATE JOB`) | 2, 3 |
| 5 | `scripts/admin/06_create_dev_user.sql` | `EMK_DEV` (password entered hidden), `DB_DEVELOPER_ROLE` + `EMK_DEVELOPER_ROLE`, `EMK_APP` grants connect through `EMK_DEV` | 3, 4 |
| 6 | `scripts/admin/07_create_workspace.sql` | Workspace `EMK_CLAIMS` with primary schema `EMK_APP`; administrator user (name, email and password entered at run time) | 4 |
| 7 | `scripts/install_admin.sql` | Orchestrator: checks it runs as `SYS` in `FREEPDB1`, then calls 00, 03–07 with `@@`; one log per run (`logs/install_admin_<timestamp>.log`) | 1–6 |
| 8 | `scripts/uninstall_admin.sql` | Removes workspace, `EMK_DEV`, `EMK_APP`, roles and tablespace; requires typing `YES` | 1 |
| 9 | `scripts/admin/verify_admin.sql` | Read-only checks used by the tests (§4) | 1 |
| 10 | `scripts/admin/09_install_utplsql.sql` (+ `09a`, `09b`) | utPLSQL 3.2.3 in schema `UT3`, created **schema-only** instead of `install_headless.sql` (which uses a published default password and grants to `PUBLIC`); official `install.sql`, grant and synonym scripts; access for `EMK_APP` only; separate step after `install_admin.sql`; installer in `data/tools/` (not committed). Numbered 09 because 08 is reserved for `08_network_acl.sql` | 7 |
| 11 | SQLcl project | `project init` for schema `EMK_APP`; creates `.dbtools/` (SQLcl 25.4.2 creates `src/` and `dist/` empty, filled from M1) and appends its block to `.gitignore` (the empty `db/` and `apex/` folders were already removed on 2026-10-05) | 5 |
| 12 | `docs/setup.md` + Spanish copy | Admin installation, utPLSQL and SQLcl project steps | 7–11 |

Scripts `01_vector_memory.sql` and `02_account_hardening.sql` are environment hardening already applied; they stay separate steps in `docs/setup.md` and are not called by the orchestrator (`02` rotates a password interactively).

## 4. Tests and Traceability

| Test | What it proves | How | Criterion |
|------|----------------|-----|-----------|
| T-M0-01 | Admin installation is idempotent | Run `install_admin.sql` twice; the second run reports "already exists" and ends without errors | SC-DEP-03 |
| T-M0-02 | All objects exist as designed | `verify_admin.sql`: tablespace, roles, `EMK_APP` with authentication `NONE`, `EMK_DEV`, proxy `EMK_DEV → EMK_APP`, workspace `EMK_CLAIMS` | SC-DEP-01 |
| T-M0-03 | Least privilege | `EMK_APP` and `EMK_DEV` hold no `DBA`, `CONNECT` or `RESOURCE` (`DBA_ROLE_PRIVS`) | spec §7.5 |
| T-M0-04 | Clean rebuild | `uninstall_admin.sql` then `install_admin.sql` ends with T-M0-02 passing | SC-DEP-02 |
| T-M0-05 | Proxy deployment works | `sql -thin EMK_DEV[EMK_APP]@localhost:1521/FREEPDB1` connects and `SELECT USER` returns `EMK_APP` | ADR-005 |
| T-M0-06 | utPLSQL works | `SELECT ut.version() FROM dual` and a sample test run as `EMK_DEV[EMK_APP]` | SC-QA-02 |
| T-M0-07 | SQLcl project is initialised | `project init` structure exists and is committed | ADR-005 |
| T-M0-08 | No secrets in files | Search the repository for literal passwords (`IDENTIFIED BY "…"` without a substitution variable) | SC-SEC-02 |

## 5. Definition of Done

- All tests T-M0-01 to T-M0-08 pass, with evidence (logs or screenshots) recorded in the pull request.
- `docs/setup.md` and its Spanish copy describe the new steps.
- Pull request reviewed and merged to `main`.

## 6. Open Points

| # | Point | Proposal |
|---|-------|----------|
| 1 | Synthetic data generator listed in M0 (spec §9) | **Decided:** moved to M1 (spec v1.1) |
| 2 | utPLSQL version | **Decided:** latest stable release, verified before installation |
| 3 | SQLcl `project init` options (project name, schema filter) | **Decided:** verified with `project -help` and the SQLcl documentation; project `emk_claims`, schema `EMK_APP` |

## 7. Test Results

Run on the reference machine. Logs are local (`logs/`, not committed) and summarised in the pull request.

| Test | Date | Result | Evidence |
|------|------|--------|----------|
| T-M0-01 | 2026-10-05 | ✅ Pass | Second run: every step reports "already exists"; no password prompts (`install_admin_20261005_214040.log`) |
| T-M0-02 | 2026-10-06 | ✅ Pass | `verify_admin.sql`: 9/9 PASS (`install_admin_20261006_012725.log`) |
| T-M0-03 | 2026-10-06 | ✅ Pass | Check "No DBA, CONNECT or RESOURCE" PASS (same log) |
| T-M0-04 | 2026-10-06 | ✅ Pass | `uninstall_admin.sql` → `install_admin.sql` (all objects "created", 9/9 PASS) → `09_install_utplsql.sql` (6/6 PASS) |
| T-M0-05 | 2026-10-05 | ✅ Pass | As `EMK_DEV[EMK_APP]`: `USER` = `EMK_APP`, `PROXY_USER` = `EMK_DEV` |
| T-M0-06 | 2026-10-06 | ✅ Pass | `ut.version()` = `v.3.2.3.4508` as `EMK_APP`; sample suite: 2 tests, 1 intentional failure reported with expected and actual values; package dropped afterwards |
| T-M0-07 | 2026-10-06 | ✅ Pass | `project init -name emk_claims -schemas EMK_APP` succeeded; `.dbtools/` committed with this milestone |
| T-M0-08 | 2026-10-06 | ✅ Pass | 45 files and all 18 commits searched: every `IDENTIFIED BY` uses a substitution variable or placeholder; no passwords, keys or personal emails |

## 8. Revision History

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-10-05 | Accepted by the owner. |
| v1.1 | 2026-10-06 | Aligned with the implementation: tablespace folder is a prerequisite; utPLSQL through `09_install_utplsql.sql` (schema-only `UT3`, access for `EMK_APP` only); one log per run; `project init` result; test results (§7). |
