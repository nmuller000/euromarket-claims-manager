# Setup Guide

How to build the local development environment for this project, in installation order. Versions are those **verified on the reference machine** (2026-10-03); newer releases exist and upgrades are decided per milestone. Values in `<ANGLE_BRACKETS>` are placeholders: never commit real passwords. Terms are defined in the [glossary](glossary.md).

## 1. Requirements

| Item | Reference machine |
|------|-------------------|
| Operating system | Windows 11 (10.0.26200), 64-bit; computer name without spaces or special characters |
| CPU / RAM | Intel Core i5-8300H / 20 GB (the database uses at most 2 GB in the Free edition) |
| Rights | Administrator (database installation, service restarts) |

## 2. Versions

| Component | Version | Purpose |
|-----------|---------|---------|
| Oracle JDK | 17.0.18 | Runtime for SQLcl and ORDS |
| Oracle AI Database Free | 26ai, release 23.26.1 | Database, vector search, PL/SQL |
| Oracle APEX | 24.2.0 | Application framework |
| ORDS | 25.4 | Web listener for APEX and REST (standalone mode) |
| SQLcl | 25.4.2 | Scripts and deployment |
| Git | 2.53.0 | Version control |
| Visual Studio Code | 1.136 | Editor (Mermaid diagrams render natively since 1.121) |
| Node.js / npm | 24.14.1 / 11.11.0 | ESLint for APEX JavaScript |
| Mailpit | latest | Local email testing (milestone M2) |
| utPLSQL | 3.2.3 | PL/SQL unit tests |

## 3. Installation Steps

### 3.1 Oracle JDK 17

1. Download the Windows x64 installer of JDK 17 from [Oracle Java downloads](https://www.oracle.com/java/technologies/downloads/) and install it.
2. Set `JAVA_HOME` to the JDK folder and put `%JAVA_HOME%\bin` **first** in the system `Path`.
3. Verify in a new terminal: `java -version` → `17.x`.

> SQLcl 25.4 failed to start with Java 21 on the reference machine (`NoClassDefFoundError`); JDK 17 solved it.

### 3.2 Oracle AI Database 26ai Free

1. Download *Oracle AI Database Free for Windows* from [oracle.com/database/free](https://www.oracle.com/database/free/) and extract the ZIP into a short path (e.g., `C:\OracleInstall`).
2. Right-click `setup.exe` → **Run as administrator** (if the installer closes silently, run it again).
3. Keep the default installation folder.
4. Enter the password for `SYS`, `SYSTEM` and `PDBADMIN`: `<SYS_PASSWORD>`.
5. If the Windows Firewall asks, allow access on **private networks** only.
6. Check the summary: container database `FREE`, pluggable database `FREEPDB1`. Install (15–30 minutes).
7. Verify: `sql -thin sys@localhost:1521/FREEPDB1 as sysdba` (after SQLcl is installed) or `sqlplus sys@localhost:1521/FREEPDB1 as sysdba`.

> If the installation freezes while configuring the network, an antivirus may be blocking Oracle services.

### 3.3 Development User

Connected as `SYS` to `FREEPDB1`:

```sql
CREATE USER dev_user IDENTIFIED BY "<DEV_USER_PASSWORD>";
GRANT DB_DEVELOPER_ROLE TO dev_user;          -- developer privileges, not DBA
ALTER USER dev_user QUOTA UNLIMITED ON USERS;
```

### 3.4 Oracle APEX 24.2

1. Download *Oracle APEX 24.2 — All languages* from [APEX downloads](https://www.oracle.com/tools/downloads/apex-downloads/).
2. Extract it so that `apexins.sql` is directly in `C:\apex` (move the contents of the inner `apex` folder up; `META-INF` is not needed).
3. In an Administrator terminal:

   ```text
   cd C:\apex
   sql -thin sys@localhost:1521/FREEPDB1 as sysdba
   @apexins.sql SYSAUX SYSAUX TEMP /i/
   ```

   The installation takes 10–20 minutes and ends at the `SQL>` prompt.
4. Create the instance administrator: `@apxchpwd.sql` → user `ADMIN`, email `<ADMIN_EMAIL>`, password `<APEX_ADMIN_PASSWORD>` (at least 8 characters with upper case, lower case, a digit and a symbol).

### 3.5 ORDS 25.4 (standalone)

1. Download ORDS from the [ORDS download page](https://www.oracle.com/database/sqldeveloper/technologies/db-actions/download/) and extract it into `C:\ords`.
2. In an Administrator terminal:

   ```text
   cd C:\ords\bin
   ords --config C:\ords\config install
   ```

3. Wizard answers:

   | Prompt | Answer |
   |--------|--------|
   | TNS service or database connection | `S` (specify the connection) |
   | Connection type | `1` (Basic) |
   | Host / port | `localhost` / `1521` |
   | Service name | `FREEPDB1` |
   | Administrator user / password | `SYS` / `<SYS_PASSWORD>` |
   | **[3]** Password for `ORDS_PUBLIC_USER` | `S` (specify your own): `<ORDS_PUBLIC_USER_PASSWORD>` |
   | **[9]** APEX static resources location | `C:\apex\images` (otherwise APEX has no icons or styles) |
   | Accept | `A` |

4. Success message: `Oracle REST Data Services initialized. HTTP Listen Port: 8080`.
5. To start ORDS later: `C:\ords\bin\ords --config C:\ords\config serve` (keep the window open while using APEX).

### 3.6 APEX Workspace

1. Open `http://localhost:8080/ords` → **Oracle APEX** → workspace `INTERNAL`, user `ADMIN`.
2. **Create Workspace:** name `PROJECT_AI`, re-use existing schema `DEV_USER`, administrator `<WORKSPACE_ADMIN>` / `<WORKSPACE_ADMIN_PASSWORD>`, with your name and email.

### 3.7 SQLcl 25.4

1. Download from the [SQLcl download page](https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/) and extract into `C:\sqlcl`.
2. Add `C:\sqlcl\bin` to the system `Path`.
3. Verify: `sql -v`. Always connect with the thin driver: `sql -thin <user>@localhost:1521/FREEPDB1`.

### 3.8 Git

1. Install *64-bit Git for Windows* from [gitforwindows.org](https://gitforwindows.org/). Recommended options:

   | Option | Choice |
   |--------|--------|
   | Default editor | Visual Studio Code |
   | Initial branch name | Override: `main` |
   | PATH | Git from the command line and also from 3rd-party software |
   | SSH | Use bundled OpenSSH |
   | HTTPS backend | OpenSSL |
   | Line endings | Checkout Windows-style, commit Unix-style |
   | `git pull` behaviour | Fast-forward or merge |
   | Credential helper | Git Credential Manager |

2. Configure your identity:

   ```text
   git config --global user.name "<YOUR_NAME>"
   git config --global user.email "<YOUR_EMAIL>"   # or the GitHub no-reply address
   git config --global init.defaultBranch main
   ```

### 3.9 Visual Studio Code

1. Install from [code.visualstudio.com](https://code.visualstudio.com/) (User Installer).
2. Extensions:

   | Extension | ID | Use |
   |-----------|----|-----|
   | Oracle SQL Developer | `oracle.sql-developer` | Connections, worksheets, PL/SQL |
   | ESLint | `dbaeumer.vscode-eslint` | JavaScript linting |
   | Claude Code | `anthropic.claude-code` | AI-assisted development (optional) |

3. New connection: type Basic, user `dev_user`, password `<DEV_USER_PASSWORD>`, host `localhost`, port `1521`, service `FREEPDB1`.

### 3.10 Node.js

Install the Windows installer (`.msi`) from [nodejs.org](https://nodejs.org/). The optional Chocolatey tools are not needed.

### 3.11 Mailpit (M2)

Local email server for alert testing; to be documented when milestone M2 starts. Source: [mailpit.axllent.org](https://mailpit.axllent.org/).

## 4. Project Setup

```powershell
git clone https://github.com/nmuller000/ia-apex-project.git
cd ia-apex-project
npm ci                     # installs ESLint from package-lock.json
npm run lint
```

Third-party files are kept locally and not committed: source documents (e.g., the CMR text) in `data/sources/`, the embedding model in `data/models/` (ADR-004) and tool installers (utPLSQL) in `data/tools/`.

## 5. Database Configuration

### 5.1 Environment Hardening (once)

| Step | Script | Notes |
|------|--------|-------|
| 1 | `scripts/admin/01_vector_memory.sql` | Vector pool for HNSW (ADR-001). Restarts the database service: run from an **Administrator** PowerShell. |
| 2 | `scripts/admin/02_account_hardening.sql` | Locks unused accounts, makes proxy-only accounts schema-only, rotates the ORDS password. |
| 3 | `ords --config C:\ords\config config secret db.password` | Stores the new ORDS password; then restart ORDS. |
| 4 | `scripts/admin/check_password_expiry.sql` | Read-only check; repeat periodically. |

### 5.2 Project Database Objects (ADR-005, ADR-007)

1. **Prerequisite:** create the datafile folder on the database server (once):

   ```powershell
   New-Item -ItemType Directory -Force C:\db_files\ia_apex_project
   ```

2. **Install** (idempotent; asks for the `EMK_DEV` password and the workspace administrator only when they are created):

   ```powershell
   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/install_admin.sql
   ```

   | Step | Creates or sets |
   |------|-----------------|
   | 1 Tablespaces | `EMK_DATA` (application) and `EMK_INT_DATA` (integration) |
   | 2 Roles | `EMK_OWNER_ROLE`, `EMK_DEVELOPER_ROLE` (development privileges in proxy sessions, including PL/SQL debugging), `EMK_READONLY_ROLE` |
   | 3 Schemas | `EMK_APP` and `EMK_INT`, schema-only (no password) |
   | 4 Developer account | `EMK_DEV`: `CREATE SESSION` only, profile `ORA_CIS_PROFILE`, proxy to `EMK_APP` and `EMK_INT` |
   | 5 APEX workspace | `EMK_CLAIMS` |
   | 6 Network access | ACL `jdwp` on `localhost` / `127.0.0.1` for `EMK_APP` and `EMK_INT` (PL/SQL debugger) |

   Then runs `verify_admin.sql` (expected: `RESULT: all checks passed`). Names and sizes are in `scripts/admin/00_config.sql`. Each run writes its own log, `logs/install_admin_<YYYYMMDD_HH24MISS>.log`; prompts are not logged. The personal account `DEV_USER` is not touched.

3. **Work as the application or the integration schema** through the developer account (proxy authentication: the password asked is the one of `EMK_DEV`). `EMK_DEV` alone cannot create objects (`ORA-01031`):

   ```powershell
   sql -thin "EMK_DEV[EMK_APP]@localhost:1521/FREEPDB1"
   sql -thin "EMK_DEV[EMK_INT]@localhost:1521/FREEPDB1"
   ```

4. **Remove everything** (asks to type `YES`; close `EMK_DEV` sessions first). `UT3` (utPLSQL) is kept:

   ```powershell
   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/uninstall_admin.sql
   ```

   To rebuild, run `install_admin.sql` and then `09_install_utplsql.sql` (§5.3) again, which restores the utPLSQL grants of `EMK_APP`.

### 5.3 utPLSQL

utPLSQL is installed into schema `UT3`, created **schema-only** (no password): the official quick installer (`install_headless.sql`) would create it with a published default password and grant the framework to `PUBLIC`. `09_install_utplsql.sql` uses the official `install.sql`, grant and synonym scripts instead and grants access to `EMK_APP` only.

1. Download `utPLSQL.zip` from the [v3.2.3 release](https://github.com/utPLSQL/utPLSQL/releases/tag/v.3.2.3) and check its SHA-256 checksum against the value published on the release page:

   ```powershell
   New-Item -ItemType Directory -Force data\tools
   Move-Item "$env:USERPROFILE\Downloads\utPLSQL.zip" data\tools\
   (Get-FileHash data\tools\utPLSQL.zip -Algorithm SHA256).Hash -eq '6e650fc497bce02ae611e185e66c72204f0b984a024a41733b5452e7fb6db47a'
   Expand-Archive -Path data\tools\utPLSQL.zip -DestinationPath data\tools -Force
   ```

   The checksum comparison must return `True`, and `data\tools\utPLSQL\source\install.sql` must exist.

2. **Install** (after §5.2; separate step, idempotent):

   ```powershell
   sql -thin sys@localhost:1521/FREEPDB1 as sysdba @scripts/admin/09_install_utplsql.sql
   ```

   Expected: `RESULT: all checks passed`. Logs: `logs/install_utplsql_<timestamp>.log` and, on first installation, `logs/install_utplsql_<timestamp>_official.log`. Delete the temporary file `params.sql.tmp` left in the repository root by the official scripts.

3. **Check** as the application schema:

   ```sql
   SELECT ut.version() FROM dual;   -- connected as EMK_DEV[EMK_APP]
   ```

### 5.4 SQLcl Project (ADR-005)

The application layer is versioned with SQLcl `project`. It was initialised once, from the repository root, connected as `EMK_DEV[EMK_APP]`:

```sql
project init -name emk_claims -schemas EMK_APP -verbose
```

This created `.dbtools/` (project configuration and export filters, default branch `main`) and appended an *Oracle SQLcl Projects* block to `.gitignore`. `src/` and `dist/` are filled from M1 with `project export` and `project stage`. A new clone does not need to run `project init` again.

**APEX application 200** (`EuroMarket Claims Manager`, alias `EMK_CLAIMS`, workspace `EMK_CLAIMS`) was created once in App Builder and is exported, connected as `EMK_DEV[EMK_APP]`, with:

```sql
project export -objects APEX.200 -schemas EMK_APP -verbose
```

- The export is written to `src/database/emk_app/apex_apps/f200/`: `f200.sql` (installable) and `readable/` (YAML, for review and diffs).
- Application roles are exported; user role assignments are not (`expAclAssignments: false`) and are created per environment.
- `project export -list` reports "0 objects" for an APEX application: the counter covers database objects only. The debug output (`-debug`) shows `application_id=200` when the application is found.
- `project export` overwrites files but does not delete the YAML of components removed in APEX. After deleting a component, remove its file from `readable/`, or delete `f200/` and export again.

### 5.5 PL/SQL Debugger (SQL Developer for VS Code)

Prerequisites are installed by the admin layer: `DEBUG CONNECT SESSION` and `EXECUTE`/`DEBUG` on `SYS.DBMS_DEBUG_JDWP` through `EMK_DEVELOPER_ROLE`, and the ACL `jdwp` on `localhost` / `127.0.0.1` (script `08`). Steps ([Oracle documentation](https://docs.oracle.com/en/database/oracle/sql-developer-vscode/24.4/sqdnx/debugging-pl-sql-objects.html)):

1. Connect as `EMK_DEV[EMK_APP]` (or `EMK_DEV[EMK_INT]`).
2. Compile the package for debugging. If the editor icon does not take effect, use `ALTER PACKAGE <name> COMPILE DEBUG;` and check `user_plsql_object_settings.plsql_debug = 'TRUE'`.
3. Set a breakpoint, choose the subprogram in **Execute → Debug**, enter the parameters, and select **127.0.0.1** as the debugger address. Do not run the ACL code the extension offers: the ACL already exists.
4. **Stop** ends the debugged session with `ORA-30687: session terminated by debugger` (expected); its uncommitted work is rolled back.
5. Afterwards recompile without debug information: `ALTER PACKAGE <name> COMPILE;`.

## 6. Verification

| Check | Command or action | Expected |
|-------|-------------------|----------|
| Database service | `Get-Service OracleServiceFREE` | `Running` |
| Database version | `SELECT banner_full FROM v$version;` | Oracle AI Database 26ai Free 23.26.1 |
| Vector pool | `SHOW PARAMETER vector_memory_size` (in `CDB$ROOT`) | `128M` |
| APEX version | `SELECT version_no FROM apex_release;` | 24.2.x |
| Project objects | `@scripts/admin/verify_admin.sql` (as `SYS`) | `RESULT: all checks passed` |
| utPLSQL | `SELECT ut.version() FROM dual;` (as `EMK_DEV[EMK_APP]`) | `v.3.2.3.x` |
| ORDS / APEX | Open `http://localhost:8080/ords/` | APEX landing page |
| Tooling | `npm run lint` | Runs without configuration errors |

## 7. Operational Notes

- After a database restart, restart ORDS.
- Check account expiry before it affects ORDS: `scripts/admin/check_password_expiry.sql`.
- Back up schemas with Data Pump (`expdp`) before large changes.
- Accounts of people use `ORA_CIS_PROFILE` (ADR-007): the password expires every 90 days and the account **locks after 120 days without login** (`ORA-28000`). Unlock as `SYS`: `ALTER USER emk_dev ACCOUNT UNLOCK;`.
- Privileges used inside PL/SQL must be granted **directly** to the owning schema: roles are disabled in definer's-rights code. Symptom: a statement works in SQLcl but fails inside a package with an insufficient-privileges error.
