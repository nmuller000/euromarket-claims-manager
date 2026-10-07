# Architecture Decision Records

Architecture Decision Records (ADRs) document the key design decisions of the project: the context, the options considered, the decision and its consequences (success criterion SC-DOC-02).

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](ADR-001-hnsw-vector-index.md) | HNSW in-memory vector index with a 128 MB vector pool | Accepted | 2026-09-27 |
| [ADR-002](ADR-002-nl-to-sql-via-ai-gateway.md) | NL-to-SQL via the PL/SQL AI gateway instead of native Select AI | Accepted | 2026-09-27 |
| [ADR-004](ADR-004-embedding-model.md) | Embedding model: multilingual-e5-small (Oracle pre-built ONNX) | Accepted | 2026-10-04 |
| [ADR-005](ADR-005-deployment-and-database-setup.md) | Deployment method (hybrid: admin scripts + SQLcl project) and EMK_ database setup | Accepted (developer-account privileges amended by ADR-007) | 2026-10-04 |
| [ADR-007](ADR-007-integration-schema-and-account-hardening.md) | Integration schema `EMK_INT`, generic landing with versioned source views, account hardening | Accepted | 2026-10-07 |

## Conventions

- File name: `ADR-NNN-short-title.md`.
- Status values: `Proposed`, `Accepted`, `Superseded by ADR-NNN`, `Deprecated`.
- Accepted ADRs are not edited. A changed decision gets a new ADR that supersedes the old one.
