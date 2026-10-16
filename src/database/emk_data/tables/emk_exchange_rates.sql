create table emk_data.emk_exchange_rates (
    currency_code char(3 char) not null enable,
    rate_date     date not null enable,
    units_per_eur number(18, 6) not null enable,
    source        varchar2(10 char) default on null 'ECB' not null enable,
    created_at    timestamp(6) with time zone default on null systimestamp not null enable,
    created_by    varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at    timestamp(6) with time zone,
    updated_by    varchar2(255 char)
);

alter table emk_data.emk_exchange_rates
    add constraint emk_exchange_rates_day_ck check ( rate_date = trunc(rate_date) ) enable;

alter table emk_data.emk_exchange_rates
    add constraint emk_exchange_rates_not_eur_ck check ( currency_code <> 'EUR' ) enable;

alter table emk_data.emk_exchange_rates
    add constraint emk_exchange_rates_pk primary key ( currency_code,
                                                       rate_date )
        using index enable;

alter table emk_data.emk_exchange_rates add constraint emk_exchange_rates_rate_ck check ( units_per_eur > 0 ) enable;

alter table emk_data.emk_exchange_rates
    add constraint emk_exchange_rates_source_ck check ( source in ( 'ECB' ) ) enable;


-- sqlcl_snapshot {"hash":"d560ded9376b4779b3888d6fbab91430972b62da","type":"TABLE","name":"EMK_EXCHANGE_RATES","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_EXCHANGE_RATES</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>3</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>RATE_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UNITS_PER_EUR</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>18</PRECISION>\n            <SCALE>6</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>SOURCE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>10</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'ECB'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                                SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                                SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_EXCHANGE_RATES_NOT_EUR_CK</NAME>\n            <CONDITION>currency_code &#60;> 'EUR'</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_EXCHANGE_RATES_RATE_CK</NAME>\n            <CONDITION>units_per_eur > 0</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_EXCHANGE_RATES_DAY_CK</NAME>\n            <CONDITION>rate_date = TRUNC(rate_date)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_EXCHANGE_RATES_SOURCE_CK</NAME>\n            <CONDITION>source IN ('ECB')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_EXCHANGE_RATES_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>CURRENCY_CODE</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>RATE_DATE</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}