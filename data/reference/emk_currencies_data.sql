-- =============================================================================
-- emk_currencies_data.sql
-- EMK_CURRENCIES: 32 currencies, EUR and those with an ECB reference rate,
-- plus the closed HRK and BGN (D-37, BR-12).
-- Sources: ECB reference rates table of 2026-10-07 (RUB suspended), ISO 4217
-- SIX lists of 2026-09-17 (iso_name, minor units; BGN and HRK from the
-- historic list), EU authority table Currencies (name).
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql;
-- added to the first release with `project stage add-custom`, run once
-- (M1 plan, open point 6; first release in M5).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-08 (M1a step 2); schema-qualified 2026-10-13 (phase M.3)
-- =============================================================================

MERGE INTO emk_data.emk_currencies t
USING (VALUES
        ('AUD', 'Australian dollar', 'Australian Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('BGN', 'Lev', 'Bulgarian Lev', 2, 'Y', DATE '2025-12-31'),
        ('BRL', 'Real', 'Brazilian Real', 2, 'Y', CAST(NULL AS DATE)),
        ('CAD', 'Canadian dollar', 'Canadian Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('CHF', 'Swiss franc', 'Swiss Franc', 2, 'Y', CAST(NULL AS DATE)),
        ('CNY', 'Renminbi-yuan', 'Yuan Renminbi', 2, 'Y', CAST(NULL AS DATE)),
        ('CZK', 'Czech koruna', 'Czech Koruna', 2, 'Y', CAST(NULL AS DATE)),
        ('DKK', 'Danish krone', 'Danish Krone', 2, 'Y', CAST(NULL AS DATE)),
        ('EUR', 'Euro', 'Euro', 2, 'N', CAST(NULL AS DATE)),
        ('GBP', 'Pound sterling', 'Pound Sterling', 2, 'Y', CAST(NULL AS DATE)),
        ('HKD', 'Hong Kong dollar', 'Hong Kong Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('HRK', 'Kuna', 'Kuna', 2, 'Y', DATE '2022-12-31'),
        ('HUF', 'Forint', 'Forint', 2, 'Y', CAST(NULL AS DATE)),
        ('IDR', 'Rupiah', 'Rupiah', 2, 'Y', CAST(NULL AS DATE)),
        ('ILS', 'Shekel', 'New Israeli Sheqel', 2, 'Y', CAST(NULL AS DATE)),
        ('INR', 'Indian rupee', 'Indian Rupee', 2, 'Y', CAST(NULL AS DATE)),
        ('ISK', 'Iceland króna', 'Iceland Krona', 0, 'Y', CAST(NULL AS DATE)),
        ('JPY', 'Yen', 'Yen', 0, 'Y', CAST(NULL AS DATE)),
        ('KRW', 'South Korean won', 'Won', 0, 'Y', CAST(NULL AS DATE)),
        ('MXN', 'Mexican peso', 'Mexican Peso', 2, 'Y', CAST(NULL AS DATE)),
        ('MYR', 'Ringgit', 'Malaysian Ringgit', 2, 'Y', CAST(NULL AS DATE)),
        ('NOK', 'Norwegian krone', 'Norwegian Krone', 2, 'Y', CAST(NULL AS DATE)),
        ('NZD', 'New Zealand dollar', 'New Zealand Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('PHP', 'Philippine peso', 'Philippine Peso', 2, 'Y', CAST(NULL AS DATE)),
        ('PLN', 'Zloty', 'Zloty', 2, 'Y', CAST(NULL AS DATE)),
        ('RON', 'Romanian leu', 'Romanian Leu', 2, 'Y', CAST(NULL AS DATE)),
        ('SEK', 'Swedish krona', 'Swedish Krona', 2, 'Y', CAST(NULL AS DATE)),
        ('SGD', 'Singapore dollar', 'Singapore Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('THB', 'Baht', 'Baht', 2, 'Y', CAST(NULL AS DATE)),
        ('TRY', 'Turkish lira', 'Turkish Lira', 2, 'Y', CAST(NULL AS DATE)),
        ('USD', 'US dollar', 'US Dollar', 2, 'Y', CAST(NULL AS DATE)),
        ('ZAR', 'Rand', 'Rand', 2, 'Y', CAST(NULL AS DATE))
      ) s (currency_code, name, iso_name, minor_units, ecb_rate_yn, valid_to)
ON (t.currency_code = s.currency_code)
WHEN NOT MATCHED THEN INSERT
    (currency_code, name, iso_name, minor_units, ecb_rate_yn, valid_to)
VALUES
    (s.currency_code, s.name, s.iso_name, s.minor_units, s.ecb_rate_yn, s.valid_to);

COMMIT;
