comment on table emk_app.emk_currencies is
    'EUR, currencies with an ECB reference rate, and historic HRK and BGN (ISO 4217); RUB excluded (no ECB rate since 2022-03-01)';

comment on column emk_app.emk_currencies.currency_code is
    'ISO 4217 alphabetic code';

comment on column emk_app.emk_currencies.ecb_rate_yn is
    'Y = the ECB publishes (or published) a reference rate; EUR is the base and has none';

comment on column emk_app.emk_currencies.iso_name is
    'ISO 4217 currency name (SIX lists)';

comment on column emk_app.emk_currencies.minor_units is
    'ISO 4217 decimals used to round converted amounts';

comment on column emk_app.emk_currencies.name is
    'English display name from the EU authority table Currencies';

comment on column emk_app.emk_currencies.valid_from is
    'Start of validity';

comment on column emk_app.emk_currencies.valid_to is
    'End of validity (HRK 2022-12-31, BGN 2025-12-31); NULL = still valid';


-- sqlcl_snapshot {"hash":"a3504746003d53c8bdbed51d59aba2b9bb4400c9","type":"COMMENT","name":"emk_currencies","schemaName":"emk_app","sxml":""}