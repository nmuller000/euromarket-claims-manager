# CLAUDE.md

## Project
CMR freight-claims application on Oracle AI Database 26ai Free, APEX 24.2 and ORDS.
Context: docs/sdlc.md (current stage) · docs/intent.md · docs/spec.md · docs/glossary.md · docs/setup.md · docs/adr/

## Commands
- Connect: `sql -thin <user>@localhost:1521/FREEPDB1` (SQLcl, thin JDBC driver)
- Lint: `npm run lint`
- Admin setup (SYS): `scripts/install_admin.sql` · Application: SQLcl `project` (ADR-005) · Tests (utPLSQL, never in PROD): `tests/install_tests.sql` and `tests/run_tests.sql`, once per schema that owns tests (`EMK_DEV[EMK_DATA]`, `EMK_DEV[EMK_API]`)

## Conventions
- Database objects use the `EMK_` prefix. Admin scripts are idempotent (existence checks, `MERGE` for data); application changes go through SQLcl `project`.
- A script run from the command line ends with `EXIT`; a script called with `@@` never does. Reference data: idempotent `MERGE` scripts in `data/reference/`.
- Business rules live in PL/SQL packages, not in APEX page logic.
- PL/SQL naming and documentation follow spec §1.3 (*Naming*, *Code documentation*): subprograms named with verbs, no `p_`/`f_` prefixes; `/** */` headers inside the object with `@author` and the line `Copyright (c) 2026 Natalia Müller. All rights reserved.`; `COMMENT ON` for tables. Repository is all rights reserved (LICENSE).
- AI calls only through `EMK_AI_GATEWAY_PKG`; embeddings are computed in-database.
- No secrets in files; passwords are entered at run time.
- Documentation in English, concise; new terms are added to docs/glossary.md.
- Follow docs/sdlc.md: drafts stay local, accepted artifacts are committed.
- One branch and pull request per change; Conventional Commits; explicit `git add <files>`.
- After a database restart, restart ORDS.
