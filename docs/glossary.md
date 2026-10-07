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
| **Consignee** | The party entitled to receive the goods at destination. |
| **Consignment note (CMR note)** | The transport document that confirms the contract of carriage under the CMR. |
| **Cross-trade** | Transport between two countries by a haulier registered in a third country. |
| **Gross weight short** | Gross weight of the goods lost or missing; basis of the CMR liability limit. |
| **Joint check** | Inspection of the goods carried out together by the consignee and the carrier (CMR Art. 30(2)). |
| **Recovered amount** | Amount actually received from the carrier or its insurer for a claim. |
| **Recovery rate** | Recovered amount divided by claimed amount, in EUR; key indicator per carrier. |
| **Settled amount** | Amount agreed with the carrier to close a claim. |
| **Shipper** | The party that contracts the carriage (also called sender). |
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
| **GDPR** | General Data Protection Regulation — Regulation (EU) 2016/679. |
| **VIES** | VAT Information Exchange System of the European Commission; validates EU VAT numbers, which start with a two-letter prefix (`EL` for Greece, `XI` for Northern Ireland traders). |
| **Limitation period** | Time within which a legal action must be brought: one year, three for wilful misconduct (CMR Art. 32). |
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
| **APEX** | Oracle Application Express: low-code framework for web applications that run inside the database. |
| **APEX Advisor** | APEX tool that checks an application for security, performance and quality issues. |
| **APEX Data Load** | APEX feature that loads CSV, Excel, JSON or XML files into tables with column mapping. |
| **`APEX_MAIL`** | APEX package that queues and sends emails through the configured SMTP server. |
| **Artifact (deployment)** | ZIP file created by SQLcl `project` that contains one release and installs it on another database. |
| **Authorization scheme** | APEX rule that decides whether a user can see a page or component. |
| **Autonomous transaction** | PL/SQL block that commits independently of the calling transaction; used for logging. |
| **Auto-scaling** | Automatic adjustment of CPU and memory to the current load (e.g., in Autonomous Database). |
| **CDB / PDB** | Container Database / Pluggable Database. `FREEPDB1` is the PDB that hosts this project. |
| **Changelog** | Liquibase file that lists database changes in order; each change is applied once and recorded. |
| **Changeset** | One database change inside a changelog (e.g., add a column); Liquibase applies it once per database. |
| **Checksum (SHA-256)** | Fingerprint calculated from a file's content; matching the published value proves a download is complete and unaltered. |
| **Chunk** | A segment of a source document stored with its embedding. |
| **Corpus** | The collection of source documents the search works on; here, the CMR and the EU acts listed in spec §2.2. |
| **Data Pump** | Oracle export/import utility (`expdp`/`impdp`) used for backups of schemas and data. |
| **Database role** | Named set of privileges granted to users instead of granting privileges one by one. |
| **Definer's rights** | Default PL/SQL mode: code runs with its owner's privileges; privileges received through roles are not active there. |
| **`DBMS_SCHEDULER`** | Oracle job scheduler used for background and recurring tasks. |
| **ELT** | Extract, Load, Transform: data is first loaded raw into staging tables and then validated and transformed inside the database before reaching the operational tables. |
| **Embedding** | Numeric vector representing the meaning of a text. |
| **HNSW** | Hierarchical Navigable Small World: in-memory graph vector index for fast approximate search; needs `VECTOR_MEMORY_SIZE` (ADR-001). |
| **Identity column** | Column whose value Oracle generates (`GENERATED ALWAYS AS IDENTITY`); used for surrogate primary keys. |
| **Integration schema** | Schema-only schema (`EMK_INT`) that receives external data, keeps it as received and passes it to the application only through its business APIs (ADR-007). |
| **Interval partitioning** | Range partitioning in which Oracle creates a new partition automatically for each interval (here: each month); old data is removed with `DROP PARTITION`. |
| **IVF** | Inverted File Flat: partition-based vector index stored on disk. |
| **Journal table** | Table `<TABLE>_JN` that keeps the previous version of each updated or deleted row, with operation, user and timestamp; filled by a trigger. |
| **Liquibase** | Database change-management tool, integrated in SQLcl. |
| **Load balancer** | Component that distributes requests across several server instances (e.g., several ORDS nodes). |
| **Mailpit** | Local email testing server: receives emails over SMTP and shows them in a web page without delivering them. |
| **NL-to-SQL** | Translating a natural-language question into SQL (ADR-002). |
| **OAuth2 client credentials** | Flow in which a client application gets an access token with its own ID and secret; native in ORDS. |
| **ONNX** | Open Neural Network Exchange: open format for trained AI models. An **ONNX model** is a file that Oracle can load and run inside the database (here, the embedding model of ADR-004). |
| **ORDS** | Oracle REST Data Services: web listener that serves APEX and REST APIs. |
| **p95 latency** | Response time that 95% of requests do not exceed. |
| **Partitioning** | Splitting a large table into smaller parts (e.g., by date) that the database manages transparently. |
| **Party role** | Function a company plays in a shipment or claim (shipper, consignee, carrier, forwarder, insurer, surveyor); a company can have several roles (`EMK_PARTY_ROLES`, BR-16). Aligned with UN/EDIFACT code list 3035. |
| **PL/SQL** | Oracle's procedural extension of SQL, used for business logic. |
| **Profile (password)** | Set of password and session rules assigned to an account (e.g., `ORA_CIS_PROFILE`: failed logins, expiry, reuse, complexity, inactivity lock). |
| **Prompt injection** | Attack in which text processed by an LLM contains instructions that try to change its behaviour. |
| **Proxy authentication** | One account connects and acts as another without its password (how ORDS uses APEX schemas). |
| **RAG** | Retrieval-Augmented Generation: grounding an LLM answer in retrieved documents. |
| **Recall@5** | Share of questions whose correct source appears in the top 5 results. |
| **Schema-only account** | Account with no password (`NO AUTHENTICATION`): nobody can log in to it directly; it owns objects and is reached only through proxy (`EMK_APP`) or by `SYS` (`UT3`). |
| **Select AI** | Oracle feature (`DBMS_CLOUD_AI`) that turns questions into SQL; not available in 26ai Free. |
| **Seed and publish (APEX)** | Translation workflow: seed copies the texts of the primary application, the XLIFF file is translated and applied, and publish creates the translated application. |
| **Session state protection** | APEX feature that prevents users from tampering with page item values in URLs. |
| **SGA / PGA** | System Global Area (shared memory) / Program Global Area (per-session memory). |
| **SMTP** | Simple Mail Transfer Protocol: standard protocol for sending email. |
| **Soft delete** | Marking a record as deleted (`deleted_yn = 'Y'`) instead of removing it, so history is kept. |
| **SQLcl** | Oracle's command-line tool for SQL, scripts, Liquibase and projects. |
| **SQLcl project** | SQLcl command set (`project init`, `export`, `stage`, `release`, `deploy`) that versions database and APEX changes with Liquibase (ADR-005). |
| **Staging / landing table** | Table where inbound data is stored before it reaches the operational tables; here a generic landing table `EMK_INBOUND_RECORDS` keeps each record as received (JSON) with its processing status. |
| **Tablespace** | Logical storage area of the database, backed by one or more data files on disk. |
| **Token** | Unit of text (a word or part of a word) that a language model processes; models accept a maximum number of tokens per input. |
| **UTC** | Coordinated Universal Time; used to store technical timestamps. |
| **XLIFF** | XML Localization Interchange File Format: standard file used to translate application texts. |
| **utPLSQL** | Unit-testing framework for PL/SQL. |
| **`VECTOR`** | Oracle data type that stores embeddings. |
| **Web Credentials** | APEX objects that store API keys securely, outside the code. |
| **Workspace (APEX)** | Isolated development area in APEX, linked to one or more database schemas. |

### Methodology & Process

| Term | Definition |
|------|------------|
| **ADR** | Architecture Decision Record: a short document that records one design decision with its context, options and consequences (`docs/adr/`). |
| **AI-native SDLC** | Software development life cycle in which an AI assistant takes part in every stage, and each stage commits an artifact the next one reads: intent → spec → plan → code → review. |
| **Conventional Commits** | Commit message convention with a type prefix (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`). |
| **Definition of Done** | The conditions that must hold for a milestone or release to count as finished. |
| **Extension [EXT]** | Feature planned for Release 1 but outside the MVP (milestones X1–X4); the label [EXT] marks it in the documents. |
| **Idempotent** | A script that can run several times with the same result and no errors or duplicates. |
| **Intent** | Stage 1 artifact (`intent.md`): what is wanted, why, and under which constraints. |
| **Milestone** | A releasable increment of work (M0–M5 for the MVP, X1–X4 for extensions). |
| **MVP** | Minimum Viable Product: the smallest complete version that delivers the core value and can be demonstrated. |
| **Plan** | Stage 3 artifact (`plan.md`): the files that change, the order of the work and the tests that prove it. |
| **Pull Request (PR)** | A proposal to merge a branch into `main`, reviewed before merging. |
| **Release** | A published version of the system. Release 1 = MVP + extensions. |
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
| **T-Mn-nn** | Test of a milestone plan | `docs/plans/` | T-M0-04 — clean rebuild |
| **PR #n** | Pull request number on GitHub | GitHub | PR #5 |

Chain of traceability: **P** (problem) → **F / FR** (what is built) → **BR** (rules it follows) → **SC** (how success is measured) → **T** (test that proves it).
