# EuroMarket AI-Driven Compliance & Claims Manager

Web application for managing **cross-border road freight claims** under the **CMR Convention**: claims and documents in one place, CMR deadline tracking with alerts, multilingual legal search and claim indicators by carrier, route and country.

Built on **Oracle AI Database 26ai** and **Oracle APEX**. The MVP runs entirely in the database, with no external services.

> **Status:** in development — Stage 3 (Build), milestone **M1 — Claims core** (M1a: data core). See [docs/sdlc.md](docs/sdlc.md).
> Every design decision is taken for a **professional, multi-developer setting** and recorded as an [Architecture Decision Record](docs/adr/README.md) with the options considered, the reasons and, where possible, a test on the target versions.

## Technology

| Area | Technology |
|------|------------|
| Database | Oracle AI Database 26ai Free (PL/SQL, AI Vector Search) |
| Application | Oracle APEX 24.2, ORDS 25.4 |
| Deployment | SQLcl 25.4: admin scripts + SQLcl `project` (Liquibase) — [ADR-005](docs/adr/ADR-005-deployment-and-database-setup.md) |
| Tests | utPLSQL 3.2.3 |

## Architecture at a Glance

```mermaid
flowchart LR
    user["Users<br/>4 APEX roles"] --> ords["ORDS"] --> apex["APEX app<br/>parsing schema EMK_UI"]
    apex -->|"EXECUTE APIs · SELECT views"| api["EMK_API<br/>business APIs, views, log"]
    int["EMK_INT<br/>file import, ECB rates"] -->|"EXECUTE APIs"| api
    api -->|"object privileges"| data[("EMK_DATA<br/>tables, journals")]
```

Business rules live in PL/SQL APIs, never in APEX pages. Details: [API design](docs/design/api-design.md) · [data model](docs/design/README.md).

## Key Design Decisions

| Area | How it is solved | Status | Reference |
|------|------------------|--------|-----------|
| **Schema separation** | Data (`EMK_DATA`), business code and views (`EMK_API`), application connect user (`EMK_UI`, owns nothing), integration (`EMK_INT`). The application cannot bypass the APIs: `EMK_UI` has no privilege on any table. Follows the SmartDB / PinkDB paradigms | Implemented in DEV (accounts, encrypted tablespaces; admin scripts per environment); objects move from `EMK_APP` in migration phases M.3–M.4 | [ADR-008](docs/adr/ADR-008-schema-separation.md) |
| **Developer access (proxy accounts)** | Owner schemas have **no password**. Each developer has a personal account with `CREATE SESSION` only and **proxy** access to the schemas of his or her work: `ANA[EMK_DATA]` models tables, `JUAN[EMK_API]` writes APIs and cannot drop a table. Every change is attributed to a person (`PROXY_USER`) and access is revoked per person. Compared with 23ai schema privileges by test | Implemented in DEV: proxies to the separated schemas; every change attributed to the person in the audit trail (T-M1-34) | [ADR-007](docs/adr/ADR-007-integration-schema-and-account-hardening.md), [ADR-008](docs/adr/ADR-008-schema-separation.md) |
| **Deployment account** | `EMK_DEPLOY`, the pipeline user, deploys with **schema privileges limited to the project schemas** (23ai `GRANT … ON SCHEMA`); nobody deploys as an owner | Implemented (account, schema privileges verified on 26ai); first deployment in migration phase M.5 | [ADR-008](docs/adr/ADR-008-schema-separation.md) |
| **Environments (DTAP)** | One PDB per environment: DEV, TEST (developer tests), ACCEPTANCE (customer tests, signed acceptance), PRODUCTION (defined). Same schema names everywhere, so **the same artifact** moves through all environments. Outside DEV: no developer proxy, APEX runtime-only, only `EMK_DEPLOY` changes objects | Decided | [ADR-009](docs/adr/ADR-009-environments.md) |
| **Least privilege and hardening** | No `DBA`/`CONNECT`/`RESOURCE`; privileges used by PL/SQL granted directly (roles are disabled in definer's-rights code, verified); CIS password profile for people; outbound network only by ACL script; no REST-enabled project schema; automated verification (`verify_admin.sql`) | Implemented (M0, M1a) | [ADR-005](docs/adr/ADR-005-deployment-and-database-setup.md), [ADR-007](docs/adr/ADR-007-integration-schema-and-account-hardening.md) |
| **Data integrity** | Rules within a row as check constraints (formats without NLS-dependent ranges, explicit `IS NOT NULL`, business dates without time); rules across tables in the APIs; optimistic locking against lost updates; immutable claim documents | Implemented (tables); APIs in progress | [spec §1.3](docs/spec.md), [API design](docs/design/api-design.md) |
| **Audit trail** | Audit columns on every table (who and when, including the APEX user); journal tables keep the previous version of every changed row; soft delete only; technical log in an autonomous transaction | Implemented | [Data model](docs/design/README.md) |
| **Scalability** | Monthly interval partitioning of append-only tables (logs, journals) with purge by partition; an index on every foreign key; stateless ORDS (several nodes behind a load balancer); growth path to Enterprise Edition or Autonomous Database without code changes | Designed; partitioning implemented | [spec §12](docs/spec.md) |
| **Backup, recovery and release rollback** | Archive log mode, RMAN backups and a [recovery runbook](docs/operations/recovery-runbook.md) with restore drills; targets derived from the business (RPO ≤ 1 h, RTO ≤ 4 h); guaranteed restore point before each deployment, decision matrix for rollback vs. fix-forward, backward-compatible schema changes, pilot users through feature flags | Implemented in DEV: `ARCHIVELOG`, encrypted RMAN backups, restore drill (M.1, drill protocol); release rollback with the first deployment (M.5) | [ADR-010](docs/adr/ADR-010-operations-and-release-strategy.md) |
| **Database auditing, encryption in transit, performance targets** | Unified Auditing of DDL, grants and logons of the project schemas, 1 year online plus a pseudonymised archive; HTTPS outside DEV; page response p95 < 2 s and Apdex at the design volume, shown on an operations page | Auditing implemented (T-M1-34); HTTPS and performance targets planned | [ADR-010](docs/adr/ADR-010-operations-and-release-strategy.md) |
| **Encryption at rest and key management** | Project tablespaces encrypted with TDE (AES-256); keys in a keystore that opens automatically only on its own server; RMAN backups encrypted (Data Pump export encryption is not available in Free, see below); **keys never kept with the data** (keystore copies in two places apart from the backups). A lost backup disk exposes no personal data or business secrets | Implemented in DEV (T-M1-35, T-M1-36; keystore recovery tested) | [ADR-011](docs/adr/ADR-011-tablespace-encryption.md), [backup runbook](docs/operations/backup-runbook.md) |

## Edition Constraints and Growth Path

The project runs on **Oracle AI Database 26ai Free** on one machine. What this edition or setup does not allow is **not implemented**, but it is documented with its replacement and growth path, so that a production project includes it ([ADR-010 §8](docs/adr/ADR-010-operations-and-release-strategy.md), [spec §12.3](docs/spec.md)).

| Not available here | Replaced by | Growth path |
|--------------------|-------------|-------------|
| Data Guard (standby database) | Archived logs backed up every 30 min, restore from backup | Enterprise Edition + Data Guard: RPO of seconds or zero, failover in minutes |
| RAC, parallel backup and recovery | One instance, one RMAN channel | Enterprise Edition / Autonomous Database |
| Flashback Transaction, tablespace point-in-time recovery | Journal tables, PDB point-in-time recovery and flashback | Enterprise Edition |
| Online encryption of existing tablespaces | Tablespaces created encrypted | Enterprise Edition + Advanced Security |
| TDE in Enterprise Edition on premises | Included in Free | **Advanced Security option (extra cost per processor)**; Standard Edition 2 on premises: not available; Oracle Cloud: included |
| Data Pump export encryption (`ORA-00439` in 26ai Free, verified 2026-10-15) | No logical copy with data in Free so far: recovery relies on encrypted RMAN backups and the keystore copies (two places per ADR-011; the second, a dedicated USB stick, still pending); the structure-only dump of the schema migration was deleted after use; the logical copy before releases is decided before the first ACCEPTANCE release ([M1 plan](docs/plans/M1-plan.md), open point 11) | Enterprise Edition + Advanced Security, or Oracle Cloud (included) |
| Central key management (Oracle Key Vault, HSM) | Software keystore with two separate copies | Oracle Key Vault (separate licence), HSM or cloud vault |
| More than 2 CPUs, 2 GB RAM, 12 GB data | Partitioning, sizing, document size limit | Enterprise Edition / Autonomous Database |
| Separate servers, disks and off-site backups | All environments as PDBs of one CDB; backups in a separate folder | One server per environment, backup storage off-site |
| Dedicated storage for application data | The project data files live in their own folder (`emk_datafile_root`), kept apart from the files Oracle manages; on the reference machine that folder sits on the only disk available, a limit of the development hardware rather than a design choice | In a company installation `emk_datafile_root` points to a dedicated disk or volume, so that growing application data can never exhaust the space of the system tablespaces, its I/O stays isolated, and its capacity and backups are managed on their own |

## How This Project Is Built

The project follows an AI-native development life cycle ([docs/sdlc.md](docs/sdlc.md)): every stage (intent, specification, plan, code, tests, review) produces a versioned artifact. I work with **Claude Code** (Anthropic) as a pair programmer: I set the requirements and the architecture, compare the options it researches, take the decisions (recorded as ADRs), review every change and verify it with tests on the target versions (Oracle AI Database 26ai, APEX 24.2, ORDS 25.4, SQLcl 25.4).

## Data Protection (GDPR by Design)

- **No personal data leaves the database in the MVP:** semantic search uses an ONNX model inside Oracle AI Database; there are no external calls.
- **Personal data is isolated** in one table (`EMK_CONTACTS`) and its journal, which keeps erasure and pseudonymisation simple (GDPR Art. 17, 25).
- **Test data:** synthetic in development and test; anonymised in acceptance; never real personal data without protection.
- **Planned AI extensions:** every external AI call goes through a single gateway that **redacts or pseudonymises personal data before the call** and re-identifies it only inside the database (FR-21); a test criterion requires zero unredacted personal data in outbound payloads (SC-SEC-04); every call is logged with its redacted payload (FR-23); providers process data in the EU/EEA under a data processing agreement.

## Documentation

| Document | Content |
|----------|---------|
| [Intent](docs/intent.md) | Problem, users, scope |
| [Specification](docs/spec.md) | Requirements, business rules, design, test strategy |
| [Architecture decisions](docs/adr/README.md) | ADRs: options, reasons, verification |
| [Data model](docs/design/README.md) · [API design](docs/design/api-design.md) | Physical design, packages, call flows |
| [SDLC](docs/sdlc.md) | Development stages and current status |
| [Setup guide](docs/setup.md) | Local environment and database installation |
| [Backup runbook](docs/operations/backup-runbook.md) | Routine backups: concepts in plain words, schedule, retention, where backups and keys are kept |
| [Recovery runbook](docs/operations/recovery-runbook.md) | What to do when data is lost: scenarios, commands, business reconciliation, restore drills |
| [Glossary](docs/glossary.md) | Functional and technical terms |

## Repository Layout

| Folder | Content |
|--------|---------|
| `docs/` | Intent, specification, plans, ADRs, design, operations runbooks, glossary, setup guide |
| `scripts/` | Admin scripts run as `SYS` (tablespaces, roles, schemas, accounts, workspace, network ACL, utPLSQL, verification) |
| `.dbtools/`, `src/`, `dist/` | SQLcl project: database objects and APEX app 200 |
| `static/` | APEX static files (JavaScript, CSS) |

## Author

Natalia Müller ([@nmuller000](https://github.com/nmuller000))

## License

Copyright (c) 2026 Natalia Müller. **All rights reserved.** This repository is published for viewing and evaluation only; no part of it (code, scripts or documentation) may be copied, modified, distributed or used without the author's prior written consent. See [LICENSE](LICENSE).
