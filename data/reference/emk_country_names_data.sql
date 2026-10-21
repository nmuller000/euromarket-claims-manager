-- =============================================================================
-- emk_country_names_data.sql
-- EMK_COUNTRY_NAMES: German names of the 60 countries (D-37).
-- Source: EU authority table Countries and territories (German labels).
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

MERGE INTO emk_data.emk_country_names t
USING (VALUES
        ('AF', 'de', 'Afghanistan'),
        ('AL', 'de', 'Albanien'),
        ('AM', 'de', 'Armenien'),
        ('AT', 'de', 'Österreich'),
        ('AZ', 'de', 'Aserbaidschan'),
        ('BA', 'de', 'Bosnien und Herzegowina'),
        ('BE', 'de', 'Belgien'),
        ('BG', 'de', 'Bulgarien'),
        ('BY', 'de', 'Belarus'),
        ('CH', 'de', 'Schweiz'),
        ('CY', 'de', 'Zypern'),
        ('CZ', 'de', 'Tschechien'),
        ('DE', 'de', 'Deutschland'),
        ('DK', 'de', 'Dänemark'),
        ('EE', 'de', 'Estland'),
        ('ES', 'de', 'Spanien'),
        ('FI', 'de', 'Finnland'),
        ('FR', 'de', 'Frankreich'),
        ('GB', 'de', 'Vereinigtes Königreich'),
        ('GE', 'de', 'Georgien'),
        ('GR', 'de', 'Griechenland'),
        ('HR', 'de', 'Kroatien'),
        ('HU', 'de', 'Ungarn'),
        ('IE', 'de', 'Irland'),
        ('IR', 'de', 'Iran'),
        ('IS', 'de', 'Island'),
        ('IT', 'de', 'Italien'),
        ('JO', 'de', 'Jordanien'),
        ('KG', 'de', 'Kirgisistan'),
        ('KZ', 'de', 'Kasachstan'),
        ('LB', 'de', 'Libanon'),
        ('LI', 'de', 'Liechtenstein'),
        ('LT', 'de', 'Litauen'),
        ('LU', 'de', 'Luxemburg'),
        ('LV', 'de', 'Lettland'),
        ('MA', 'de', 'Marokko'),
        ('MD', 'de', 'Moldau'),
        ('ME', 'de', 'Montenegro'),
        ('MK', 'de', 'Nordmazedonien'),
        ('MN', 'de', 'Mongolei'),
        ('MT', 'de', 'Malta'),
        ('NL', 'de', 'Niederlande'),
        ('NO', 'de', 'Norwegen'),
        ('OM', 'de', 'Oman'),
        ('PK', 'de', 'Pakistan'),
        ('PL', 'de', 'Polen'),
        ('PT', 'de', 'Portugal'),
        ('RO', 'de', 'Rumänien'),
        ('RS', 'de', 'Serbien'),
        ('RU', 'de', 'Russland'),
        ('SE', 'de', 'Schweden'),
        ('SI', 'de', 'Slowenien'),
        ('SK', 'de', 'Slowakei'),
        ('SY', 'de', 'Syrien'),
        ('TJ', 'de', 'Tadschikistan'),
        ('TM', 'de', 'Turkmenistan'),
        ('TN', 'de', 'Tunesien'),
        ('TR', 'de', 'Türkei'),
        ('UA', 'de', 'Ukraine'),
        ('UZ', 'de', 'Usbekistan')
      ) s (country_code, language_code, name)
ON (t.country_code = s.country_code AND t.language_code = s.language_code)
WHEN NOT MATCHED THEN INSERT (country_code, language_code, name)
VALUES (s.country_code, s.language_code, s.name);

COMMIT;
