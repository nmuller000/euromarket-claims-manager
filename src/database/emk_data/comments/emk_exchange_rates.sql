comment on table emk_data.emk_exchange_rates is
    'Daily ECB reference rates (units of the currency per 1 EUR); BR-12 uses the latest rate on or before the business date';

comment on column emk_data.emk_exchange_rates.currency_code is
    'ISO 4217 code; never EUR (the base, rate 1)';

comment on column emk_data.emk_exchange_rates.rate_date is
    'Business date of the rate (no time part)';

comment on column emk_data.emk_exchange_rates.source is
    'Origin of the rate; only ECB in Release 1';

comment on column emk_data.emk_exchange_rates.units_per_eur is
    'Units of the currency per 1 EUR (ECB publishes 4 decimals; 6 also hold fixed conversion rates)';


-- sqlcl_snapshot {"hash":"d4fa2c30fd3e13901567c042d80d2e0613865dc4","type":"COMMENT","name":"emk_exchange_rates","schemaName":"emk_data","sxml":""}