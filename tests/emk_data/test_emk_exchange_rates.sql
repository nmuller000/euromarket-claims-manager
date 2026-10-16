create or replace package test_emk_exchange_rates as
    /**
     * Unit tests of EMK_EXCHANGE_RATES in EMK_DATA (M1a step 6, BR-12): one
     * ECB rate per currency and day, none for EUR, positive, date without time,
     * only known currencies. The API only reads this table (ADR-008): the
     * tests that insert rows live here, in the owner schema.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    --%suite(Exchange rates (EMK_DATA))
    --%suitepath(emk_data)

    --%beforeeach
    procedure insert_test_rate;

    --%test(A valid rate is stored with source ECB and the audit columns)
    procedure stores_valid_rate;

    --%test(One rate per currency and day)
    --%throws(-1)
    procedure rejects_second_rate_same_day;

    --%test(No rate for EUR)
    --%throws(-2290)
    procedure rejects_rate_for_eur;

    --%test(The rate must be positive)
    --%throws(-2290)
    procedure rejects_zero_rate;

    --%test(The rate date has no time)
    --%throws(-2290)
    procedure rejects_rate_date_with_time;

    --%test(Only known currencies (RUB is not in the list))
    --%throws(-2291)
    procedure rejects_unknown_currency;
end test_emk_exchange_rates;
/

create or replace package body test_emk_exchange_rates as

    c_rate_date constant date := date '2026-10-08';

    procedure insert_test_rate is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur) values ('USD', c_rate_date, 1.0912);
    end insert_test_rate;

    procedure stores_valid_rate is
        l_source     emk_exchange_rates.source%type;
        l_created_by emk_exchange_rates.created_by%type;
    begin
        select source, created_by
        into   l_source, l_created_by
        from   emk_exchange_rates
        where  currency_code = 'USD' and rate_date = c_rate_date;
        ut.expect(l_source).to_equal('ECB');
        ut.expect(l_created_by).to_be_not_null();
    end stores_valid_rate;

    procedure rejects_second_rate_same_day is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur) values ('USD', c_rate_date, 1.1);
    end rejects_second_rate_same_day;

    procedure rejects_rate_for_eur is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur) values ('EUR', c_rate_date, 1);
    end rejects_rate_for_eur;

    procedure rejects_zero_rate is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur) values ('GBP', c_rate_date, 0);
    end rejects_zero_rate;

    procedure rejects_rate_date_with_time is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur)
        values ('GBP', timestamp '2026-10-08 16:00:00', 0.86);
    end rejects_rate_date_with_time;

    procedure rejects_unknown_currency is
    begin
        insert into emk_exchange_rates (currency_code, rate_date, units_per_eur) values ('RUB', c_rate_date, 90);
    end rejects_unknown_currency;

end test_emk_exchange_rates;
/
