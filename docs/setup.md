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
| utPLSQL | to be defined in M0 | PL/SQL unit tests |

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

Third-party source documents (e.g., the CMR text) go into `data/sources/` and the embedding model into `data/models/` (ADR-004); neither is committed.

## 5. Database Configuration

| Step | Script | Notes |
|------|--------|-------|
| 1 | `scripts/admin/01_vector_memory.sql` | Vector pool for HNSW (ADR-001). Restarts the database service: run from an **Administrator** PowerShell. |
| 2 | `scripts/admin/02_account_hardening.sql` | Locks unused accounts, makes proxy-only accounts schema-only, rotates the ORDS password. |
| 3 | `ords --config C:\ords\config config secret db.password` | Stores the new ORDS password; then restart ORDS. |
| 4 | `scripts/admin/check_password_expiry.sql` | Read-only check; repeat periodically. |

## 6. Verification

| Check | Command or action | Expected |
|-------|-------------------|----------|
| Database service | `Get-Service OracleServiceFREE` | `Running` |
| Database version | `SELECT banner_full FROM v$version;` | Oracle AI Database 26ai Free 23.26.1 |
| Vector pool | `SHOW PARAMETER vector_memory_size` (in `CDB$ROOT`) | `128M` |
| APEX version | `SELECT version_no FROM apex_release;` | 24.2.x |
| ORDS / APEX | Open `http://localhost:8080/ords/` | APEX landing page |
| Tooling | `npm run lint` | Runs without configuration errors |

## 7. Operational Notes

- After a database restart, restart ORDS.
- Check account expiry before it affects ORDS: `scripts/admin/check_password_expiry.sql`.
- Back up schemas with Data Pump (`expdp`) before large changes.
