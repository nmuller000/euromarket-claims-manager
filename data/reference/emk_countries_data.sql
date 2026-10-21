-- =============================================================================
-- emk_countries_data.sql
-- EMK_COUNTRIES: 60 countries, the 58 CMR parties plus Iceland and
-- Liechtenstein (D-37).
-- Sources: UN Treaty Collection (CMR deposits, Art. 43 rule), EU authority
-- table Countries and territories (name), ISO 3166-1 (iso_name), EU and EEA
-- membership.
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

MERGE INTO emk_data.emk_countries t
USING (VALUES
        ('AF', 'Afghanistan', 'Afghanistan', NULL, 'N', 'N', DATE '2021-01-05'),
        ('AL', 'Albania', 'Albania', NULL, 'N', 'N', DATE '2006-10-18'),
        ('AM', 'Armenia', 'Armenia', NULL, 'N', 'N', DATE '2006-09-07'),
        ('AT', 'Austria', 'Austria', 'AT', 'Y', 'Y', DATE '1961-07-02'),
        ('AZ', 'Azerbaijan', 'Azerbaijan', NULL, 'N', 'N', DATE '2006-12-17'),
        ('BA', 'Bosnia and Herzegovina', 'Bosnia and Herzegovina', NULL, 'N', 'N', DATE '1993-09-01'),
        ('BE', 'Belgium', 'Belgium', 'BE', 'Y', 'Y', DATE '1962-12-17'),
        ('BG', 'Bulgaria', 'Bulgaria', 'BG', 'Y', 'Y', DATE '1978-01-18'),
        ('BY', 'Belarus', 'Belarus', NULL, 'N', 'N', DATE '1993-07-04'),
        ('CH', 'Switzerland', 'Switzerland', NULL, 'N', 'N', DATE '1970-05-28'),
        ('CY', 'Cyprus', 'Cyprus', 'CY', 'Y', 'Y', DATE '2003-09-30'),
        ('CZ', 'Czechia', 'Czechia', 'CZ', 'Y', 'Y', DATE '1993-06-02'),
        ('DE', 'Germany', 'Germany', 'DE', 'Y', 'Y', DATE '1962-02-05'),
        ('DK', 'Denmark', 'Denmark', 'DK', 'Y', 'Y', DATE '1965-09-26'),
        ('EE', 'Estonia', 'Estonia', 'EE', 'Y', 'Y', DATE '1993-08-01'),
        ('ES', 'Spain', 'Spain', 'ES', 'Y', 'Y', DATE '1974-05-13'),
        ('FI', 'Finland', 'Finland', 'FI', 'Y', 'Y', DATE '1973-09-25'),
        ('FR', 'France', 'France', 'FR', 'Y', 'Y', DATE '1961-07-02'),
        ('GB', 'United Kingdom', 'United Kingdom of Great Britain and Northern Ireland (the)', NULL, 'N', 'N', DATE '1967-10-19'),
        ('GE', 'Georgia', 'Georgia', NULL, 'N', 'N', DATE '1999-11-02'),
        ('GR', 'Greece', 'Greece', 'EL', 'Y', 'Y', DATE '1977-08-22'),
        ('HR', 'Croatia', 'Croatia', 'HR', 'Y', 'Y', DATE '1992-08-03'),
        ('HU', 'Hungary', 'Hungary', 'HU', 'Y', 'Y', DATE '1970-07-28'),
        ('IE', 'Ireland', 'Ireland', 'IE', 'Y', 'Y', DATE '1991-05-01'),
        ('IR', 'Iran', 'Iran (Islamic Republic of)', NULL, 'N', 'N', DATE '1998-12-16'),
        ('IS', 'Iceland', 'Iceland', NULL, 'N', 'Y', CAST(NULL AS DATE)),
        ('IT', 'Italy', 'Italy', 'IT', 'Y', 'Y', DATE '1961-07-02'),
        ('JO', 'Jordan', 'Jordan', NULL, 'N', 'N', DATE '2009-02-11'),
        ('KG', 'Kyrgyzstan', 'Kyrgyzstan', NULL, 'N', 'N', DATE '1998-07-01'),
        ('KZ', 'Kazakhstan', 'Kazakhstan', NULL, 'N', 'N', DATE '1995-10-15'),
        ('LB', 'Lebanon', 'Lebanon', NULL, 'N', 'N', DATE '2006-06-20'),
        ('LI', 'Liechtenstein', 'Liechtenstein', NULL, 'N', 'Y', CAST(NULL AS DATE)),
        ('LT', 'Lithuania', 'Lithuania', 'LT', 'Y', 'Y', DATE '1993-06-15'),
        ('LU', 'Luxembourg', 'Luxembourg', 'LU', 'Y', 'Y', DATE '1964-07-19'),
        ('LV', 'Latvia', 'Latvia', 'LV', 'Y', 'Y', DATE '1994-04-14'),
        ('MA', 'Morocco', 'Morocco', NULL, 'N', 'N', DATE '1995-05-24'),
        ('MD', 'Moldova', 'Moldova (the Republic of)', NULL, 'N', 'N', DATE '1993-08-24'),
        ('ME', 'Montenegro', 'Montenegro', NULL, 'N', 'N', DATE '2006-10-23'),
        ('MK', 'North Macedonia', 'North Macedonia', NULL, 'N', 'N', DATE '1997-06-20'),
        ('MN', 'Mongolia', 'Mongolia', NULL, 'N', 'N', DATE '2003-12-17'),
        ('MT', 'Malta', 'Malta', 'MT', 'Y', 'Y', DATE '2008-03-20'),
        ('NL', 'Netherlands', 'Netherlands (Kingdom of the)', 'NL', 'Y', 'Y', DATE '1961-07-02'),
        ('NO', 'Norway', 'Norway', NULL, 'N', 'Y', DATE '1969-09-29'),
        ('OM', 'Oman', 'Oman', NULL, 'N', 'N', DATE '2020-12-22'),
        ('PK', 'Pakistan', 'Pakistan', NULL, 'N', 'N', DATE '2019-08-28'),
        ('PL', 'Poland', 'Poland', 'PL', 'Y', 'Y', DATE '1962-09-11'),
        ('PT', 'Portugal', 'Portugal', 'PT', 'Y', 'Y', DATE '1969-12-21'),
        ('RO', 'Romania', 'Romania', 'RO', 'Y', 'Y', DATE '1973-04-23'),
        ('RS', 'Serbia', 'Serbia', NULL, 'N', 'N', DATE '2001-03-12'),
        ('RU', 'Russia', 'Russian Federation (the)', NULL, 'N', 'N', DATE '1983-12-01'),
        ('SE', 'Sweden', 'Sweden', 'SE', 'Y', 'Y', DATE '1969-07-01'),
        ('SI', 'Slovenia', 'Slovenia', 'SI', 'Y', 'Y', DATE '1992-07-06'),
        ('SK', 'Slovakia', 'Slovakia', 'SK', 'Y', 'Y', DATE '1993-05-28'),
        ('SY', 'Syria', 'Syrian Arab Republic (the)', NULL, 'N', 'N', DATE '2008-12-09'),
        ('TJ', 'Tajikistan', 'Tajikistan', NULL, 'N', 'N', DATE '1996-12-10'),
        ('TM', 'Turkmenistan', 'Turkmenistan', NULL, 'N', 'N', DATE '1996-12-17'),
        ('TN', 'Tunisia', 'Tunisia', NULL, 'N', 'N', DATE '1994-04-24'),
        ('TR', 'Türkiye', 'Türkiye', NULL, 'N', 'N', DATE '1995-10-31'),
        ('UA', 'Ukraine', 'Ukraine', NULL, 'N', 'N', DATE '2007-05-17'),
        ('UZ', 'Uzbekistan', 'Uzbekistan', NULL, 'N', 'N', DATE '1995-12-27')
      ) s (country_code, name, iso_name, eu_vat_prefix, eu_member_yn, eea_member_yn, cmr_party_since)
ON (t.country_code = s.country_code)
WHEN NOT MATCHED THEN INSERT
    (country_code, name, iso_name, eu_vat_prefix, eu_member_yn, eea_member_yn, cmr_party_since)
VALUES
    (s.country_code, s.name, s.iso_name, s.eu_vat_prefix, s.eu_member_yn, s.eea_member_yn, s.cmr_party_since);

COMMIT;
