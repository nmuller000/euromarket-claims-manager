-- =============================================================================
-- emk_currency_names_data.sql
-- EMK_CURRENCY_NAMES: German names of the 32 currencies (D-37).
-- Source: EU authority table Currencies (German labels).
-- Idempotent MERGE: inserts missing rows, updates only rows whose values
-- changed (no needless updated_* changes), never deletes (a reference row is
-- closed with valid_to). Schema-qualified (ADR-008): runs in a session of
-- EMK_DATA or of the deployment account. Loaded by load_reference_data.sql;
-- added to the first release with `project stage add-custom` and runOnChange
-- (M1 plan, open point 6; first release in M5).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-08 (M1a step 2); schema-qualified 2026-10-13 (phase M.3)
-- =============================================================================

MERGE INTO emk_data.emk_currency_names t
USING (VALUES
        ('AUD', 'de', 'Australischer Dollar'),
        ('BGN', 'de', 'Lew'),
        ('BRL', 'de', 'Real'),
        ('CAD', 'de', 'Kanadischer Dollar'),
        ('CHF', 'de', 'Schweizer Franc'),
        ('CNY', 'de', 'Renminbi Yuan'),
        ('CZK', 'de', 'Tschechische Krone'),
        ('DKK', 'de', 'Dänische Krone'),
        ('EUR', 'de', 'Euro'),
        ('GBP', 'de', 'Pfund Sterling'),
        ('HKD', 'de', 'Hongkong-Dollar'),
        ('HRK', 'de', 'Kuna'),
        ('HUF', 'de', 'Forint'),
        ('IDR', 'de', 'Rupiah'),
        ('ILS', 'de', 'Shekel'),
        ('INR', 'de', 'Indische Rupie'),
        ('ISK', 'de', 'Isländische Krone'),
        ('JPY', 'de', 'Yen'),
        ('KRW', 'de', 'Südkoreanischer Won'),
        ('MXN', 'de', 'Mexikanischer Peso'),
        ('MYR', 'de', 'Ringgit'),
        ('NOK', 'de', 'Norwegische Krone'),
        ('NZD', 'de', 'Neuseeland-Dollar'),
        ('PHP', 'de', 'Philippinischer Peso'),
        ('PLN', 'de', 'Zloty'),
        ('RON', 'de', 'Rumänischer Leu'),
        ('SEK', 'de', 'Schwedische Krone'),
        ('SGD', 'de', 'Singapur-Dollar'),
        ('THB', 'de', 'Baht'),
        ('TRY', 'de', 'Türkische Lira'),
        ('USD', 'de', 'US-Dollar'),
        ('ZAR', 'de', 'Rand')
      ) s (currency_code, language_code, name)
ON (t.currency_code = s.currency_code AND t.language_code = s.language_code)
WHEN MATCHED THEN UPDATE SET t.name = s.name
  WHERE t.name <> s.name
WHEN NOT MATCHED THEN INSERT (currency_code, language_code, name)
VALUES (s.currency_code, s.language_code, s.name);

COMMIT;
