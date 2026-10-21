# Personal Data Inventory

| | |
|---|---|
| **Status** | Accepted v1.0 (2026-10-21) (D-80) |
| **Schema** | `EMK_DATA`, `EMK_API` (log), `EMK_INT` (M1b) |
| **Input** | [spec.md](../spec.md) §3.3, §5.3 L13 · [GDPR, Regulation (EU) 2016/679](https://eur-lex.europa.eu/eli/reg/2016/679/oj) Art. 4(1), 5(1)(c), 17, 30 |

Every column that holds, or may hold, personal data: *"any information relating to an identified or identifiable natural person"* (GDPR Art. 4(1)). The erasure and pseudonymisation of the extension X4 (FR-41) must treat each place listed here. **This is a technical inventory, not the record of processing activities of Art. 30**, which also needs purposes and legal bases and should be reviewed by a data protection specialist (spec §5.3 L13).

## 1. Inventory

| Table . column | Personal data | Kind | Why it is stored | Erasure (X4, to be decided) |
|----------------|---------------|------|------------------|-----------------------------|
| `EMK_CONTACTS.full_name`, `email`, `phone` | Contact person of a company | **Direct** | Letters and contact for a claim (FR-01) | Pseudonymise; the journal too |
| `EMK_CONTACTS_JN` (same columns) | Former values | **Direct** | Change history (FR-09); visible to the compliance officer only (D-67) | Pseudonymise with the base row |
| `EMK_PARTIES.name`, `street`, `postal_code`, `city`, `vat_number` | Name and address of a **sole trader** (a natural person); not personal for a legal person | **Direct, if a sole trader** | Parties of the CMR contract (Art. 6), letters (M4) | Pseudonymise when the party is a natural person; the journal too |
| `EMK_PARTIES_JN` (same columns) | Former values | Direct, if a sole trader | Change history | With the base row |
| `created_by`, `updated_by`, `deleted_by` of every table; `jn_by` of every journal | User name of the employee who made the change | **User identity** | Accountability (FR-09, spec §1.3 *Audit columns*) | Keep while the record is kept (accountability); pseudonymise when the user account is erased |
| `EMK_CLAIMS.handler` | User name of the responsible handler | User identity | Alerts and workload (spec §2.6) | As the audit columns |
| `EMK_CLAIM_STATUS_HISTORY.created_by` | Who changed the status | User identity | Business history (spec §4) | As the audit columns |
| `EMK_LOG.created_by` | User of the session | User identity | Troubleshooting; 90 days (data-model-audit §3) | Purged with the log partitions |
| `EMK_CLAIMS.description`, `EMK_CLAIM_STATUS_HISTORY.reason` | Free text: may name persons | **Possible** | Description of the claim, reason of a status change | Review the text; redact |
| `EMK_CLAIM_RECOVERIES.reference`, `correction_reason` (step 8) | Free text: a payment reference may name the payer | Possible | Recovery tracking (D-77) | Review the text; redact |
| `EMK_CLAIM_DOCUMENTS.file_name`, `content`, `extracted_text` | Photos, letters, signatures, names in documents | **Possible** | Evidence of the claim (CMR Art. 30) | Review the document; replace it by a redacted copy (new document row, D-41) |
| `EMK_INT.EMK_INBOUND_RECORDS.payload` (M1b) | Rows of an imported file as received | Possible | Traceability of imports (ADR-007) | Purged with the inbound partitions |

**Not personal data:** shipments (goods, places, dates, weights, amounts), code lists, reference data, exchange rates, the claim amounts and dates — unless free text in them names a person.

## 2. Rules

- **Direct personal data of contacts stays isolated** in `EMK_CONTACTS` and its journal (spec §3.3): one place to erase.
- **Free text is a risk:** the pages show a short hint "Do not enter personal data here unless needed" on the description, reason and reference fields (step 8).
- **The technical log never stores personal data in its message or context** (data-model-audit §3); only the user name of the session.
- **A new column with personal data** is added to this inventory in the same change (checklist item, like the journal rule).

## 3. Revision History

| Version | Date | Change |
|---------|------|--------|
| v1.0 | 2026-10-21 | First version (D-80), from the data model validation. Accepted by the owner. |
