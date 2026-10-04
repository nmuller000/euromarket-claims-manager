# ADR-002: NL-to-SQL via the PL/SQL AI Gateway Instead of Native Select AI

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-09-27 |
| **Deciders** | Solution Architect (project owner) |
| **Related** | [spec.md](../spec.md) §2.4, §6.3 · [intent.md](../intent.md) §5 · SC-SEC-01, SC-SEC-05, SC-AI-04 |

---

## Context

The NL-to-SQL capability (spec §2.4) lets logistics analysts query claim data in natural language. The original design used **Oracle Select AI** (`DBMS_CLOUD_AI` profiles and `SELECT AI`).

A check of the reference environment (Oracle AI Database 26ai Free 23.26.1) on 2026-09-27 returned:

| Package | Status |
|---------|--------|
| `DBMS_VECTOR` | Installed, VALID, `EXECUTE` granted to `PUBLIC` |
| `DBMS_VECTOR_CHAIN` (owner `CTXSYS`) | Installed, VALID, `EXECUTE` granted to `PUBLIC` |
| `DBMS_CLOUD` | **Not installed** |
| `DBMS_CLOUD_AI` | **Not installed** |

Native Select AI is therefore not available.

---

## Options Considered

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A. Install `DBMS_CLOUD` manually** | Oracle documents a manual installation for non-Autonomous databases | Could enable native Select AI | Select AI support on a local 26ai Free instance is not confirmed. Installation requires SYS-level wallet and network ACL setup, with uncertain outcome |
| **B. NL-to-SQL through the AI gateway** | `EMK_AI_GATEWAY_PKG` sends the question and governed view metadata to the LLM, then validates and executes the generated SQL | Works on the reference environment. Keeps a single AI egress point (SC-SEC-01). Full control over validation and logging. Provider-agnostic | More code to build and test. Accuracy depends on prompt design |
| **C. Autonomous Database (OCI Always Free)** | Select AI is included | Native feature | Moves the project off the local reference environment. Out of Release 1 scope (local environment only) |

---

## Decision

Adopt **Option B** for Release 1 (extension X2). Option C is a candidate for a later release; native Select AI is out of scope (intent §5).

### Security design (defence in depth)

| Layer | Control |
|-------|---------|
| 1. Privileges (**primary**) | Generated SQL runs under a dedicated low-privilege schema with `SELECT`-only grants on analytical views |
| 2. Metadata exposure | Only allow-listed analytical views are described to the LLM. It never sees base tables or personal data columns |
| 3. Validation | Single `SELECT` statement; allow-listed objects only; no DML, DDL or PL/SQL; enforced row limit |
| 4. Egress | All LLM calls go through `EMK_AI_GATEWAY_PKG` via `APEX_WEB_SERVICE`, using Web Credentials and the ACL allow-list |
| 5. Audit | Prompt, generated SQL, validation outcome and execution status are written to `EMK_AI_AUDIT_LOG` |

The validator is a secondary control. If it is bypassed, layer 1 still prevents any write or access to base tables (SC-SEC-05).

### Functional parity with Select AI

| Select AI action | Gateway mode |
|------------------|--------------|
| `showsql` | Show SQL (transparency) |
| `runsql` | Run SQL (execution) |
| `explainsql` | Explain SQL (education) |

---

## Consequences

**Positive**
- The capability is fully deliverable on the local reference environment.
- NL-to-SQL shares the single, auditable AI egress point with the other AI features.
- The LLM provider can be changed through configuration.
- The layered controls are explicit and testable (negative test cases for SC-SEC-05).

**Negative / trade-offs**
- The generation, validation and execution logic must be built and tested in-house.
- The accuracy target (SC-AI-04: ≥ 85% on 30 benchmark questions) depends on prompt engineering and view design.
- Native Select AI is not demonstrated in Release 1.

**Revisit when**
- `DBMS_CLOUD_AI` becomes available in the Free edition, or
- a later release targets Autonomous Database.
