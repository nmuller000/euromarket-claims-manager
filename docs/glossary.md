# Glossary

Terms used in this repository, in two parts: **Functional** (business, logistics and regulation) and **Technical** (technology, methodology and process). Other documents link here instead of repeating definitions.

---

## Part A — Functional

### Logistics & Business

| Term | Definition |
|------|------------|
| **Act-by date** | Earliest possible reservation deadline, counting only Sundays as excluded days; used for alerts so that action is in time under any holiday calendar (spec §5.1). |
| **Agreed time-limit** | Delivery deadline agreed in the contract of carriage; used to detect delay and total loss (CMR Art. 19, 20). |
| **B2B claim** | A demand for payment or remedy raised by one company against another. |
| **Business rule** | A rule of the business domain that the system enforces (e.g., deadlines, allowed status changes); catalogued in spec §2.7. |
| **Cabotage** | Domestic transport inside a country performed by a haulier registered in another country. |
| **Carrier** | The company that undertakes to transport the goods; liable under the CMR for loss, damage and delay, within limits. |
| **Claimant** | The person who makes a claim against the carrier: the sender or the consignee of the shipment (CMR Art. 12, 13; BR-19). |
| **Consignee** | The party entitled to receive the goods at destination. |
| **Consignment note (CMR note)** | The transport document that confirms the contract of carriage under the CMR. |
| **Cross-trade** | Transport between two countries by a haulier registered in a third country. |
| **Declared value** | Value of the goods declared in the consignment note against a surcharge; it replaces the CMR liability limit of 8.33 SDR per kg (CMR Art. 24). |
| **Goods placed at the disposal of the consignee** | The moment the consignee can take the goods; the 21-day reservation for delay counts from it (CMR Art. 30(3)). |
| **Gross weight short** | Gross weight of the goods lost or missing; basis of the CMR liability limit. |
| **Joint check** | Inspection of the goods carried out together by the consignee and the carrier (CMR Art. 30(2)). |
| **Partial admission** | The carrier accepts part of a claim; the limitation period then runs again only for the part still in dispute (CMR Art. 32(2)). |
| **Recovered amount** | Amount actually received from the carrier or its insurer for a claim. |
| **Recovery payment** | One payment received for a claim from the carrier or its insurer; the recovered amount is their sum (D-77). |
| **Recovery rate** | Recovered amount divided by claimed amount, in EUR; key indicator per carrier. |
| **Settled amount** | Amount agreed with the carrier to close a claim. |
| **Sender** | The party that contracts the carriage with the carrier and is named in the consignment note (CMR Art. 6(1)(b)); called sender in other modes and consignor in UN/EDIFACT (`CZ`). |
| **Special interest in delivery** | Amount declared in the consignment note against a surcharge, up to which additional proven loss can be claimed (CMR Art. 26). |
| **Subrogation** | An insurer who paid the claimant takes over the claim against the carrier; governed by national law, out of scope of Release 1. |
| **Taking over (of the goods)** | The moment the carrier takes charge of the goods at the place of taking over (CMR Art. 6(1)(d), 17(1)): the carrier's liability starts, and the shipment is checked on this date (BR-17). |
| **Tonne-kilometre (tkm)** | Unit of freight transport: one tonne of goods carried over one kilometre. |

### Application Roles

APEX application roles of application 200 (spec §7.1). Name and static identifier are identical; code checks the static identifier (`APEX_ACL.HAS_USER_ROLE`). Roles are exported with the application; user role assignments are not.

| Role | Description |
|------|-------------|
| **ADMINISTRATOR** | Functional administrator (not the APEX workspace administrator or a database role): maintains reference data (countries, holidays, rules, rates, templates), imports shipments, ingests the regulatory corpus and reviews the AI audit log [EXT]. Read-only access to claims; cannot change claim status. |
| **ANALYST** | Analyses claim KPIs: dashboards, regulatory search and natural-language questions translated to read-only SQL [EXT]. No access to individual claim records or reference data. |
| **CLAIMS_HANDLER** | Handles CMR claims: creates and edits parties, shipments and claims, imports shipments, writes claim letters and receives alerts for own claims. The only role that changes claim status (BR-02). Read-only access to reference data. |
| **COMPLIANCE_OFFICER** | Oversees compliance (CMR, GDPR, AI Act): read-only access to claims and reference data, regulatory search and dashboards; reviews the AI audit log and handles erasure requests [EXT]. Does not change claims. |

### Legal & Regulatory

| Term | Definition |
|------|------------|
| **CELEX** | Unique identifier of documents in EUR-Lex. |
| **CMR** | Convention on the Contract for the International Carriage of Goods by Road (Geneva, 1956). Applies to road carriage for reward between two countries, at least one of which is a contracting country. |
| **CMR Protocol (1978)** | Amendment to the CMR that expresses the liability limit in SDR instead of gold francs. |
| **DPA** | Data Processing Agreement required by GDPR Art. 28 between a controller and a processor (e.g., an LLM provider). |
| **ECB reference rates** | Daily euro exchange rates published by the European Central Bank (ECB): units of a currency per 1 EUR, every TARGET working day around 16:00 CET. |
| **Euro changeover** | Replacement of a national currency by the euro at a fixed conversion rate, e.g., Croatia (HRK, 2023-01-01, 7.53450 per EUR) and Bulgaria (BGN, 2026-01-01, 1.95583 per EUR). The old currency code stays valid only for earlier dates. |
| **ISO 3166 / ISO 4217 / ISO 8601** | International standards for country codes (alpha-2, e.g., `DE`), currency codes (e.g., `EUR`, with minor units) and date/time representation (`YYYY-MM-DD`). |
| **eFTI** | Electronic Freight Transport Information — Regulation (EU) 2020/1056. |
| **EU AI Act** | Regulation (EU) 2024/1689 on artificial intelligence. |
| **EU/EEA** | European Union / European Economic Area (EU plus Iceland, Liechtenstein and Norway); GDPR applies throughout. |
| **EUR-Lex** | Official online database of EU law. |
| **GoBD** | German principles for keeping books and records electronically: data must be complete, unchanged and every change traceable; retention by §147 AO and §257 HGB (accounting documents 8 years since 2025, books 10 years). |
| **GDPR** | General Data Protection Regulation — Regulation (EU) 2016/679. |
| **VIES** | VAT Information Exchange System of the European Commission; validates EU VAT numbers, which start with a two-letter prefix (`EL` for Greece, `XI` for Northern Ireland traders). |
| **Limitation period** | Time within which a legal action must be brought: one year, three for wilful misconduct (CMR Art. 32). |
| **Pseudonymisation** | Replacing names or identifiers with a pseudonym, keeping the link to the person in a separate, protected place; pseudonymised data is still personal data under the GDPR (Art. 4(5)). Anonymised data cannot be linked to a person any more. |
| **PII** | Personally Identifiable Information ("personal data" in GDPR terms). |
| **Reservation** | The consignee's notice to the carrier about loss, damage or delay, within the periods of CMR Art. 30. |
| **SDR** | Special Drawing Right: IMF unit of account used for the CMR liability limit (Art. 23). |
| **Suspension of limitation** | A written claim stops the limitation period until the carrier rejects it in writing (CMR Art. 32(2)). |
| **UNECE** | United Nations Economic Commission for Europe; publishes the official CMR text. |
| **Wilful misconduct** | Intentional or reckless wrongdoing; extends the limitation period to three years and removes liability limits (CMR Art. 29, 32). |
| **Written claim** | Formal written demand sent to the carrier; it suspends the limitation period (CMR Art. 32(2)). |

---

## Part B — Technical

### Oracle & Technology

| Term | Definition |
|------|------------|
| **ACL (network)** | Database rule that allows outbound connections only to approved hosts (`DBMS_NETWORK_ACL_ADMIN`). |
| **AES-256 / AES-NI** | Advanced Encryption Standard with a 256-bit key, the encryption algorithm of TDE; AES-NI are CPU instructions that make it fast. |
| **Allowlist** | List of the only values that are accepted; everything else is rejected. Safer than a list of forbidden values (denylist), which misses what nobody thought of; used for the file types of claim documents (BR-18). |
| **APEX** | Oracle Application Express: low-code framework for web applications that run inside the database. |
| **APEX Advisor** | APEX tool that checks an application for security, performance and quality issues. |
| **APEX Data Load** | APEX feature that loads CSV, Excel, JSON or XML files into tables with column mapping. |
| **`APEX_MAIL`** | APEX package that queues and sends emails through the configured SMTP server. |
| **Archived log** | Saved copy of a full online redo log ("a saved page of the database diary"); with archived logs a restored backup is brought forward to a later moment. Only in `ARCHIVELOG` mode. |
| **ARCHIVELOG mode** | Database mode in which every filled online redo log is saved as an **archived redo log** before it is reused; needed for online backups, point-in-time recovery and restore points (ADR-010). The opposite, `NOARCHIVELOG`, allows only cold backups. |
| **Artifact (deployment)** | ZIP file created by SQLcl `project` that contains one release and installs it on another database. |
| **Authorization scheme** | APEX rule that decides whether a user can see a page or component. |
| **Auto-login keystore (local)** | File `cwallet.sso` created from the keystore that opens the keys automatically when the database starts, but only on the computer where it was created. |
| **Auto-scaling** | Automatic adjustment of CPU and memory to the current load (e.g., in Autonomous Database). |
| **Autonomous transaction** | PL/SQL block that commits independently of the calling transaction; used for logging. |
| **Backup piece** | File written by RMAN that contains a backup or part of it. |
| **Block change tracking** | File in which Oracle records the changed blocks, so that an incremental backup reads only those blocks. |
| **CDB / PDB** | Container Database / Pluggable Database. `FREEPDB1` is the PDB that hosts this project. |
| **Change script** | A script, run once, that changes existing production data (e.g., retires a currency); it cites the authorized change request. Data scripts never overwrite data on their own (D-72). |
| **Changelog** | Liquibase file that lists database changes in order; each change is applied once and recorded. |
| **Changeset** | One database change inside a changelog (e.g., add a column); Liquibase applies it once per database. |
| **Checksum (SHA-256)** | Fingerprint calculated from a file's content; matching the published value proves a download is complete and unaltered. |
| **Chunk** | A segment of a source document stored with its embedding. |
| **Code list** | Reference table of the values a business column may take (e.g., claim statuses), with a validity period and referenced by a foreign key, so that a value can be retired while old records keep it (spec §1.3). |
| **Control file** | Small database file that acts as its table of contents: which data files and logs exist and which backups RMAN made. Saved automatically with each backup (`CONTROLFILE AUTOBACKUP`). |
| **Corpus** | The collection of source documents the search works on; here, the CMR and the EU acts listed in spec §2.2. |
| **Data file** | Operating-system file (`.DBF`) that stores the data of one tablespace. |
| **Data Guard** | Oracle feature that keeps a standby copy of the database up to date from the redo of the primary; not available in the Free edition (growth path, ADR-010 §8). |
| **Data Pump** | Oracle export/import utility (`expdp`/`impdp`, or the `DBMS_DATAPUMP` API) that writes objects and rows to a dump file and reads them back: a **logical** copy, used to move schemas (migration phase M.3); backups for recovery are made with RMAN. Dump encryption is not available in 26ai Free (`ORA-00439`). |
| **Database role** | Named set of privileges granted to users instead of granting privileges one by one. |
| **DBID** | Identity number of a database; needed to find its backups when the control file is lost. |
| **`DBMS_SCHEDULER`** | Oracle job scheduler used for background and recurring tasks. |
| **Definer's rights** | Default PL/SQL mode: code runs with its owner's privileges; privileges received through roles are not active there. |
| **Dump file** | File written by Data Pump with the definitions (and optionally the rows) of the exported objects. Before an import, a `SQL_FILE` job writes the DDL it would run without changing the database (preview). |
| **ELT** | Extract, Load, Transform: data is first loaded raw into staging tables and then validated and transformed inside the database before reaching the operational tables. |
| **Embedding** | Numeric vector representing the meaning of a text. |
| **Encrypted tablespace** | Tablespace whose data files are stored encrypted by TDE: decrypted when read into memory, so users and applications see normal data, while copied files or backups are unreadable without the keystore (ADR-011). |
| **Fast recovery area** | Disk location managed by Oracle for archived logs, backups and flashback logs (`DB_RECOVERY_FILE_DEST`). |
| **File signature (magic bytes)** | The first bytes of a file that identify its format, e.g. `%PDF-` for PDF; compared with the file extension to detect a file whose name lies about its content (BR-18). |
| **First schema (APEX workspace)** | The database schema a workspace is created with. APEX cannot remove or change it later; to use another one, the workspace is created again. |
| **Flashback (Database / PDB / Table)** | Oracle features that return a whole database, one PDB or one table to an earlier time without restoring a backup. |
| **HNSW** | Hierarchical Navigable Small World: in-memory graph vector index for fast approximate search; needs `VECTOR_MEMORY_SIZE` (ADR-001). |
| **Identity column** | Column whose value Oracle generates (`GENERATED ALWAYS AS IDENTITY`); used for surrogate primary keys. |
| **Incremental backup (level 0 / level 1)** | RMAN backups: level 0 copies all blocks (the base); level 1 copies only blocks changed since the previous backup. |
| **Integration schema** | Schema-only schema (`EMK_INT`) that receives external data, keeps it as received and passes it to the application only through its business APIs in `EMK_API` (ADR-007, ADR-008). |
| **Interval partitioning** | Range partitioning in which Oracle creates a new partition automatically for each interval (here: each month); old data is removed with `DROP PARTITION`. |
| **IVF** | Inverted File Flat: partition-based vector index stored on disk. |
| **Journal table** | Table `<TABLE>_JN` that keeps the previous version of each updated or deleted row, with operation, user and timestamp; filled by a trigger. |
| **Key rotation (rekey)** | Replacing a master encryption key with a new one; the old keys stay in the keystore so older backups remain readable. |
| **Keystore (wallet)** | Password-protected file (`ewallet.p12`) that holds the TDE master encryption keys, under `WALLET_ROOT`. "The safe of the keys": without it encrypted data cannot be read, also not from backups (ADR-011). |
| **Liquibase** | Database change-management tool, integrated in SQLcl. |
| **Load balancer** | Component that distributes requests across several server instances (e.g., several ORDS nodes). |
| **Mailpit** | Local email testing server: receives emails over SMTP and shows them in a web page without delivering them. |
| **Master data** | The code lists the administrator maintains in the application's Master Data menu (party roles, claim statuses and types, document types, allowed file types). A value is retired, never deleted or re-coded; the codes the program names cannot be retired (D-82). |
| **Master encryption key** | TDE key, one per PDB, that encrypts the tablespace keys; stored only in the keystore. |
| **Media type (MIME type)** | Standard name of a file format registered at IANA, e.g. `application/pdf`; the type a browser sends with an upload is chosen by the client and is not trusted. |
| **NL-to-SQL** | Translating a natural-language question into SQL (ADR-002). |
| **OAuth2 client credentials** | Flow in which a client application gets an access token with its own ID and secret; native in ORDS. |
| **ONNX** | Open Neural Network Exchange: open format for trained AI models. An **ONNX model** is a file that Oracle can load and run inside the database (here, the embedding model of ADR-004). |
| **Optimistic locking** | Protection against lost updates: a page saves only if the row still has the version it read (`row_version`); otherwise the user is told that another user changed it (D-43). |
| **ORDS** | Oracle REST Data Services: web listener that serves APEX and REST APIs. |
| **p50 / p95 (percentile)** | p50 (median): half of the requests are faster. p95: 95 of every 100 requests are faster; the rest form the "slow tail" that an average hides. |
| **Parsing schema (APEX)** | Database schema whose privileges an APEX application uses to run its SQL and PL/SQL (here `EMK_UI`, which owns nothing). |
| **Partitioning** | Splitting a large table into smaller parts (e.g., by date) that the database manages transparently. |
| **Party role** | Function a company plays in a shipment or claim (sender, consignee, carrier, forwarder, insurer, surveyor); a company can have several roles (`EMK_PARTY_ROLES`, BR-16). Aligned with UN/EDIFACT code list 3035. |
| **PL/SQL** | Oracle's procedural extension of SQL, used for business logic. |
| **Point-in-time recovery** | Recovery of a database or PDB up to a chosen moment (for example just before a wrong mass update); later changes are lost. |
| **Profile (password)** | Set of password and session rules assigned to an account (e.g., `ORA_CIS_PROFILE`: failed logins, expiry, reuse, complexity, inactivity lock). |
| **Prompt injection** | Attack in which text processed by an LLM contains instructions that try to change its behaviour. |
| **Proxy authentication** | One account connects and acts as another without its password (how ORDS uses APEX schemas). |
| **RAG** | Retrieval-Augmented Generation: grounding an LLM answer in retrieved documents. |
| **Recall@5** | Share of questions whose correct source appears in the top 5 results. |
| **Redo log** | Files in which the database writes every change before it is applied to the data files; online redo logs are reused in a cycle, archived redo logs are their saved copies. |
| **Restore / recover** | Restore copies data files back from a backup; recover applies archived logs to bring them forward to the latest or to a chosen moment. |
| **Restore point (guaranteed)** | Name for a point in time to which a database or PDB can be returned with flashback; a guaranteed one keeps the needed logs until it is dropped (used before each deployment, ADR-010). |
| **Retention policy (recovery window)** | RMAN rule that says how long backups are kept, e.g. "recovery window of 7 days" = any moment of the last 7 days can be restored; older backups become obsolete and are deleted. |
| **RMAN** | Recovery Manager: Oracle tool that makes backups (full and incremental, encrypted), checks them, deletes obsolete ones and restores and recovers the database; it records every backup in the control file ([backup runbook](operations/backup-runbook.md)). |
| **Row lock** | Lock on one row held until the end of the transaction (`SELECT … FOR UPDATE`); `NOWAIT` answers at once if the row is locked, `WAIT n` waits up to n seconds (D-73). |
| **Schema-only account** | Account with no password (`NO AUTHENTICATION`): nobody can log in to it directly; it owns objects and is reached only through proxy (`EMK_DATA`) or by `SYS` (`UT3`). |
| **Scalar SQL macro** | PL/SQL function whose text Oracle copies into the SQL statement before running it, so a view can reuse an expression without a call per row (`EMK_ROW_VERSION_PKG.format_row_version`). |
| **Seed and publish (APEX)** | Translation workflow: seed copies the texts of the primary application, the XLIFF file is translated and applied, and publish creates the translated application. |
| **SQL assertion** | Integrity rule declared once that the database enforces across several tables (`CREATE ASSERTION`, Oracle 26ai 23.26.1). Not used in Release 1: the export tools do not carry it yet (D-70). |
| **Select AI** | Oracle feature (`DBMS_CLOUD_AI`) that turns questions into SQL; not available in 26ai Free. |
| **Session state protection** | APEX feature that prevents users from tampering with page item values in URLs. |
| **SGA / PGA** | System Global Area (shared memory) / Program Global Area (per-session memory). |
| **SMTP** | Simple Mail Transfer Protocol: standard protocol for sending email. |
| **Soft delete** | Marking a record as deleted (`deleted_yn = 'Y'`) instead of removing it, so history is kept. |
| **SQLcl** | Oracle's command-line tool for SQL, scripts, Liquibase and projects. |
| **SQLcl project** | SQLcl command set (`project init`, `export`, `stage`, `release`, `deploy`) that versions database and APEX changes with Liquibase (ADR-005). |
| **Staging / landing table** | Table where inbound data is stored before it reaches the operational tables; here a generic landing table `EMK_INBOUND_RECORDS` keeps each record as received (JSON) with its processing status. |
| **SYSKM** | Oracle administrative privilege for key management only (keystore and master keys), so that key handling can be separated from general database administration. |
| **Tablespace** | Logical storage area of the database, backed by one or more data files on disk. |
| **Tablespace key** | TDE key that encrypts the blocks of one tablespace; stored in the data file header, encrypted by the master key. |
| **TDE** | Transparent Data Encryption: encrypts data when it is written to disk and decrypts it when read, without changes to SQL or applications; keys are kept in a keystore (ADR-011). |
| **Token** | Unit of text (a word or part of a word) that a language model processes; models accept a maximum number of tokens per input. |
| **Unified Auditing** | The only database auditing in 23ai/26ai: audit policies (`CREATE AUDIT POLICY`) write to `UNIFIED_AUDIT_TRAIL`, managed with `DBMS_AUDIT_MGMT`. |
| **UTC** | Coordinated Universal Time; used to store technical timestamps. |
| **utPLSQL** | Unit-testing framework for PL/SQL. |
| **Unit test suite (utPLSQL)** | Package `TEST_EMK_<NAME>` whose procedures are tests, marked with annotations (`--%suite`, `--%test`, `--%throws`); it lives in the schema of the objects it tests, is never installed in PROD, and every change of a test is rolled back by utPLSQL. |
| **Validate (RMAN)** | RMAN check that reads backups and confirms they are complete and undamaged, without restoring anything (`RESTORE DATABASE VALIDATE`). |
| **`VECTOR`** | Oracle data type that stores embeddings. |
| **WALLET_ROOT** | Initialization parameter (26ai) that sets the folder of the keystore; the TDE keystore is in its subfolder `tde`. |
| **Web Credentials** | APEX objects that store API keys securely, outside the code. |
| **Workspace (APEX)** | Isolated development area in APEX, linked to one or more database schemas. |
| **Write skew** | Two transactions each check a rule on data the other is changing, both pass, and together they break the rule (e.g., removing a role while a shipment that needs it is saved); prevented by locking what both read (D-73). |
| **XLIFF** | XML Localization Interchange File Format: standard file used to translate application texts. |

### Methodology & Process

| Term | Definition |
|------|------------|
| **ADR** | Architecture Decision Record: a short document that records one design decision with its context, options and consequences (`docs/adr/`). |
| **AI-native SDLC** | Software development life cycle in which an AI assistant takes part in every stage, and each stage commits an artifact the next one reads: intent → spec → plan → code → review. |
| **Apdex** | Application Performance Index: open standard that rates response times against a threshold T as satisfied (≤ T), tolerating (≤ 4T) or frustrated (> 4T); score from 0 to 1. |
| **BIA** | Business Impact Analysis: assessment of what a disruption of a business process costs over time; source of the MTPD, RTO and RPO (BSI-Standard 200-4, ISO 22301). |
| **Conventional Commits** | Commit message convention with a type prefix (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`). |
| **Definition of Done** | The conditions that must hold for a milestone or release to count as finished. |
| **Expand / contract** | Schema change in two releases: first add (expand), later remove what is no longer used (contract), so that the previous code still works and can be redeployed. |
| **Extension [EXT]** | Feature planned for Release 1 but outside the MVP (milestones X1–X4); the label [EXT] marks it in the documents. |
| **Feature flag** | Switch that turns a feature on or off without a deployment; here an APEX Build Option or the role `PILOT_USER`. |
| **Idempotent** | A script that can run several times with the same result and no errors or duplicates. |
| **Intent** | Stage 1 artifact (`intent.md`): what is wanted, why, and under which constraints. |
| **Milestone** | A releasable increment of work (M0–M5 for the MVP, X1–X4 for extensions). |
| **MTPD** | Maximum Tolerable Period of Disruption: longest outage the business can accept; the RTO must be shorter. |
| **MVP** | Minimum Viable Product: the smallest complete version that delivers the core value and can be demonstrated. |
| **Pilot user** | User who receives a new feature first (role `PILOT_USER`), before all users. |
| **Plan** | Stage 3 artifact (`plan.md`): the files that change, the order of the work and the tests that prove it. |
| **Pull Request (PR)** | A proposal to merge a branch into `main`, reviewed before merging. |
| **Release** | A published version of the system. Release 1 = MVP + extensions. |
| **Restore drill** | Planned test in which a backup is actually restored, timed and recorded, to prove the RPO and RTO ([recovery runbook](operations/recovery-runbook.md)). |
| **RPO** | Recovery Point Objective: the most data, measured in time, that may be lost in a failure (here ≤ 1 hour). |
| **RTO** | Recovery Time Objective: the longest time until users can work again after a failure (here ≤ 4 hours). |
| **Runbook** | Step-by-step operating procedure for a task or incident (`docs/operations/`). |
| **SDLC** | Software Development Life Cycle. This project uses six stages: Plan, Design, Build, Test, Deploy, Maintain (`docs/sdlc.md`). |
| **Traceability table** | Table that links each business rule and success criterion to the tests that prove it. |
| **Spec** | Stage 2 artifact (`spec.md`): requirements and design that answer the intent's open questions. |

### Document Identifiers

Codes used in the documents to refer to items and to trace them from problem to test.

| Code | Meaning | Defined in | Example |
|------|---------|------------|---------|
| **P1–P3** | Problem the project solves | intent §1 | P2 — strict legal deadlines |
| **Q1–Q5** | Open question of the intent, answered by an ADR or the spec | intent §7 | Q1 — deployment method → ADR-005 |
| **F-nn** | Feature (functional block) of the catalogue, with its milestone | spec §2 | F-01 — claims management |
| **FR-nn** | Functional requirement: one thing the system must do | spec §2.1–2.6 | FR-01 — manage parties and contact persons |
| **BR-nn** | Business rule enforced by the system, with its source and test | spec §2.7 | BR-07 — the start day of a period is not counted |
| **`RES_*` / `LIM_*`** | CMR deadline rule: reservation (Art. 30) / limitation (Art. 32) | spec §5 | `RES_DELAY` — 21 days for delay |
| **SC-xxx-nn** | Success criterion, grouped by area: `DEP` deployment, `SEC` security, `QA` quality and tests, `AI` AI quality, `DOC` documentation | spec §8 | SC-SEC-02 — no secrets in the repository |
| **R-nn** | Risk and its mitigation | spec §11 | R-01 — memory limit of 2 GB |
| **ADR-nnn** | Architecture Decision Record | `docs/adr/` | ADR-005 — hybrid deployment |
| **M0–M5 / X1–X4** | MVP milestone / extension milestone | spec §9 | M0 — foundations |
| **M.1–M.5** | Migration phase of step M of the M1 plan (move to the separated schemas); not a milestone: M.3 is a phase inside milestone M1, M3 is the legal-search milestone | M1 plan §4.1 | M.1 — safety and operations |
| **T-Mn-nn** | Test of a milestone plan | `docs/plans/` | T-M0-04 — clean rebuild |
| **PR #n** | Pull request number on GitHub | GitHub | PR #5 |

Chain of traceability: **P** (problem) → **F / FR** (what is built) → **BR** (rules it follows) → **SC** (how success is measured) → **T** (test that proves it).
