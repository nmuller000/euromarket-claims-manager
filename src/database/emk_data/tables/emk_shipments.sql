create table emk_data.emk_shipments (
    shipment_id          number generated always as identity not null enable,
    cmr_note_no          varchar2(50 char) not null enable,
    shipper_id           number not null enable,
    carrier_id           number not null enable,
    consignee_id         number not null enable,
    pickup_place         varchar2(100 char) not null enable,
    origin_country       char(2 char) not null enable,
    delivery_place       varchar2(100 char) not null enable,
    destination_country  char(2 char) not null enable,
    pickup_date          date not null enable,
    agreed_delivery_date date,
    delivery_date        date,
    goods_description    varchar2(500 char) not null enable,
    packages             number(7, 0),
    gross_weight_kg      number(12, 3) not null enable,
    carriage_charges     number(14, 2),
    currency_code        char(3 char),
    created_at           timestamp(6) with time zone default on null systimestamp not null enable,
    created_by           varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at           timestamp(6) with time zone,
    updated_by           varchar2(255 char),
    deleted_yn           char(1 char) default on null 'N' not null enable,
    deleted_by           varchar2(255 char),
    deleted_at           timestamp(6) with time zone
);

alter table emk_data.emk_shipments
    add constraint emk_shipments_charges_ck
        check ( ( carriage_charges is null
                  and currency_code is null )
                or ( carriage_charges is not null
                     and carriage_charges >= 0
                     and currency_code is not null ) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_cmr_note_ck
        check ( cmr_note_no = upper(trim(cmr_note_no)) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_cmr_note_uk unique ( carrier_id,
                                                      cmr_note_no )
        using index enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_countries_ck check ( origin_country <> destination_country ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_dates_ck
        check ( ( delivery_date is null
                  or delivery_date >= pickup_date )
                and ( agreed_delivery_date is null
                      or agreed_delivery_date >= pickup_date ) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_day_ck
        check ( pickup_date = trunc(pickup_date)
                and ( delivery_date is null
                      or delivery_date = trunc(delivery_date) )
                and ( agreed_delivery_date is null
                      or agreed_delivery_date = trunc(agreed_delivery_date) ) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_deleted_ck
        check ( ( deleted_yn = 'N'
                  and deleted_at is null
                  and deleted_by is null )
                or ( deleted_yn = 'Y'
                     and deleted_at is not null
                     and deleted_by is not null ) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_deleted_yn_ck
        check ( deleted_yn in ( 'Y', 'N' ) ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_packages_ck
        check ( packages is null
                or packages > 0 ) enable;

alter table emk_data.emk_shipments
    add constraint emk_shipments_pk primary key ( shipment_id )
        using index enable;

alter table emk_data.emk_shipments add constraint emk_shipments_weight_ck check ( gross_weight_kg > 0 ) enable;


-- sqlcl_snapshot {"hash":"174983e8d2cdfa7a308be4a48199c8cfde8a011f","type":"TABLE","name":"EMK_SHIPMENTS","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>SHIPMENT_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <IDENTITY_COLUMN>\n               <SCHEMA>EMK_DATA</SCHEMA>\n               \n            </IDENTITY_COLUMN>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CMR_NOTE_NO</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>50</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>SHIPPER_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CARRIER_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CONSIGNEE_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>PICKUP_PLACE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>100</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>ORIGIN_COUNTRY</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>2</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELIVERY_PLACE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>100</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DESTINATION_COUNTRY</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>2</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>PICKUP_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>AGREED_DELIVERY_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELIVERY_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>GOODS_DESCRIPTION</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>500</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>PACKAGES</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>7</PRECISION>\n            <SCALE>0</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>GROSS_WEIGHT_KG</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>12</PRECISION>\n            <SCALE>3</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CARRIAGE_CHARGES</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>14</PRECISION>\n            <SCALE>2</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>3</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                                       SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                                       SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_YN</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'N'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_WEIGHT_CK</NAME>\n            <CONDITION>gross_weight_kg > 0</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_DATES_CK</NAME>\n            <CONDITION>(delivery_date IS NULL OR delivery_date >= pickup_date)\n                                             AND (agreed_delivery_date IS NULL OR agreed_delivery_date >= pickup_date)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_DAY_CK</NAME>\n            <CONDITION>pickup_date = TRUNC(pickup_date)\n                                             AND (delivery_date IS NULL OR delivery_date = TRUNC(delivery_date))\n                                             AND (agreed_delivery_date IS NULL OR agreed_delivery_date = TRUNC(agreed_delivery_date))</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_DELETED_YN_CK</NAME>\n            <CONDITION>deleted_yn IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_CHARGES_CK</NAME>\n            <CONDITION>(carriage_charges IS NULL AND currency_code IS NULL)\n        OR (carriage_charges IS NOT NULL AND carriage_charges >= 0 AND currency_code IS NOT NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_CMR_NOTE_CK</NAME>\n            <CONDITION>cmr_note_no = UPPER(TRIM(cmr_note_no))</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_PACKAGES_CK</NAME>\n            <CONDITION>packages IS NULL OR packages > 0</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_COUNTRIES_CK</NAME>\n            <CONDITION>origin_country &#60;> destination_country</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_DELETED_CK</NAME>\n            <CONDITION>(deleted_yn = 'N' AND deleted_at IS NULL AND deleted_by IS NULL)\n                                             OR (deleted_yn = 'Y' AND deleted_at IS NOT NULL AND deleted_by IS NOT NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>SHIPMENT_ID</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <UNIQUE_KEY_CONSTRAINT_LIST>\n         <UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_SHIPMENTS_CMR_NOTE_UK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>CARRIER_ID</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>CMR_NOTE_NO</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n      </UNIQUE_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}