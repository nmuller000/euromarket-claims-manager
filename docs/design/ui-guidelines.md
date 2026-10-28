# User Interface Guidelines (APEX Pages)

| | |
|---|---|
| **Status** | Accepted v1.0 (2026-10-28) (D-85) |
| **Schema** | `EMK_UI` (APEX parsing schema, application 200); pages read views and call the APIs of `EMK_API` ([api-design.md](api-design.md)) |
| **Milestone** | M1a step 7.8 onwards; every page of the application |
| **Input** | [spec.md](../spec.md) §1.3 (*Error handling*), §7.1 (roles) · owner rules of 2026-10-21/22 · the official sources in §6 |

How every page of the application is built, so that it is understandable for its users, accessible, and easy to maintain. The rules come from the official Oracle APEX documentation, the European accessibility standard and established public-sector form design, and from the owner's decisions. Each page is checked against the list in §5 before it is committed.

## 1. Principles (owner rules)

| # | Rule | Why |
|---|------|-----|
| P1 | **No business logic in a page.** Every process calls a stored procedure of `EMK_API` (one process of type *Invoke API* per button, with the server-side condition *When Button Pressed*); pages may contain queries on views, display conditions and declarative settings, never a business rule, DML or a decision of the business | Rules in one place, also for the import (M1b); maintainability (spec §1.1) |
| P2 | **The interface reflects the rules.** What a rule forbids is not offered: read-only fields, hidden or disabled buttons, lists without forbidden values, with the reason shown. The API enforces the rule and the database guarantees it; their refusal is only the safety net | A user should never try something and then be refused (D-82, three layers) |
| P3 | **Every message is friendly**: it says what happened and how to fix it, never an ORA- code, a constraint name, a stack or a technical word. Texts are text messages of the application, maintained by the developer with the rule they explain, approved by the business | Users understand the system (error handling function, §3) |
| P4 | **The names users already know**: labels follow the CMR consignment note and the usual terms of logistics systems; the same word in labels and messages; an inventory of labels per page is approved before the page is built | Users do not learn new names (D-83, D-84) |
| P5 | **Access per capability**: each page, region and button names an authorization scheme of a capability (`CAN_EDIT_PARTIES_SHIPMENTS`…), never a role; the menu shows only what the user may use. **Every process that changes data carries the authorization scheme of its capability too**, not only its button: a request can be sent without pressing the button (APEX Advisor, security check) | Who may do what changes in one place (spec §7.1) |
| P6 | **Only what the business needs.** Every feature that is not a business need is disabled (e.g. download, send as email, subscriptions, flashback, public reports of an interactive report); every action that manipulates information or copies it out of the system is granted through the authorization scheme of a capability, with roles the business has authorized | Owner rule (D-87); data minimisation (GDPR Art. 5(1)(c)) |

## 2. Page Rules (official sources)

| # | Rule | Source |
|---|------|--------|
| R1 | **Universal Theme with the theme style Vita**, the default style that Oracle has tested for accessibility; no custom CSS or JavaScript, only the template options of the theme | Oracle: "Oracle recommends using the default Oracle APEX theme style Vita for best accessibility" (APEX 24.2 Accessibility Guide, themes) |
| R2 | **A meaningful label for every item.** A label hidden for design reasons uses the template *Hidden*, never no label; a placeholder is never the only label | Oracle: "Define meaningful labels for all items"; a placeholder alone "is insufficient for accessibility" (Accessibility Guide, form pages and items) |
| R3 | **Required items: label template *Required* plus a *Not Null* validation**, not the attribute *Value Required* (both together announce the required state twice to assistive technologies); other items use the template *Optional* | Oracle Accessibility Guide, form pages and items |
| R4 | **No reload when a value is chosen** (*Page Action on Selection*): a region is refreshed by a dynamic action, or a cascading list of values is used; if a reload cannot be avoided, the label says so | Oracle: a reload "could be disruptive to users who may not expect a page reload or change of context" |
| R5 | **Errors next to the field and in a summary at the top**, with the same words, after the user saves (not when leaving a field); the page keeps what the user typed. The application shows errors "Inline with Field and in Notification" | GOV.UK Design System: error message, error summary and validation pattern |
| R6 | **Lists of values offer only the values valid on their date** (today; the date of taking over for shipments), never mixed with retired values; a value of the record that is no longer valid is shown apart, read only, and the user chooses a valid one or removes it explicitly (D-86). A list that is the same on every page is shared (Shared Components); a list that depends on the date of the record is defined on the item, with bind variables (R7). A required list has no empty entry | Owner decision D-86 (mixing valid and retired values is confusing); APEX shared components; api-design §8 |
| R7 | **Queries use bind variables** (`:P11_PARTY_ID`), never values concatenated into the SQL text | Oracle: "accessing session state using bind variables is the most efficient way to reference session state" (APEX best practices to improve performance); also prevents SQL injection |
| R8 | **Names**: page items `P<page>_<COLUMN>` (APEX convention), pages grouped by area (page groups), buttons named by their action (`CREATE`, `SAVE`, `DELETE`) | Maintainability; the default naming of APEX wizards |
| R9 | **APEX Advisor before every commit of pages**: every finding is fixed, or the reason to keep it is written in the pull request | Oracle: the Advisor checks errors, security, performance and best practices "like a compiler or LINT tool"; fix its findings before other accessibility testing |
| R10 | **Accessibility target: WCAG 2.1 level AA**, the level of the European standard EN 301 549 referred to by the European Accessibility Act (Directive (EU) 2019/882); the Act applies mainly to consumer services, so for this internal application it is a quality target, not a legal duty. Oracle's conformance report for APEX 24.2 covers WCAG 2.1 A and AA | EN 301 549, European Accessibility Act; Oracle VPAT for APEX 24.2 |

## 2a. Build Conventions

| # | Convention | Source |
|---|------------|--------|
| C1 | **One primary button per page or dialog**, with the template option *Hot*; the other buttons are plain | Universal Theme (option *Hot*); one primary action per screen is general UX practice |
| C2 | **Buttons of a modal form**: *Cancel* on the left (closes without saving); *Create* or *Save* on the right, the primary button; *Delete* on the left, in the danger style, with a confirmation | The defaults of the APEX form wizard; positions defined by the dialog template |
| C3 | **Dialogs**: page template *Modal Dialog* for forms; *Wizard Modal Dialog* only for guided steps | APEX 24.2, creating dialog pages |
| C4 | **Help in two levels**: the format to type is shown under the item, always visible (*Inline Help Text*, e.g. "DE123456789"); what the data means and what it is used for goes in the item *Help Text*, which Universal Theme shows as a help icon next to the label — only on items whose meaning is not obvious (not on Street or City); a placeholder is never the only hint (R2) | APEX label templates (inline help, help text); Accessibility Guide; owner decision (D-85) |
| C5 | **Titles and menu**: every page has its own clear title ("Companies", "Company: …"); the navigation menu uses Font APEX icons, one entry per page with the authorization scheme of the page (P5) | The Advisor checks page titles; WCAG 2.1 success criterion 2.4.2; Universal Theme |
| C6 | **Interactive reports**: by default the main columns, sorted by name; download as CSV only | Spec §1.3 (CSV, RFC 4180) |
| C7 | **Numbers and amounts**: format masks with the group and decimal separator of the application language (`999G999G990D00` for amounts, `999G999G990D000` for kg); an amount is shown with its ISO 4217 currency code next to it | Spec §1.3 (ISO 4217, SI); APEX globalization |
| C8 | **Dates on screen**: `DD/MM/YYYY`; date and time `DD/MM/YYYY HH24:MI` (e.g. the change history); set once in the globalization attributes of the application, never per page. Files, interfaces and APIs keep ISO 8601 (`YYYY-MM-DD`, spec §1.3). Not the mask `DS`: it follows the territory of the session, which the application primary language `en` sets to AMERICA (`MM/DD/RRRR`), and the territories differ between users; Oracle also allows `DS` only together with `TS`. Improvement for the German interface (M5): `DD.MM.YYYY` if its users ask for it | Owner decision (D-85); Oracle SQL Language Reference, format models (`DS`); APEX globalization attributes |
| C9 | **Page numbers by area**: 1 home; 10–19 companies; 20–29 shipments; 30–39 claims (step 8); 50–59 master data; 80 restore; 90–99 administration (technical log); 9999 login; 0 global page. Page groups follow the same areas | Maintainability (R8) |
| C10 | **Authorization schemes of type *Is In Role or Group***: the role names separated by commas **without spaces** (`CLAIMS_HANDLER,COMPLIANCE_OFFICER,ADMINISTRATOR`). APEX does not remove a space after a comma: a name with a leading space matches no role, and every role after the first one is denied (P-48, step 7.8) | Tested in APEX 24.2 (2026-10-28); test with the demo user of **each** role in the list (§5, item 9) |

## 2b. Performance

| # | Rule | Source |
|---|------|--------|
| R11 | **No `V('ITEM')` and no substitution `&ITEM.` in SQL or PL/SQL** of the application: only bind variables (R7), so that the database reuses the execution plan | Oracle: bind variables are "the most efficient way to reference session state" (APEX best practices to improve performance) |
| R12 | **No function on an indexed column in a `WHERE` clause** (e.g. `TO_CHAR(date_column, …) = :P1_DATE`): the input is converted and compared with the column as it is. Business dates have no time part (spec §1.3, check constraints), so they are compared directly | Oracle: the optimizer does not use a normal index when the indexed column is inside a function (using indexes in database applications) |
| R13 | **Reports return native dates and numbers**; the format comes from the format mask of the column (C7, C8), never `TO_CHAR` in the query, which costs work per row and breaks the sorting. Exception: `row_version`, which the page needs as text | Same; APEX format masks |
| R14 | **A region query lists only the columns it shows, never `SELECT *`.** In particular, the columns of a view computed by functions (`EMK_V_PARTIES.roles_in_use`, `deletable_yn`) are read only by the form of one record, never by a list, so that the functions do not run for every row | Less work and memory per request; views of api-design §8 |
| R15 | **Interactive reports show 50 rows per page** (server-side pagination) | Less rendering in the browser |
| R16 | **Region cache only for static content or dashboards**, *Cached by User* when the content depends on the role; never for forms or data that must be current | Oracle: caching for static regions; the engine renders a cached region only if its condition is met (managing page and region caching) |
| R17 | **Build Options** exclude a feature per release or environment (status *Exclude*: the engine treats the component as if it did not exist); a component no longer used is deleted, Git keeps its history; no server-side condition "Never" | APEX 24.2, about build options |
| R18 | **Measure before optimizing**: debug up to level 6 (*App Trace*); level 9 (*Full Trace*) only when Oracle Support asks, because it slows the application for every user; activity in `APEX_WORKSPACE_ACTIVITY_LOG` (application logging is on); the response-time targets are checked in M1 plan step 11 | APEX 24.2, available debug levels; best practices to improve performance |

## 3. Errors and Messages

- The error handling function `EMK_APEX_ERROR_PKG.handle_error` turns every error into a friendly text: a business error shows the text message `EMK_ERROR_<code>`, a constraint violation the text message named as the constraint, anything else a generic text with the number of a log entry ([api-design.md](api-design.md)).
- Text messages live in Shared Components → Globalization → Text Messages and travel with the application export; German follows with the translated interface (M5).
- A new business error or a constraint a user can reach gets its text in the same change, approved by the business; `tests/emk_ui/error_messages_test.sql` fails if one is missing.
- Messages of APEX itself (e.g. a required item left empty) are reviewed so that they follow P3 as well.

## 4. Page Patterns

| Pattern | Use | How |
|---------|-----|-----|
| **List** | Companies, shipments, master data lists | Interactive report on the view of the entity; a button *Create* for who may edit; each row opens the form |
| **Form in a modal dialog** | One company, shipment, contact, master data value | Form region on the view; hidden items for the key and `row_version`; buttons *Create*, *Save*, *Delete* (with confirmation), each calling one API procedure; read-only for who may only view (`APEX_AUTHORIZATION.IS_AUTHORIZED` of the edit capability) |
| **Child records** | Contacts of a company | A report in the parent form and a modal form per child record — not an editable grid, whose save processing would need code in the page (P1) |
| **History** | Changes of a record | A report on the history view in the form, for the roles of spec §7.1 |
| **Rules shown in advance** | E.g. roles in use, a company that cannot be deleted | Columns of the view computed by the same API functions that enforce the rule (`get_roles_in_use`, `is_deletable`) |

**Standard configuration of an interactive report** (P6, D-87; region → Attributes → Actions Menu, Search Bar, Download):

| Feature | Setting | Why |
|---------|---------|-----|
| Search bar, Filter, Sort, Select Columns, Reset, Help | On | Find and read records |
| Control Break, Highlight, Compute, Aggregate, Chart, Group By, Pivot | On | Analysis of what the user already sees; nothing changes or leaves the system (owner) |
| Save Report (private) | On | A view for the user only |
| Rows Per Page (and its selector) | Off | 50 rows fixed (R15) |
| Save Public Report | Off | Would change what other users see |
| Flashback | Off | Shows data as it was in the past, also data corrected or erased (GDPR); not a requirement |
| Download, Send as Email, Subscription | Off | Copy data out of the system; only through a capability the business authorizes (P6) |

## 5. Checklist Before a Page Is Committed

1. The label inventory of the page is approved (P4).
2. Every process is a call of an API procedure; no business rule in the page (P1).
3. Every rule the user can meet is shown before saving (P2).
4. Every item has a label; required items: template *Required* and a *Not Null* validation (R2, R3); in every report the column that names the record has *Value Identifies Row* (row header for screen readers, an Advisor accessibility check).
5. No list reloads the page (R4); lists of values are shared (R6); queries use bind variables, without `V()` or `&ITEM.` (R7, R11), and list only the columns they show (R14); no function on an indexed column (R12).
6. Page, regions, buttons and every process that changes data have the authorization scheme of their capability; the menu entry too (P5).
6a. One primary button; buttons, dialog, help, title and page number follow C1–C5 and C9; role names of an authorization scheme without spaces (C10); reports show 50 rows and format dates and numbers by masks (C6–C8, R13, R15).
7. Every message the page can show is friendly (P3).
8. APEX Advisor: no open finding (R9).
9. The page is tested in the browser with the demo user of each role (step 7.9).

## 6. Sources

**Oracle APEX 24.2**
- [Accessibility Guide — About](https://docs.oracle.com/en/database/oracle/apex/24.2/aeacc/about-accessibility.html) · [Developing Accessible Themes](https://docs.oracle.com/en/database/oracle/apex/24.2/aeacc/developing-accessible-themes.html) · [Form Pages and Items](https://docs.oracle.com/en/database/oracle/apex/24.1/aeacc/form-pages-and-items.html) · [Testing Apps for Accessibility](https://docs.oracle.com/en/database/oracle/apex/24.2/aeacc/testing-apps-for-accessibility.html) · [Accessibility Help Text](https://docs.oracle.com/en/database/oracle/apex/24.2/aeacc/accessibility-help-text.html)
- [Running Advisor to Check Application Integrity](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/running-advisor-to-check-application-integrity.html) · [About Best Practices to Improve Performance](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/about-best-practices-to-improve-performance.html)
- [Example of an Error Handling Function](https://docs.oracle.com/en/database/oracle/apex/24.2/aeapi/Example-of-an-Error-Handling-Function.html) · [APEX_ERROR](https://docs.oracle.com/en/database/oracle/apex/24.2/aeapi/APEX_ERROR.html) · [Creating Text Messages](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/creating-text-messages.html) · [APEX_LANG.MESSAGE](https://docs.oracle.com/en/database/oracle/apex/24.1/aeapi/MESSAGE-Function.html) · [APEX_AUTHORIZATION.IS_AUTHORIZED](https://docs.oracle.com/en/database/oracle/apex/24.2/aeapi/IS_AUTHORIZED-Function.html) · [Configuring Security Attributes](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/configuring-security-attributes.html)
- [APEX 22.2 New Features (Invoke API)](https://docs.oracle.com/en/database/oracle/apex/22.2/htmrn/new-features.html) · [Oracle APEX blog — Forms in APEX 19.1 (Target Type PL/SQL Code)](https://blogs.oracle.com/apex/forms-in-apex-191-more-power-more-flexibility)
- [Universal Theme — Forms](https://apex.oracle.com/pls/apex/apex_pm/r/ut10/forms) · [Oracle VPAT for APEX 24.2](https://docs.oracle.com/en/corporate/accessibility/templates/t2-15004.html)

**Accessibility law and standards**
- [European Commission — Accessibility (Europa web guide)](https://commission.europa.eu/resources/europa-web-guide/design-content-and-development/accessibility/what-accessibility_de) · [EN 301 549 (arc42 quality model)](https://quality.arc42.org/standards/en-301-549) · [European Accessibility Act and EN 301 549 (Clym)](https://www.clym.io/regulations/european-accessibility-act-eea-en-301549)

**Form design**
- [GOV.UK Design System — Error message](https://design-system.service.gov.uk/components/error-message) · [Error summary](https://design-system.service.gov.uk/components/error-summary) · [Validation pattern](https://design-system.service.gov.uk/patterns/validation)

**Domain terms (P4)**
- CMR Convention (UNECE text, `data/sources/cmr_e.pdf`; Spanish text: [BOE](https://www.boe.es/eli/es/ai/1956/05/19/(1)/con)) · [SAP Learning — condition records Valid From / Valid To](https://learning.sap.com/courses/implementing-sap-s-4hana-cloud-public-edition-sales-configuration/managing-condition-records-for-sales-prices) · [European Commission — VIES (VAT identification number)](https://europa.eu/youreurope/business/taxation/vat/check-vat-number-vies/index_fr.htm) · [UPU — formatting an international address (postcode)](https://www.upu.int/UPU/media/upu/documents/PostCode/AddressElementsFormattingAnInternationalAdressEn.pdf)

**Build conventions and performance**
- [Universal Theme — Buttons](https://apex.oracle.com/pls/apex/r/apex_pm/ut12/buttons) · [Universal Theme — Regions](https://apex.oracle.com/pls/apex/r/apex_pm/ut11/regions) · [APEX 24.2 — Creating Dialog Pages](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/creating-dialog-pages.html) · [APEX 24.1 — Label Templates (inline help)](https://docs.oracle.com/en/database/oracle/apex/24.1/htmdb/label-templates.html) · [APEX 23.1 — Configuring Globalization Attributes](https://docs.oracle.com/en/database/oracle/apex/23.1/htmdb/configuring-globalization-attributes.html) · [APEX 24.2 — Built-in Substitution Strings](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/using-available-built-in-substitution-strings.html)
- [Oracle 26 SQL Language Quick Reference — Format Models (`DS`, `TS`)](https://docs.oracle.com/en/database/oracle/oracle-database/26/sqlqr/Format-Models.html) · [Oracle 19 — Using Indexes in Database Applications](https://docs.oracle.com/en/database/oracle/oracle-database/19/adfns/indexes.html)
- [APEX 24.2 — About Build Options](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/about-build-options.html) · [APEX 24.2 — Managing Page and Region Caching](https://docs.oracle.com/en/database/oracle/apex/24.2/aeadm/managing-page-and-region-caching.html) · [APEX 24.1 — Editing Regions (Server Cache)](https://docs.oracle.com/en/database/oracle/apex/24.1/htmdb/editing-regions.html) · [APEX 24.2 — Available Debug Levels](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/available-debug-levels.html) · [APEX 24.2 — Viewing Debug Messages](https://docs.oracle.com/en/database/oracle/apex/24.2/htmdb/viewing-debug-messages.html)

## 7. Revision History

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-10-22 | First version (D-85): owner rules P1–P5, page rules R1–R10 from the official sources, build conventions C1–C10 (dates `DD/MM/YYYY`, page numbers by area, role names without spaces), performance rules R11–R18, errors and messages, page patterns, checklist. Accepted by the owner (2026-10-28). |
