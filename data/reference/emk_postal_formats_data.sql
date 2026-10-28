-- =============================================================================
-- emk_postal_formats_data.sql
-- EMK_POSTAL_FORMATS: the postcode rule of each of the 60 countries (D-89,
-- D-90): whether an address needs a postcode, the pattern of the postcode,
-- an example and, where the official format includes it, the prefix.
-- Source: UPU, Universal POST*CODE DataBase, "General Addressing Issues"
-- (lists of countries which require / do not require postal codes, Sep. 2025
-- and Aug. 2026; postcode format per country, Aug. 2026): of these 60
-- countries only Syria does not require postal codes.
-- Patterns: anchored, explicit character lists, never ranges such as [0-9]
-- (spec §1.3 Check constraints, P-20). Where the UPU format has an inner
-- space (Czechia 999 99, Netherlands 9999 AA, United Kingdom, Ireland,
-- Malta…) the space is optional: many users leave it out. Hyphens are part of
-- the format (Poland 99-999, Portugal 9999-999). Alternatives listed by the
-- UPU are all accepted (Netherlands, Iran, Kazakhstan, Lebanon, Serbia,
-- Mongolia). The prefix (LV-, LT-, HR-, CY-, MD-, L-, AZ) is part of the
-- official postcode: EMK_PARTY_API adds it when a user types only the
-- digits. A unit test checks that each example follows its pattern.
-- Whether a postcode exists is not checked (national postal databases,
-- often licensed: out of scope, M1 plan §2).
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
-- Since:  2026-10-28 (M1a step 7.8, D-90)
-- =============================================================================

MERGE INTO emk_data.emk_postal_formats t
USING (VALUES
        ('AF', 'Y', NULL, '^[0123456789]{4}$', '1001'),
        ('AL', 'Y', NULL, '^[0123456789]{4}$', '1001'),
        ('AM', 'Y', NULL, '^[0123456789]{4}$', '0010'),
        ('AT', 'Y', NULL, '^[0123456789]{4}$', '1010'),
        ('AZ', 'Y', 'AZ', '^AZ[0123456789]{4}$', 'AZ1000'),
        ('BA', 'Y', NULL, '^[0123456789]{5}$', '71000'),
        ('BE', 'Y', NULL, '^[0123456789]{4}$', '1000'),
        ('BG', 'Y', NULL, '^[0123456789]{4}$', '1000'),
        ('BY', 'Y', NULL, '^[0123456789]{6}$', '220050'),
        ('CH', 'Y', NULL, '^[0123456789]{4}$', '8001'),
        ('CY', 'Y', 'CY-', '^CY-[0123456789]{4}$', 'CY-1010'),
        ('CZ', 'Y', NULL, '^[0123456789]{3} ?[0123456789]{2}$', '110 00'),
        ('DE', 'Y', NULL, '^[0123456789]{5}$', '10115'),
        ('DK', 'Y', NULL, '^[0123456789]{4}$', '1050'),
        ('EE', 'Y', NULL, '^[0123456789]{5}$', '10111'),
        ('ES', 'Y', NULL, '^[0123456789]{5}$', '28001'),
        ('FI', 'Y', NULL, '^[0123456789]{5}$', '00100'),
        ('FR', 'Y', NULL, '^[0123456789]{5}$', '75001'),
        ('GB', 'Y', NULL, '^[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{1,2}[0123456789][0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]? ?[0123456789][ABCDEFGHIJKLMNOPQRSTUVWXYZ]{2}$', 'SW1A 1AA'),
        ('GE', 'Y', NULL, '^[0123456789]{4}$', '0108'),
        ('GR', 'Y', NULL, '^[0123456789]{3} ?[0123456789]{2}$', '105 57'),
        ('HR', 'Y', 'HR-', '^HR-[0123456789]{5}$', 'HR-10000'),
        ('HU', 'Y', NULL, '^[0123456789]{4}$', '1051'),
        ('IE', 'Y', NULL, '^[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{3} ?[0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ]{4}$', 'A65 F4E2'),
        ('IR', 'Y', NULL, '^([0123456789]{6}|[0123456789]{10})$', '1193653471'),
        ('IS', 'Y', NULL, '^[0123456789]{3}$', '101'),
        ('IT', 'Y', NULL, '^[0123456789]{5}$', '00184'),
        ('JO', 'Y', NULL, '^[0123456789]{5}$', '11118'),
        ('KG', 'Y', NULL, '^[0123456789]{6}$', '720001'),
        ('KZ', 'Y', NULL, '^([0123456789]{6}|[ABCDEFGHIJKLMNOPQRSTUVWXYZ][0123456789]{2}[ABCDEFGHIJKLMNOPQRSTUVWXYZ][0123456789][ABCDEFGHIJKLMNOPQRSTUVWXYZ][0123456789])$', '050000'),
        ('LB', 'Y', NULL, '^([0123456789]{4}|[0123456789]{2} ?[0123456789]{3} ?[0123456789]{3})$', '1103'),
        ('LI', 'Y', NULL, '^[0123456789]{4}$', '9490'),
        ('LT', 'Y', 'LT-', '^LT-[0123456789]{5}$', 'LT-01100'),
        ('LU', 'Y', 'L-', '^L-[0123456789]{4}$', 'L-1009'),
        ('LV', 'Y', 'LV-', '^LV-[0123456789]{4}$', 'LV-1050'),
        ('MA', 'Y', NULL, '^[0123456789]{5}$', '10000'),
        ('MD', 'Y', 'MD-', '^MD-[0123456789]{4}$', 'MD-2001'),
        ('ME', 'Y', NULL, '^[0123456789]{5}$', '81000'),
        ('MK', 'Y', NULL, '^[0123456789]{4}$', '1000'),
        ('MN', 'Y', NULL, '^[0123456789]{5}(-[0123456789]{4})?$', '15160'),
        ('MT', 'Y', NULL, '^[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{3} ?[0123456789]{4}$', 'VLT 1117'),
        ('NL', 'Y', NULL, '^[123456789][0123456789]{3}( ?[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{2})?$', '1012 AB'),
        ('NO', 'Y', NULL, '^[0123456789]{4}$', '0150'),
        ('OM', 'Y', NULL, '^[0123456789]{3}$', '113'),
        ('PK', 'Y', NULL, '^[0123456789]{5}$', '44000'),
        ('PL', 'Y', NULL, '^[0123456789]{2}-[0123456789]{3}$', '00-950'),
        ('PT', 'Y', NULL, '^[0123456789]{4}-[0123456789]{3}$', '1000-001'),
        ('RO', 'Y', NULL, '^[0123456789]{6}$', '010011'),
        ('RS', 'Y', NULL, '^[0123456789]{5,6}$', '11000'),
        ('RU', 'Y', NULL, '^[0123456789]{6}$', '101000'),
        ('SE', 'Y', NULL, '^[0123456789]{3} ?[0123456789]{2}$', '114 55'),
        ('SI', 'Y', NULL, '^[0123456789]{4}$', '1000'),
        ('SK', 'Y', NULL, '^[0123456789]{3} ?[0123456789]{2}$', '811 01'),
        ('SY', 'N', NULL, NULL, NULL),
        ('TJ', 'Y', NULL, '^[0123456789]{6}$', '734000'),
        ('TM', 'Y', NULL, '^[0123456789]{6}$', '744000'),
        ('TN', 'Y', NULL, '^[0123456789]{4}$', '1000'),
        ('TR', 'Y', NULL, '^[0123456789]{5}$', '06100'),
        ('UA', 'Y', NULL, '^[0123456789]{5}$', '01001'),
        ('UZ', 'Y', NULL, '^[0123456789]{6}$', '100000')
      ) s (country_code, postal_code_required_yn, postal_code_prefix, postal_code_format, postal_code_example)
ON (t.country_code = s.country_code)
WHEN NOT MATCHED THEN INSERT
    (country_code, postal_code_required_yn, postal_code_prefix, postal_code_format, postal_code_example)
VALUES
    (s.country_code, s.postal_code_required_yn, s.postal_code_prefix, s.postal_code_format, s.postal_code_example);

COMMIT;
