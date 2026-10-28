-- =============================================================================
-- emk_countries_data.sql
-- EMK_COUNTRIES: 60 countries, the 58 CMR parties plus Iceland and
-- Liechtenstein (D-37).
-- Sources: UN Treaty Collection (CMR deposits, Art. 43 rule), EU authority
-- table Countries and territories (name), ISO 3166-1 (iso_name), EU and EEA
-- membership. The VAT prefix of a country is in EMK_VAT_FORMATS (D-88,
-- 2026-10-25: one source; XI belongs to GB, EL to GR).
-- The postcode rule of a country is in EMK_POSTAL_FORMATS (D-90, 2026-10-28).
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
        ('AF', 'Afghanistan', 'Afghanistan', 'N', 'N', DATE '2021-01-05'),
        ('AL', 'Albania', 'Albania', 'N', 'N', DATE '2006-10-18'),
        ('AM', 'Armenia', 'Armenia', 'N', 'N', DATE '2006-09-07'),
        ('AT', 'Austria', 'Austria', 'Y', 'Y', DATE '1961-07-02'),
        ('AZ', 'Azerbaijan', 'Azerbaijan', 'N', 'N', DATE '2006-12-17'),
        ('BA', 'Bosnia and Herzegovina', 'Bosnia and Herzegovina', 'N', 'N', DATE '1993-09-01'),
        ('BE', 'Belgium', 'Belgium', 'Y', 'Y', DATE '1962-12-17'),
        ('BG', 'Bulgaria', 'Bulgaria', 'Y', 'Y', DATE '1978-01-18'),
        ('BY', 'Belarus', 'Belarus', 'N', 'N', DATE '1993-07-04'),
        ('CH', 'Switzerland', 'Switzerland', 'N', 'N', DATE '1970-05-28'),
        ('CY', 'Cyprus', 'Cyprus', 'Y', 'Y', DATE '2003-09-30'),
        ('CZ', 'Czechia', 'Czechia', 'Y', 'Y', DATE '1993-06-02'),
        ('DE', 'Germany', 'Germany', 'Y', 'Y', DATE '1962-02-05'),
        ('DK', 'Denmark', 'Denmark', 'Y', 'Y', DATE '1965-09-26'),
        ('EE', 'Estonia', 'Estonia', 'Y', 'Y', DATE '1993-08-01'),
        ('ES', 'Spain', 'Spain', 'Y', 'Y', DATE '1974-05-13'),
        ('FI', 'Finland', 'Finland', 'Y', 'Y', DATE '1973-09-25'),
        ('FR', 'France', 'France', 'Y', 'Y', DATE '1961-07-02'),
        ('GB', 'United Kingdom', 'United Kingdom of Great Britain and Northern Ireland (the)', 'N', 'N', DATE '1967-10-19'),
        ('GE', 'Georgia', 'Georgia', 'N', 'N', DATE '1999-11-02'),
        ('GR', 'Greece', 'Greece', 'Y', 'Y', DATE '1977-08-22'),
        ('HR', 'Croatia', 'Croatia', 'Y', 'Y', DATE '1992-08-03'),
        ('HU', 'Hungary', 'Hungary', 'Y', 'Y', DATE '1970-07-28'),
        ('IE', 'Ireland', 'Ireland', 'Y', 'Y', DATE '1991-05-01'),
        ('IR', 'Iran', 'Iran (Islamic Republic of)', 'N', 'N', DATE '1998-12-16'),
        ('IS', 'Iceland', 'Iceland', 'N', 'Y', CAST(NULL AS DATE)),
        ('IT', 'Italy', 'Italy', 'Y', 'Y', DATE '1961-07-02'),
        ('JO', 'Jordan', 'Jordan', 'N', 'N', DATE '2009-02-11'),
        ('KG', 'Kyrgyzstan', 'Kyrgyzstan', 'N', 'N', DATE '1998-07-01'),
        ('KZ', 'Kazakhstan', 'Kazakhstan', 'N', 'N', DATE '1995-10-15'),
        ('LB', 'Lebanon', 'Lebanon', 'N', 'N', DATE '2006-06-20'),
        ('LI', 'Liechtenstein', 'Liechtenstein', 'N', 'Y', CAST(NULL AS DATE)),
        ('LT', 'Lithuania', 'Lithuania', 'Y', 'Y', DATE '1993-06-15'),
        ('LU', 'Luxembourg', 'Luxembourg', 'Y', 'Y', DATE '1964-07-19'),
        ('LV', 'Latvia', 'Latvia', 'Y', 'Y', DATE '1994-04-14'),
        ('MA', 'Morocco', 'Morocco', 'N', 'N', DATE '1995-05-24'),
        ('MD', 'Moldova', 'Moldova (the Republic of)', 'N', 'N', DATE '1993-08-24'),
        ('ME', 'Montenegro', 'Montenegro', 'N', 'N', DATE '2006-10-23'),
        ('MK', 'North Macedonia', 'North Macedonia', 'N', 'N', DATE '1997-06-20'),
        ('MN', 'Mongolia', 'Mongolia', 'N', 'N', DATE '2003-12-17'),
        ('MT', 'Malta', 'Malta', 'Y', 'Y', DATE '2008-03-20'),
        ('NL', 'Netherlands', 'Netherlands (Kingdom of the)', 'Y', 'Y', DATE '1961-07-02'),
        ('NO', 'Norway', 'Norway', 'N', 'Y', DATE '1969-09-29'),
        ('OM', 'Oman', 'Oman', 'N', 'N', DATE '2020-12-22'),
        ('PK', 'Pakistan', 'Pakistan', 'N', 'N', DATE '2019-08-28'),
        ('PL', 'Poland', 'Poland', 'Y', 'Y', DATE '1962-09-11'),
        ('PT', 'Portugal', 'Portugal', 'Y', 'Y', DATE '1969-12-21'),
        ('RO', 'Romania', 'Romania', 'Y', 'Y', DATE '1973-04-23'),
        ('RS', 'Serbia', 'Serbia', 'N', 'N', DATE '2001-03-12'),
        ('RU', 'Russia', 'Russian Federation (the)', 'N', 'N', DATE '1983-12-01'),
        ('SE', 'Sweden', 'Sweden', 'Y', 'Y', DATE '1969-07-01'),
        ('SI', 'Slovenia', 'Slovenia', 'Y', 'Y', DATE '1992-07-06'),
        ('SK', 'Slovakia', 'Slovakia', 'Y', 'Y', DATE '1993-05-28'),
        ('SY', 'Syria', 'Syrian Arab Republic (the)', 'N', 'N', DATE '2008-12-09'),
        ('TJ', 'Tajikistan', 'Tajikistan', 'N', 'N', DATE '1996-12-10'),
        ('TM', 'Turkmenistan', 'Turkmenistan', 'N', 'N', DATE '1996-12-17'),
        ('TN', 'Tunisia', 'Tunisia', 'N', 'N', DATE '1994-04-24'),
        ('TR', 'Türkiye', 'Türkiye', 'N', 'N', DATE '1995-10-31'),
        ('UA', 'Ukraine', 'Ukraine', 'N', 'N', DATE '2007-05-17'),
        ('UZ', 'Uzbekistan', 'Uzbekistan', 'N', 'N', DATE '1995-12-27')
      ) s (country_code, name, iso_name, eu_member_yn, eea_member_yn, cmr_party_since)
ON (t.country_code = s.country_code)
WHEN NOT MATCHED THEN INSERT
    (country_code, name, iso_name, eu_member_yn, eea_member_yn, cmr_party_since)
VALUES
    (s.country_code, s.name, s.iso_name, s.eu_member_yn, s.eea_member_yn, s.cmr_party_since);

COMMIT;
