# ADR-004: Embedding Model for Multilingual Legal Search

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-10-04 |
| **Deciders** | Solution Architect (project owner) |
| **Related** | [spec.md](../spec.md) §2.2, §6.1, §12 · [intent.md](../intent.md) §7 (Q2) · [ADR-001](ADR-001-hnsw-vector-index.md) · SC-AI-01, SC-AI-03, SC-AI-05 · R-01, R-07 |

---

## Context

Feature F-07 (multilingual legal search, milestone M3) converts legal text and user questions into vectors **inside the database** (spec principle 2). The model must:

| Requirement | Reason |
|-------------|--------|
| Cover **EN, DE, FR, ES** | Cross-lingual retrieval (SC-AI-03) |
| Load as **ONNX** with `DBMS_VECTOR.LOAD_ONNX_MODEL` | In-database embeddings, no external service |
| Fit the **2 GB memory** budget of the Free edition | Shared with APEX and the vector pool (R-01) |
| Accept inputs long enough for a **legal article** | Fewer, more meaningful chunks |
| Have a licence that **permits this use** | R-07 |

ONNX model size limit: 1 GB when loaded from a file; up to 2 GB as a BLOB in Oracle AI Database 26ai.

---

## Options Considered

| | **A. multilingual-e5-small** | **B. granite-embedding-107m-multilingual** | **C. multilingual-e5-base** |
|---|---|---|---|
| Publisher | Microsoft (intfloat) | IBM | Microsoft (intfloat) |
| Licence | MIT | Apache 2.0 | MIT |
| Languages | ~100, including EN/DE/FR/ES | 12, including EN/DE/FR/ES | ~100, including EN/DE/FR/ES |
| Parameters | 118 M | 107 M | 278 M |
| Dimensions | 384 | 384 | 768 |
| Max input | 512 tokens | 512 tokens | 512 tokens |
| Oracle availability | **Pre-built ONNX** published by Oracle (`multilingual_e5_small.onnx`, ~77 MB) — load directly | On Oracle's list of supported models; must be converted with the OML4Py client (Python) | On Oracle's list; must be converted with the OML4Py client (Python) |
| Fit for Free edition | Very good | Good | Larger model and twice the vector size |

**Excluded:** `all-MiniLM-L12-v2` (English only); `paraphrase-multilingual-MiniLM-L12-v2` (128-token input limit and not on Oracle's list of supported models).

---

## Decision

Adopt **Option A: `multilingual-e5-small`**, using the pre-built ONNX model published by Oracle.

### Why Option A Was Selected

| Criterion | A. multilingual-e5-small | B. granite-107m-multilingual | C. multilingual-e5-base |
|-----------|:-:|:-:|:-:|
| Loads without a Python conversion step | ✔ | ✘ | ✘ |
| Covers EN, DE, FR, ES | ✔ | ✔ | ✔ |
| Smallest memory footprint for the Free edition | ✔ | ✔ | ✘ |
| Matches the ADR-001 sizing (384 dimensions) | ✔ | ✔ | ✘ (768) |
| Language coverage beyond the four target languages | ✔ (~100) | Limited (12) | ✔ (~100) |
| Permissive licence | ✔ MIT | ✔ Apache 2.0 | ✔ MIT |

- **Lowest setup effort and risk.** A is the only option that Oracle publishes as a ready-to-load ONNX model. B and C need the OML4Py client (Python) to convert them, which adds tooling, time and failure points for a single-developer project.
- **Fits the Free edition.** A and B are the smallest models; A's ONNX file is about 77 MB, leaving the 2 GB memory budget for APEX and the vector pool (R-01).
- **Consistent with ADR-001.** 384-dimension vectors keep the HNSW index at about 6 MB for 3,000 chunks.
- **Broader language coverage than B.** Claims documents may arrive in languages beyond the four search languages (e.g., Polish or Czech), which A covers and B does not.
- **Measured, not assumed.** A smaller model may retrieve less accurately; the golden set (SC-AI-01, SC-AI-03) verifies quality, and C remains the fallback.

### Implementation Rules (M3)

| Rule | Detail |
|------|--------|
| Model name in the database | `MULTILINGUAL_E5_SMALL` in schema `EMK_APP` |
| Model file | Downloaded to `data/models/` (not committed); download URL recorded in `docs/setup.md` when M3 starts |
| Input prefixes | The E5 models expect `"passage: "` before each indexed chunk and `"query: "` before each question; applied by `EMK_SEARCH_API` |
| Chunk size | At most 512 tokens per chunk; long articles are split by paragraph |
| Vector column | `VECTOR(384, FLOAT32)` |
| Verification | Memory measured after loading the model (R-01); quality measured with the golden set (SC-AI-01, SC-AI-03) |

---

## Consequences

**Positive**
- Simple, Oracle-supported setup with no extra tooling.
- Small memory footprint within the Free edition budget.
- Same embedding model for documents and questions in all four languages.

**Negative / trade-offs**
- Smaller models retrieve less accurately than larger ones; this is measured, not assumed.
- Callers must add the `query:` / `passage:` prefixes consistently.

**Revisit when**
- Recall@5 stays below the targets of SC-AI-01 or SC-AI-03. Option C is the first fallback (requires OML4Py conversion and re-embedding the corpus).
