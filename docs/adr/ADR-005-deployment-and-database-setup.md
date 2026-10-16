# ADR-005: Deployment Method and Database Setup

| Field | Value |
|-------|-------|
| **Status** | Accepted · developer-account privileges amended by [ADR-007](ADR-007-integration-schema-and-account-hardening.md) · single schema `EMK_APP`, tablespace `EMK_DATA` and APEX primary schema superseded by [ADR-008](ADR-008-schema-separation.md) and [ADR-011](ADR-011-tablespace-encryption.md) |
| **Date** | 2026-10-04 |
| **Deciders** | Solution Architect (project owner) |
| **Related** | [spec.md](../spec.md) §7, §10 · [intent.md](../intent.md) §7 (Q1, Q5) · SC-DEP-01 to SC-DEP-04 |

---

## Context

The project starts from a clean database setup, separate from earlier experiments:

- A **dedicated tablespace, schema, roles and APEX workspace**, all prefixed `EMK_` (EuroMarket).
- **No default grants** (such as `CONNECT`, `RESOURCE` or `DBA`); privileges come from project roles.
- **Every script is idempotent** where re-execution is possible (SC-DEP-03).
- The environment must be rebuilt with **one documented command** (SC-DEP-02).

Two layers have different lifecycles:

| Layer | Content | Runs as | Frequency |
|-------|---------|---------|-----------|
| **Admin** | Tablespace, schema, roles, APEX workspace, instance settings | `SYS` in `FREEPDB1` | Once per environment |
| **Application** | Tables, views, packages, reference data, APEX application | Project schema | Every release |

SQLcl 25.4 on the reference machine includes the `project` command (`init`, `export`, `stage`, `release`, `gen-artifact`, `deploy`, `verify`), verified on 2026-10-04.

---

## Options Considered

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. Plain SQLcl scripts** | Orchestrator scripts call numbered scripts with `@@`; idempotency written by hand | Simple and transparent | Every script needs its own existence checks; no record of which changes were applied |
| **B. SQLcl `project`** (Liquibase) for everything | Changes exported from the database into versioned changelogs; releases packaged as artifacts | Change tracking; APEX export included; Oracle's recommended CI/CD path | Not designed for tablespaces, users and workspaces created as `SYS` |
| **C. Hybrid** | Admin layer with option A; application layer with option B | Each layer uses the tool that fits it | Two mechanisms to learn |

---

## Decision

Adopt **Option C**:

- **Admin layer:** plain, idempotent SQLcl scripts orchestrated by `scripts/install_admin.sql`.
- **Application layer:** SQLcl `project`, which applies each change once and records it, so idempotency comes from the tool. `project deploy` is the single command for the application.

### Database Objects

| Object | Name | Notes |
|--------|------|-------|
| Tablespace | `EMK_DATA` | Datafile in `C:\db_files\ia_apex_project\`; 100 MB, autoextend, **max 2 GB** (Free edition limit is 12 GB) |
| Application schema | `EMK_APP` | **Schema-only** (no password); quota on `EMK_DATA`; owns all application objects |
| Owner role | `EMK_OWNER_ROLE` | System privileges to create the application objects (tables, views, sequences, procedures, triggers, types, synonyms, materialized views, jobs, mining models for ONNX) |
| Developer role | `EMK_DEVELOPER_ROLE` | Session and read access for developer accounts |
| Read-only role | `EMK_READONLY_ROLE` | `SELECT` on analytical views (`EMK_V_*`); used by NL-to-SQL [EXT] |
| Developer account | `EMK_DEV` | New account with `DB_DEVELOPER_ROLE` + `EMK_DEVELOPER_ROLE`; deploys to `EMK_APP` through **proxy** (`EMK_APP` grants connect through `EMK_DEV`) |
| APEX workspace | `EMK_CLAIMS` | Primary schema `EMK_APP`; administrator user created with a password entered at run time |
| APEX application | Application ID **200** (Q5), alias `EMK_CLAIMS` | Prototype `f100` stays in its old workspace |

**Privilege rules**

- Privileges used **inside PL/SQL** (e.g., `CREATE JOB` for `DBMS_SCHEDULER`) are granted **directly** to `EMK_APP`, because roles are not active in definer's-rights code.
- Tablespace quota is granted directly (quotas cannot be granted through roles).
- Application users are **APEX users** with APEX roles (spec §7.1), not database users.

### Script Structure

```text
scripts/
├── install_admin.sql            # orchestrator (SYS, FREEPDB1): calls admin/* only
├── uninstall_admin.sql          # cleanup; requires typing YES
└── admin/
    ├── 00_config.sql            # all names, paths and sizes (DEFINE), in one place
    ├── 01_vector_memory.sql     # existing (CDB level, restarts the service)
    ├── 02_account_hardening.sql # existing
    ├── 03_create_tablespace.sql
    ├── 04_create_roles.sql
    ├── 05_create_schema.sql
    ├── 06_create_dev_user.sql   # EMK_DEV with project roles
    ├── 07_create_workspace.sql
    ├── 08_network_acl.sql       # outbound access only to configured hosts (SMTP in M2)
    └── check_password_expiry.sql, rotate_*.sql   # existing utilities
```

The application layer follows the folder layout created by `project init` (`src/`, `dist/`, `.dbtools/`), which replaces the current `db/` folder.

### Script Conventions

| Convention | Rule |
|------------|------|
| Idempotency | Every `CREATE` checks for existence first; re-running reports "already exists" and continues |
| Configuration | Names, paths and sizes only in `00_config.sql` |
| Secrets | Passwords entered with `ACCEPT ... HIDE`; no personal data (names, emails) in scripts |
| Connection | `sql -thin sys@localhost:1521/FREEPDB1 as sysdba`; every admin script checks it runs in `FREEPDB1` |
| Errors | `WHENEVER SQLERROR EXIT FAILURE` |
| Destructive actions | Cleanup scripts ask for explicit confirmation |

---

## Consequences

**Positive**
- Clean separation from earlier experiments; least-privilege roles instead of default grants.
- The application schema cannot be logged into directly.
- Application changes are tracked and released as versioned artifacts (SC-DEP-01, 03).
- `SQLcl project` is the deployment approach Oracle recommends for APEX and PL/SQL, which adds portfolio value.

**Negative / trade-offs**
- Two mechanisms to learn (plain scripts and `SQLcl project`).
- The `db/` folder layout changes to the `project init` layout.
- Administrative tasks are done as `SYS`; development as `EMK_DEV`.


---

## Amendment (2026-10-04, before first publication)

- The developer account is a **new user `EMK_DEV`**. The existing personal account `DEV_USER` is **not modified** and is not used by this project.
- The old workspace `PROJECT_AI` (prototype application 100) is removed; the project starts in the new workspace `EMK_CLAIMS`.
- Network access is granted by script (`08_network_acl.sql`), only to the hosts each milestone needs.
