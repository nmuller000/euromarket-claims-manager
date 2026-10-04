# ADR-001: HNSW In-Memory Vector Index with a 128 MB Vector Pool

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-09-27 |
| **Deciders** | Solution Architect (project owner) |
| **Related** | [spec.md](../spec.md) §2.2, §6.1 · [intent.md](../intent.md) §4 · SC-AI-05, SC-DEP-01, SC-DEP-03 |

---

## Context

The semantic search capability (spec §2.2) retrieves CMR and EU regulation chunks by vector similarity. Success criterion **SC-AI-05** requires a top-k retrieval p95 latency below **500 ms** on the reference local environment.

The reference environment is **Oracle AI Database 26ai Free 23.26.1** on Windows, whose resource limits are 2 CPU threads, 2 GB of RAM (SGA + PGA) and 12 GB of user data.

The following values were measured in `CDB$ROOT` on 2026-09-27:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `memory_target` | 0 | Automatic Memory Management not used |
| `sga_target` / `sga_max_size` | 1536M | Automatic Shared Memory Management, fixed SGA size |
| `pga_aggregate_target` | 512M | SGA + PGA = 2,048 MB, the full Free edition budget |
| `vector_memory_size` | 0 | No vector pool, so HNSW indexes cannot be created |

**Corpus size estimate** (to be confirmed once the embedding model is selected): 6 legal instruments (the CMR Convention and 5 EU acts, see spec §2.2), about 2,000–3,000 chunks, 384-dimension `FLOAT32` embeddings.

---

## Options Considered

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. IVF index** | Inverted File Flat, a partition-based index stored on disk | No configuration change or restart | Slower than HNSW; accuracy depends on partition tuning |
| **B. HNSW index + vector pool** | Hierarchical Navigable Small World, an in-memory graph | Fastest and most accurate approximate search; the usual choice for RAG workloads | Requires a vector pool carved out of the SGA and a one-time instance restart |
| **C. No index (exact search)** | Full scan with `VECTOR_DISTANCE` | Exact results, no memory cost | Latency grows linearly with the corpus |

---

## Decision

Adopt **Option B**: **HNSW** in-memory vector indexes with **`VECTOR_MEMORY_SIZE = 128M`**.

### Sizing

The rule of thumb for HNSW memory is ≈ 1.3 × vectors × dimensions × bytes per dimension:

| Scenario | Estimate |
|----------|----------|
| 3,000 chunks × 384 dims × 4 bytes × 1.3 | ≈ 6 MB |
| 3,000 chunks × 1,024 dims × 4 bytes × 1.3 (larger model) | ≈ 16 MB |

128 MB leaves ample headroom while keeping most of the SGA for the buffer cache and APEX.

### Implementation

- **Script:** [`scripts/admin/01_vector_memory.sql`](../../scripts/admin/01_vector_memory.sql)
  - Idempotent: it only verifies if the value is already active (SC-DEP-03).
  - Backs up the SPFILE as a timestamped PFILE before changing anything.
  - Sets the value with `SCOPE = SPFILE`, restarts `OracleServiceFREE`, and waits for the listener.
  - Ensures `FREEPDB1` is open and saves its state.
- **Applied:** 2026-09-27. Result `OK: VECTOR_MEMORY_SIZE = 128M is active`.

### Rollback

```sql
-- As SYS in CDB$ROOT, then restart OracleServiceFREE
ALTER SYSTEM SET vector_memory_size = 0 SCOPE = SPFILE;
```

---

## Consequences

**Positive**
- Low-latency approximate search supports SC-AI-05 despite the 2-CPU limit.
- There is headroom for larger embedding models or corpus growth.
- The configuration is reproducible as code (SC-DEP-01).

**Negative / trade-offs**
- The vector pool is carved out of the fixed 1,536 MB SGA. Other SGA components shrink, mainly the buffer cache (estimated ~592 MB → ~464 MB).
- The change required a one-time instance restart (1–2 minutes of downtime in the local environment).
- HNSW is an in-memory structure. Its behaviour after instance restarts and under DML must be validated when the index is implemented.

**Revisit when**
- The embedding model or corpus changes significantly, or
- `v$vector_memory_pool` usage exceeds ~70% of the pool.

IVF (Option A) remains the documented fallback.
