# Architecture Decision Records

Architecture Decision Records (ADRs) document the key design decisions of the project: the context, the options considered, the decision and its consequences (success criterion SC-DOC-02).

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](ADR-001-hnsw-vector-index.md) | HNSW in-memory vector index with a 128 MB vector pool | Accepted | 2026-09-27 |
| [ADR-002](ADR-002-nl-to-sql-via-ai-gateway.md) | NL-to-SQL via the PL/SQL AI gateway instead of native Select AI | Accepted | 2026-09-27 |
| [ADR-004](ADR-004-embedding-model.md) | Embedding model: multilingual-e5-small (Oracle pre-built ONNX) | Accepted (schema of the model open since ADR-008; decided before M3) | 2026-10-04 |
| [ADR-005](ADR-005-deployment-and-database-setup.md) | Deployment method (hybrid: admin scripts + SQLcl project) and EMK_ database setup | Accepted (developer-account privileges amended by ADR-007; single schema `EMK_APP` superseded by ADR-008) | 2026-10-04 |
| [ADR-007](ADR-007-integration-schema-and-account-hardening.md) | Integration schema `EMK_INT`, generic landing with versioned source views, account hardening | Accepted (`EMK_APP` references and private synonyms superseded by ADR-008; `EMK_INT_DATA` replaced by `EMK_INT_TS`) | 2026-10-07 |
| [ADR-008](ADR-008-schema-separation.md) | Schema separation: `EMK_DATA`, `EMK_API`, `EMK_UI`, `EMK_INT`; deployment account `EMK_DEPLOY` | Accepted | 2026-10-10 |
| [ADR-009](ADR-009-environments.md) | Environments (DTAP): one PDB per environment — DEV `FREEPDB1`, TEST `EMKTEST`, ACCEPTANCE `EMKACC`, PROD defined; only `EMK_DEPLOY` changes shared environments | Accepted (amended: acceptance environment; MVP in DEV only, TEST at M5 if time allows) | 2026-10-10 |
| [ADR-010](ADR-010-operations-and-release-strategy.md) | Operational baseline and release strategy: `ARCHIVELOG`, RMAN and recovery runbook with business-based targets, restore points and rollback matrix, Unified Auditing with pseudonymised archive, HTTPS, performance targets, edition constraints as growth path | Accepted (logical export cannot be encrypted in Free: open point) | 2026-10-11 |
| [ADR-011](ADR-011-tablespace-encryption.md) | Encryption at rest, key management and encrypted backups: TDE tablespace encryption (AES-256), local auto-login keystore, encrypted RMAN backups and Data Pump exports; keys never kept with the data; Advanced Security licence in EE as growth-path cost | Accepted (Data Pump export encryption not enabled in Free, `ORA-00439`) | 2026-10-12 |

## Conventions

- File name: `ADR-NNN-short-title.md`.
- Status values: `Proposed`, `Accepted`, `Superseded by ADR-NNN`, `Deprecated`.
- Accepted ADRs are not edited. A changed decision gets a new ADR that supersedes the old one.
