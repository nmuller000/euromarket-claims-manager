# Intent — EuroMarket AI-Driven Compliance & Claims Manager

| | |
|---|---|
| **SDLC stage** | 1 — Plan ([docs/sdlc.md](sdlc.md)) |
| **Status** | Accepted v1.1 (2026-10-04) |
| **Owner** | Natalia Müller ([@nmuller000](https://github.com/nmuller000)) |
| **Date** | 2026-10-03 |
| **Next artifact** | [docs/spec.md](spec.md) (Stage 2 — Design) |

Terms are defined in the [glossary](glossary.md).

---

## 1. Problem

Companies that ship goods by road across Europe lose money and time on **freight claims** (loss, damage or delay of goods under the CMR Convention):

- **P1 — Language barrier.** Parties to a claim are often based in different countries. Consignment notes, damage reports and correspondence arrive in many languages.
- **P2 — Strict legal deadlines and compliance.** CMR reservation and limitation periods are short; a missed deadline can mean a lost claim. Claims also contain personal data protected by the GDPR.
- **P3 — No visibility of claim data.** Claim information is often scattered across emails and spreadsheets. There are no indicators by carrier, route or country, and new questions depend on IT reports or manual work in Excel.

### Evidence

| Fact | Source |
|------|--------|
| EU road freight reached **1,886 billion tonne-km** in 2025. **37.8%** of it was international transport, cross-trade or cabotage, so it involved more than one country or a foreign haulier. | [Eurostat, 31 July 2026](https://ec.europa.eu/eurostat/web/products-eurostat-news/w/ddn-20260731-2) |
| The EU has **24 official languages**. | [European Union — Languages](https://european-union.europa.eu/principles-countries-history/languages_en) |
| The CMR sets short periods: reservations for non-apparent loss or damage within **7 days**, for delay within **21 days**, and a **one-year** limitation period (Art. 30, 32). | [CMR Convention, UNECE](https://unece.org/DAM/trans/conventn/cmr_e.pdf) |

P3 is a working assumption about how small and mid-sized logistics companies manage claims; it is validated with the MVP demo, not with statistics.

## 2. Proposed Outcome

A web application on Oracle AI Database 26ai and Oracle APEX, delivered as **Release 1**. The MVP runs **entirely in the database**, with no external services.

| Component | What it does | Solves |
|-----------|--------------|--------|
| **MVP** — Claims management | One structured place for shipments, claims, documents and a controlled status workflow, instead of emails and spreadsheets | P3 |
| **MVP** — Recovery tracking | Records settled and recovered amounts and shows the recovery rate per carrier | P3 |
| **MVP** — Shipment import | Loads existing shipment data from CSV or Excel files | P3 |
| **MVP** — Dashboards | Claim indicators by carrier, route, country, type, status and ageing | P3 |
| **MVP** — CMR deadline tracking | Calculates reservation and limitation deadlines for each claim and flags claims at risk | P2 |
| **MVP** — Deadline alerts | Warns handlers on the home page and by daily email before a deadline expires | P2 |
| **MVP** — Multilingual legal search | Finds the relevant CMR and EU articles, with citations, from a question in EN, DE, FR or ES | P1, P2 |
| **MVP** — Claim letters | Generates reservation and claim letters in English or German | P1, P2 |
| **MVP** — Liability cap | Shows the maximum compensation under CMR Art. 23 | P2 |
| **MVP** — English / German interface | Users switch the application language with a selector | P1 |
| *EXT* — AI summaries and translations | Summarises and translates claim documents through a secure AI gateway | P1 |
| *EXT* — AI answers with citations | Answers legal questions grounded in the retrieved articles | P2 |
| *EXT* — Natural-language questions on claim data | Answers new questions without IT reports or Excel work | P3 |
| *EXT* — REST API | Lets other systems (e.g., a TMS) create claims and read their status | P3 |
| *EXT* — GDPR compliance pack | Data retention, erasure requests and compliance records | P2 |

## 3. Users

| User | Needs |
|------|-------|
| Claims Handler | Register shipments and claims, meet CMR deadlines, find applicable rules quickly. |
| Compliance Officer | Check compliance with the CMR and the GDPR; review AI usage. |
| Logistics Analyst | See claim trends by carrier, route and country. |
| Administrator | Manage reference data, the legal corpus and access. |

## 4. Constraints

- **Platform:** local Oracle AI Database 26ai Free (2 CPU, 2 GB RAM, 12 GB data), APEX 24.2, ORDS, SQLcl. The design must scale beyond these limits without redesign (spec §12).
- **Data:** synthetic data only; privacy by design (GDPR).
- **AI:** external AI only through one PL/SQL gateway, with EU/EEA data processing.
- **Engineering:** everything as code (idempotent SQLcl scripts in Git); no secrets in files.
- **Legal:** results are informational, not legal advice.
- **Time:** limited; MVP first, and every milestone must be releasable.

## 5. Out of Scope (Release 1)

- Payments, complex identity management, legal advice, real personal data.
- Other transport modes (air, sea, rail) and national transport law.
- Integrations with courts, e-CMR/eFTI platforms, TMS or telematics.
- OCR and image analysis, model training, production infrastructure, multi-tenancy, mobile apps.
- Native Oracle Select AI (not available in 26ai Free) and UI translations beyond English and German.

## 6. Success Measures

- The **MVP is published** as a GitHub release with a README in English and German, design diagrams and a demo.
- Claim **status rules and CMR deadlines** are enforced in the database and covered by tests; handlers receive **alerts** in the app and by email.
- **Search quality:** Recall@5 ≥ 0.80, ≥ 0.70 in each language, p95 latency < 500 ms.
- **No secrets** in the repository and **no AI calls** outside the gateway.

Detailed, testable criteria are defined in [spec.md §8](spec.md#8-success-criteria).

## 7. Open Questions

To be resolved in Stage 2 — Design.

| # | Question | Resolved in |
|---|----------|-------------|
| Q1 | Deployment method: plain SQLcl scripts or SQLcl `project` / Liquibase? | ADR-005 |
| Q2 | Which multilingual ONNX embedding model fits the 2 GB memory limit and licence needs? | ADR-004 |
| Q3 | Which LLM provider offers EU/EEA processing within budget? (extensions only) | ADR-003 |
| Q4 | Which country's public holidays apply to the 7-day reservation period? (The deadline rules themselves were verified against the official CMR text.) | [spec.md §5](spec.md#5-cmr-deadline-rules) |
| Q5 | Which APEX application ID will the project application use? | [spec.md §10](spec.md#10-repository-structure) |

Decisions already taken: [ADR-001](adr/ADR-001-hnsw-vector-index.md) (HNSW vector index) and [ADR-002](adr/ADR-002-nl-to-sql-via-ai-gateway.md) (NL-to-SQL through the AI gateway).

## 8. Revision History

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-10-03 | Initial version, accepted by the owner. |
| v1.1 | 2026-10-04 | German UI with a language selector added to the MVP (previously out of scope); accepted by the owner. |
