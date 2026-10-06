# EuroMarket AI-Driven Compliance & Claims Manager

Web application for managing **cross-border road freight claims** under the **CMR Convention**: claims and documents in one place, CMR deadline tracking with alerts, multilingual legal search and claim indicators by carrier, route and country.

Built on **Oracle AI Database 26ai** and **Oracle APEX**. The MVP runs entirely in the database, with no external services.

> **Status:** in development — Stage 3 (Build), milestone **M0 — Foundations**. See [docs/sdlc.md](docs/sdlc.md).

## Technology

| Area | Technology |
|------|------------|
| Database | Oracle AI Database 26ai Free (PL/SQL, AI Vector Search) |
| Application | Oracle APEX 24.2, ORDS 25.4 |
| Deployment | SQLcl 25.4: admin scripts + SQLcl `project` (Liquibase) — [ADR-005](docs/adr/ADR-005-deployment-and-database-setup.md) |
| Tests | utPLSQL 3.2.3 |

## Documentation

| Document | Content |
|----------|---------|
| [Intent](docs/intent.md) | Problem, users, scope |
| [Specification](docs/spec.md) | Requirements, business rules, design, test strategy |
| [SDLC](docs/sdlc.md) | Development stages and current status |
| [Setup guide](docs/setup.md) | Local environment and database installation |
| [Architecture decisions](docs/adr/README.md) | ADRs |
| [Glossary](docs/glossary.md) | Functional and technical terms |

## Repository Layout

| Folder | Content |
|--------|---------|
| `docs/` | Intent, specification, plans, ADRs, glossary, setup guide |
| `scripts/` | Admin scripts run as `SYS` (tablespace, roles, schema, workspace, utPLSQL) |
| `.dbtools/`, `src/`, `dist/` | SQLcl project: application objects and APEX app 200 (from M1) |
| `static/` | APEX static files (JavaScript, CSS) |

## Author

Natalia Müller ([@nmuller000](https://github.com/nmuller000))
