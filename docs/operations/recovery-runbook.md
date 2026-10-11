# Recovery Runbook

| Field | Value |
|-------|-------|
| **Version** | v1.0 (2026-10-11) |
| **Decision** | [ADR-010](../adr/ADR-010-operations-and-release-strategy.md) §1 (targets and their business basis), §8 (edition constraints) |
| **Applies to** | CDB `FREE` with the PDBs of [ADR-009](../adr/ADR-009-environments.md) (DEV `FREEPDB1`, TEST `EMKTEST`, ACCEPTANCE `EMKACC`, PROD) |
| **Status of commands** | Written from the 26ai documentation; each command is confirmed or corrected in the first restore drill (T-M1-33) before this runbook is used in production |

This runbook says what to do when data is lost or damaged: who decides, which recovery fits the damage, the commands, how to check the result and how to recover the business work of the lost period. It never contains passwords: operating-system authentication (`/ as sysdba`, `rman target /`) or a prompt is used.

---

## 1. Targets

| Target | Value | Meaning |
|--------|-------|---------|
| **RPO** | ≤ 1 hour (internal 30 min) | At most the last hour of work is lost |
| **RTO** | ≤ 4 hours within support hours | Users work again at most 4 hours after the failure |
| **MTPD** | 1 working day | Longest outage the business tolerates (assumption until the customer's BIA) |

Business basis (≈ 5 new claims per hour, 7-day shortest CMR period, sources outside the system): ADR-010, *Business Basis of the Targets*.

## 2. Roles

| Role | Task |
|------|------|
| **Incident lead** (operations or release manager) | Opens the incident, keeps the timeline, decides the technical scenario, informs the stakeholders |
| **DBA** | Runs the recovery and the technical checks |
| **Business owner** (customer, head of claims) | Decides when data will be lost (point-in-time recovery of a whole PDB); approves reopening |
| **Claims team lead** | Organises the business reconciliation of the lost period (§7) |

## 3. Prerequisites

Recovery is only possible if these hold **before** the incident. They are set by the admin scripts and checked by monitoring (ADR-010 §7).

| # | Prerequisite | Check |
|---|--------------|-------|
| 1 | Database in `ARCHIVELOG`, fast recovery area configured (Appendix A) | `SELECT log_mode FROM v$database` → `ARCHIVELOG` |
| 2 | `ARCHIVE_LAG_TARGET = 1800` | `SHOW PARAMETER archive_lag_target` |
| 3 | RMAN: `CONTROLFILE AUTOBACKUP ON`; weekly level 0, daily level 1, archived logs every 30 min copied to separate storage (sizing: [setup.md §1.1](../setup.md)) | `SELECT MAX(next_time) FROM v$archived_log WHERE backup_count > 0` is less than 45 min old |
| 4 | Block change tracking enabled | `SELECT status FROM v$block_change_tracking` → `ENABLED` |
| 5 | Backups validated weekly | `RESTORE DATABASE VALIDATE` without errors |
| 6 | Record of the database: DBID, location of backups, location of this runbook, contact list — kept **outside** the database server | Reviewed at each drill |
| 7 | Last drill passed within the last quarter (production) or release (DEV) | Drill protocol (§9) |

## 4. Worked Example: Disk Failure at 15:00

A disk with the data files fails on a working day at **15:00**. The last archived-log backup ran at **14:30**.

```mermaid
timeline
    title Disk failure at 15:00 (estimates; replaced by drill measurements)
    14:30 : Last archived logs backed up to separate storage
    15:00 : Failure — users get errors
    15:15 : Detect — alert, incident opened, users informed
    15:45 : Diagnose and decide — scenario S1, full restore
    16:15 : RESTORE — level 0 of Sunday and level 1 backups
    16:30 : RECOVER — archived logs until 14:30
    17:00 : Verify — technical and functional checks
    17:15 : Reopen — users work again; reconciliation of 14:30–15:00 starts
```

| Result | Value | Target |
|--------|-------|--------|
| Data lost | 14:30–15:00 = **30 min** (≈ 2–3 claims and their updates) | RPO ≤ 1 h ✔ |
| Outage | 15:00–17:15 = **2 h 15 min** | RTO ≤ 4 h ✔ |
| If the server must be rebuilt (new disk, software installed again) | + about 1 h → 3 h 15 min | RTO ≤ 4 h ✔ |

Nothing starts automatically at 15:00. Every step below is done by a person, following this runbook.

## 5. Procedure

### Step 1 — Detect and record

1. Open the incident: time of the failure, symptoms, error messages (alert log: `<ORACLE_BASE>\diag\rdbms\free\free\trace\alert_free.log`).
2. Inform users: the application is unavailable; **keep a list of the work done since about one hour before the failure** (emails sent, letters, documents received).
3. Stop the scheduled jobs that write data (imports, alerts) if the database is still open.

### Step 2 — Classify the damage

| Scenario | Typical cause | Data loss | Go to |
|----------|---------------|-----------|-------|
| **S1** Loss of the database files (disk, server) | Hardware failure, deleted files | Since the last backed-up archived log (≤ 30 min) | §6 S1 |
| **S2** Logical damage to a whole PDB | Wrong mass update or delete, failed manual intervention | Everything after the chosen point in time, **in that PDB** | §6 S2 |
| **S3** Failed deployment | Error during or just after a release | None (back to the restore point before the deployment) | §6 S3 |
| **S4** Few rows changed or deleted by mistake | User or support error | None | §6 S4 |
| **S5** One data file lost or damaged blocks | Disk error on one file, corruption (`ORA-01578`) | None (complete recovery) | §6 S5 |

**Choose the smallest recovery that solves the problem.** S4 before S2; S5 before S1. A point-in-time recovery (S2) loses good work too, so the business owner decides it.

### Step 3 — Decide

| Scenario | Decided by |
|----------|------------|
| S1, S5 (complete recovery, no extra loss) | Incident lead |
| S3 | Release manager (deploy runbook) |
| S2 (later work in the PDB is lost) | **Business owner**, after the incident lead explains what will be lost |
| S4 | Claims team lead with the incident lead |

### Step 4 — Execute

See §6.

### Step 5 — Verify

| # | Check | Expected |
|---|-------|----------|
| 1 | `SELECT name, open_mode FROM v$pdbs` | All PDBs `READ WRITE` |
| 2 | `@scripts/verify_admin.sql` | All checks pass |
| 3 | Invalid objects in the project schemas (`DBA_OBJECTS`, `status = 'INVALID'`) | None |
| 4 | Smoke test suite (utPLSQL) in the PDB | Green |
| 5 | **Point reached:** newest `created_at` / `updated_at` in `EMK_DATA.EMK_CLAIMS`, `EMK_SHIPMENTS`, `EMK_CLAIM_DOCUMENTS` | Recorded as the real RPO |
| 6 | `DBMS_SCHEDULER` jobs enabled again | As before the incident |
| 7 | ORDS restarted (rule after a database restart); APEX login with a test user of each role | Login works, claims list opens |
| 8 | New full backup started after an `OPEN RESETLOGS` | Running or finished |

### Step 6 — Reopen

The business owner approves; users are informed of the **recovery point** (for example "data up to 14:30 is available; please check your work after 14:30").

### Step 7 — Business reconciliation of the lost period

| # | Action | Source |
|---|--------|--------|
| 1 | Re-enter claims, status changes and documents recorded after the recovery point | Users' lists, sent emails, received documents |
| 2 | **Legal dates first:** for each written claim, reservation or reminder sent in the lost period, record the sending date again — it suspends the limitation (CMR Art. 32(2)) | Sent letters and emails |
| 3 | Re-import shipment files received after the recovery point | Source files of `EMK_INT` (kept by the sender or the file exchange) |
| 4 | Run the deadline alert job and check the act-by dates of the next 7 days | Application |
| 5 | Exchange rates of the lost period loaded again | ECB file |

### Step 8 — Post-incident review (within 5 working days)

Timeline, measured RPO and RTO against the targets, root cause, corrective actions with owners. A missed target is corrected before new features (ADR-010 §1).

## 6. Scenarios

All RMAN and SQL commands run on the database server as a member of the operating-system DBA group (no password). Names in angle brackets are placeholders.

### S1 — Loss of the database files

1. If the server or disk is replaced: install Oracle AI Database Free in the same Oracle home and directories ([setup.md](../setup.md)); do not create a new database.
2. Restore and recover the whole CDB:

```
rman target /

STARTUP NOMOUNT;
SET DBID <dbid>;                          -- from the record of the database (prerequisite 6)
RESTORE CONTROLFILE FROM AUTOBACKUP;
ALTER DATABASE MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;                          -- applies all available archived logs, then stops
ALTER DATABASE OPEN RESETLOGS;
ALTER PLUGGABLE DATABASE ALL OPEN;
```

3. If the control files and online redo logs survived (only data files lost), `RESTORE CONTROLFILE` and `RESETLOGS` are not needed: `STARTUP MOUNT; RESTORE DATABASE; RECOVER DATABASE; ALTER DATABASE OPEN;` — this is a complete recovery without data loss.
4. Start a full backup (level 0) after `OPEN RESETLOGS`.

### S2 — Point-in-time recovery of one PDB

Only the damaged PDB goes back in time; the other PDBs keep working. Connect to the root (`CDB$ROOT`).

```
rman target /

RUN {
  SET UNTIL TIME "TO_DATE('<YYYY-MM-DD HH24:MI:SS>','YYYY-MM-DD HH24:MI:SS')";
  ALTER PLUGGABLE DATABASE <pdb> CLOSE IMMEDIATE;
  RESTORE PLUGGABLE DATABASE <pdb>;
  RECOVER PLUGGABLE DATABASE <pdb>;
  ALTER PLUGGABLE DATABASE <pdb> OPEN RESETLOGS;
}
```

- The time is just **before** the damaging action (from `UNIFIED_AUDIT_TRAIL`, `EMK_LOG` or the journals).
- If a guaranteed restore point or flashback logging covers the time, `FLASHBACK PLUGGABLE DATABASE` is faster (see S3).
- Not available in Free: tablespace point-in-time recovery (ADR-010 §8).

### S3 — Failed deployment

Follow the deploy runbook (ADR-010 §2). Core commands, connected to the root:

```
ALTER PLUGGABLE DATABASE <pdb> CLOSE IMMEDIATE;
FLASHBACK PLUGGABLE DATABASE <pdb> TO RESTORE POINT <release_rp>;
ALTER PLUGGABLE DATABASE <pdb> OPEN RESETLOGS;
```

### S4 — Few rows changed or deleted by mistake

No database restore:

1. **Business restore through the API:** soft-deleted records are restored with the restore procedures of the APIs (D-43); previous values of changed rows are in the journal `<TABLE>_JN` (`:OLD` values, user, time) and are written back through the API, so the change is audited again.
2. **Within the undo retention** (minutes to hours): a flashback query shows the rows at an earlier time, for comparison: `SELECT … FROM emk_data.<table> AS OF TIMESTAMP <time> WHERE …`.
3. `FLASHBACK TABLE` (included in Free) only with the business owner's approval: it rolls back **all** changes of the table after that time.
- Not available in Free: Flashback Transaction and Transaction Query (ADR-010 §8); the journals replace them.

### S5 — One data file lost or damaged blocks

```
rman target /

-- damaged blocks (ORA-01578): repair only those blocks
RECOVER CORRUPTION LIST;

-- one data file lost: take it offline in its PDB, restore and recover it
ALTER PLUGGABLE DATABASE <pdb> CLOSE IMMEDIATE;
RESTORE DATAFILE <file#>;
RECOVER DATAFILE <file#>;
ALTER PLUGGABLE DATABASE <pdb> OPEN;
```

`<file#>` from `V$DATAFILE` or the error message. Block-level media recovery is included in Free.

## 7. Monitoring of the Targets

| Indicator | Query or source | Alert |
|-----------|-----------------|-------|
| RPO age | `SELECT ROUND((SYSDATE - MAX(next_time)) * 1440) AS minutes FROM v$archived_log WHERE backup_count > 0` | > 45 min |
| Last level 0 / level 1 backup | `V$RMAN_BACKUP_JOB_DETAILS` | Level 0 older than 8 days, level 1 older than 26 h, status not `COMPLETED` |
| Backup validation | Result of the weekly `RESTORE DATABASE VALIDATE` | Any error |
| Fast recovery area usage | `V$RECOVERY_AREA_USAGE` | > 80 % |
| Last drill | Drill protocol | Older than one quarter (production) |

Shown on the operations page of the application (ADR-010 §7) from M2.

## 8. Restore Drill

**When:** every release in DEV (T-M1-33); every quarter in a production setup; after a change of hardware, backup storage or Oracle version.

**How:**

1. Insert **marker rows** with their time every 5 minutes into a test table during the hour before the simulated failure.
2. Simulate the failure in a copy (another PDB, or another server with the backups) — never on the environment users work on.
3. Follow this runbook step by step, with a stopwatch per phase.
4. The newest marker row after recovery gives the **measured RPO**; the time from simulated failure to successful verification gives the **measured RTO**.
5. Correct this runbook where a command or step differed.

## 9. Drill Protocol (template)

| Field | Value |
|-------|-------|
| Date, environment, participants | |
| Scenario (S1–S5) and simulated failure time | |
| Backups used (level 0, level 1, archived logs up to) | |
| Phase times: detect · decide · restore · recover · verify · reopen | |
| Newest marker row after recovery → **measured RPO** | |
| Failure to reopening → **measured RTO** | |
| Targets met (RPO ≤ 1 h, RTO ≤ 4 h) | Yes / No |
| Deviations from the runbook, corrections | |
| Actions, owner, due date | |
| Approved by (incident lead, business owner) | |

## Appendix A — Switch from NOARCHIVELOG to ARCHIVELOG

Done once per CDB, in a maintenance window: it **restarts the whole CDB**, so all PDBs (all environments on this machine) are unavailable for a few minutes. Steps from the [Administrator's Guide 26ai](https://docs.oracle.com/en/database/oracle/oracle-database/26/admin/managing-archived-redo-log-files.html).

1. **Before:** check free disk space and the current settings:

```
SELECT log_mode FROM v$database;
SHOW PARAMETER db_recovery_file_dest
SELECT group#, member FROM v$logfile ORDER BY group#;
```

2. Set the fast recovery area (size and folder outside the data-file folder; values decided in the migration plan): `ALTER SYSTEM SET db_recovery_file_dest_size = <size> SCOPE=BOTH;` and `ALTER SYSTEM SET db_recovery_file_dest = '<folder>' SCOPE=BOTH;`
3. Inform users; stop ORDS.
4. Take a last cold backup or copy of the database files (safety copy in `NOARCHIVELOG`).
5. Switch, connected with `sqlplus / as sysdba` (operating-system authentication; a stopped instance cannot be reached through the listener):

```
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ALTER PLUGGABLE DATABASE ALL OPEN;
ARCHIVE LOG LIST
```

6. Settings of ADR-010: `ALTER SYSTEM SET archive_lag_target = 1800 SCOPE=BOTH;`, `ALTER DATABASE ENABLE BLOCK CHANGE TRACKING;`, RMAN `CONFIGURE CONTROLFILE AUTOBACKUP ON;`.
7. **Immediately take a level 0 backup:** backups taken in `NOARCHIVELOG` cannot be used with archived logs.
8. Start ORDS; check the application.

To verify in the migration: OS authentication of the Windows user (group `ORA_DBA`), whether the PDBs reopen with their saved state, and how RMAN is scheduled without stored passwords.

## Sources

[Backup and Recovery User's Guide 26ai](https://docs.oracle.com/en/database/oracle/oracle-database/26/bradv/oracle-ai-database-backup-and-recovery-users-guide.pdf) · [Performing Complete Database Recovery](https://docs.oracle.com/en/database/oracle/oracle-database/26/bradv/rman-complete-database-recovery.html) · [Performing Flashback and Database Point-in-Time Recovery](https://docs.oracle.com/en/database/oracle/oracle-database/26/bradv/rman-performing-flashback-dbpitr.html) · [RMAN RECOVER](https://docs.oracle.com/en/database/oracle/oracle-database/26/rcmrf/RECOVER.html) · [Managing Archived Redo Log Files](https://docs.oracle.com/en/database/oracle/oracle-database/26/admin/managing-archived-redo-log-files.html) · [ARCHIVE_LAG_TARGET](https://docs.oracle.com/en/database/oracle/oracle-database/26/refrn/ARCHIVE_LAG_TARGET.html) · [Database Licensing Information](https://docs.oracle.com/en/database/oracle/oracle-database/23/dblic/Licensing-Information.html) · [BSI-Standard 200-4 glossary](https://www.bsi.bund.de/SharedDocs/Downloads/DE/BSI/Grundschutz/Hilfsmittel/Standard200_4_BCM/Standard_200-4_BCM_Glossar.pdf?__blob=publicationFile&v=4) · [Wiederanlauftest: RTO und RPO belegen](https://www.bcm-news.de/2026/09/22/wiederanlauftest-was-im-protokoll-stehen-muss-damit-rto-und-rpo-belegt-sind/) · [CMR Convention (UNECE)](https://unece.org/fileadmin/DAM/trans/conventn/cmr_e.pdf)

## Revision History

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-10-11 | First version with ADR-010: targets, roles, prerequisites, worked example, scenarios S1–S5, monitoring, drill and protocol, switch to `ARCHIVELOG`. |
