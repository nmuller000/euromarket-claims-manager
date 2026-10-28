-- =============================================================================
-- emk_vat_formats_data.sql
-- EMK_VAT_FORMATS: format of the national part of an EU VAT number for each
-- VAT prefix (D-88): the 27 member states (EL for Greece) and XI for traders
-- in Northern Ireland (country GB, since 2021-01-01).
-- Sources: Bundeszentralamt für Steuern (BZSt), "Aufbau der USt-IdNr. in den
-- EU-Mitgliedstaaten" (structure per member state and XI); HMRC, "Selling or
-- moving goods between Northern Ireland and the EU" (XI: same digits as the
-- GB number, checked in VIES); GD 000-499 for government departments and
-- HA 500-999 for health authorities (HMRC VAT number structure).
-- Netherlands: the 10th character is B (Ondernemersplein, Dutch government);
-- the first nine may also hold letters, + and * (BZSt): where the sources
-- differ, the wider rule, as the format check only catches typing errors and
-- VIES confirms that a number exists (growth path, M1 plan §2).
-- Patterns: anchored, explicit character lists, never ranges such as [0-9]
-- (spec §1.3 Check constraints, P-20). A check constraint of the table
-- rejects a pattern without anchors; a unit test checks that each example
-- follows its pattern (a check constraint accepts only a literal pattern).
-- Insert-only MERGE (D-72): inserts the rows that are missing and never
-- changes or deletes an existing row, so that running it again (DEV, a
-- release) never overwrites production data. A change to an existing row
-- is a separate change script, run once, that cites the authorized change
-- request and its source (ITIL change enablement; Liquibase: roll forward).
-- Schema-qualified (ADR-008): runs in a session of EMK_DATA or of the
-- deployment account. Loaded by load_reference_data.sql after
-- emk_countries_data.sql (foreign key to the country).
--
-- Author: Natalia Müller
-- Copyright (c) 2026 Natalia Müller. All rights reserved.
-- Since:  2026-10-25 (M1a step 7.8, D-88)
-- =============================================================================

MERGE INTO emk_data.emk_vat_formats t
USING (VALUES
        ('AT', 'AT', '^U[0123456789]{8}$', 'U12345678', DATE '1900-01-01'),
        ('BE', 'BE', '^[0123456789]{10}$', '0123456789', DATE '1900-01-01'),
        ('BG', 'BG', '^[0123456789]{9,10}$', '123456789', DATE '1900-01-01'),
        ('CY', 'CY', '^[0123456789]{8}[ABCDEFGHIJKLMNOPQRSTUVWXYZ]$', '12345678X', DATE '1900-01-01'),
        ('CZ', 'CZ', '^[0123456789]{8,10}$', '12345678', DATE '1900-01-01'),
        ('DE', 'DE', '^[0123456789]{9}$', '123456789', DATE '1900-01-01'),
        ('DK', 'DK', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('EE', 'EE', '^[0123456789]{9}$', '123456789', DATE '1900-01-01'),
        ('EL', 'GR', '^[0123456789]{9}$', '123456789', DATE '1900-01-01'),
        ('ES', 'ES', '^[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ][0123456789]{7}[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]$', 'B12345678', DATE '1900-01-01'),
        ('FI', 'FI', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('FR', 'FR', '^[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{2}[0123456789]{9}$', '12345678901', DATE '1900-01-01'),
        ('HR', 'HR', '^[0123456789]{11}$', '12345678901', DATE '1900-01-01'),
        ('HU', 'HU', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('IE', 'IE', '^([0123456789][0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ][0123456789]{5}[ABCDEFGHIJKLMNOPQRSTUVWXYZ]|[0123456789]{7}[ABCDEFGHIJKLMNOPQRSTUVW][ABCDEFGHI])$', '1234567WA', DATE '1900-01-01'),
        ('IT', 'IT', '^[0123456789]{11}$', '12345678901', DATE '1900-01-01'),
        ('LT', 'LT', '^([0123456789]{9}|[0123456789]{12})$', '123456789', DATE '1900-01-01'),
        ('LU', 'LU', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('LV', 'LV', '^[0123456789]{11}$', '12345678901', DATE '1900-01-01'),
        ('MT', 'MT', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('NL', 'NL', '^[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+*]{9}B[0123456789]{2}$', '123456789B01', DATE '1900-01-01'),
        ('PL', 'PL', '^[0123456789]{10}$', '1234567890', DATE '1900-01-01'),
        ('PT', 'PT', '^[0123456789]{9}$', '123456789', DATE '1900-01-01'),
        ('RO', 'RO', '^[123456789][0123456789]{1,9}$', '12345678', DATE '1900-01-01'),
        ('SE', 'SE', '^[0123456789]{10}01$', '123456789001', DATE '1900-01-01'),
        ('SI', 'SI', '^[0123456789]{8}$', '12345678', DATE '1900-01-01'),
        ('SK', 'SK', '^[0123456789]{10}$', '1234567890', DATE '1900-01-01'),
        ('XI', 'GB', '^([0123456789]{9}|[0123456789]{12}|GD[01234][0123456789]{2}|HA[56789][0123456789]{2})$', '123456789', DATE '2021-01-01')
      ) s (vat_prefix, country_code, national_format, national_example, valid_from)
ON (t.vat_prefix = s.vat_prefix)
WHEN NOT MATCHED THEN INSERT
    (vat_prefix, country_code, national_format, national_example, valid_from)
VALUES
    (s.vat_prefix, s.country_code, s.national_format, s.national_example, s.valid_from);

COMMIT;
