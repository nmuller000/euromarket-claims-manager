create table emk_data.emk_claims (
    claim_id               number generated always as identity not null enable,
    claim_no               varchar2(15 char) not null enable,
    shipment_id            number not null enable,
    claim_type             varchar2(20 char) not null enable,
    damage_apparent_yn     char(1 char),
    status                 varchar2(20 char) default on null 'DRAFT' not null enable,
    handler                varchar2(255 char),
    registration_date      date default on null trunc(sysdate) not null enable,
    joint_check_date       date,
    reservation_date       date,
    written_claim_date     date,
    carrier_rejection_date date,
    weight_short_kg        number(12, 3),
    claimed_amount         number(14, 2),
    settled_amount         number(14, 2),
    recovered_amount       number(14, 2),
    currency_code          char(3 char),
    description            varchar2(1000 char),
    created_at             timestamp(6) with time zone default on null systimestamp not null enable,
    created_by             varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at             timestamp(6) with time zone,
    updated_by             varchar2(255 char),
    deleted_yn             char(1 char) default on null 'N' not null enable,
    deleted_by             varchar2(255 char),
    deleted_at             timestamp(6) with time zone
);

alter table emk_data.emk_claims
    add constraint emk_claims_amounts_ck
        check ( ( claimed_amount is null
                  or claimed_amount >= 0 )
                and ( settled_amount is null
                      or ( claimed_amount is not null
                           and settled_amount between 0 and claimed_amount ) )
                and ( recovered_amount is null
                      or ( settled_amount is not null
                           and recovered_amount between 0 and settled_amount ) ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_apparent_ck
        check ( ( claim_type in ( 'PARTIAL_LOSS', 'DAMAGE' )
                  and damage_apparent_yn is not null
                  and damage_apparent_yn in ( 'Y', 'N' ) )
                or ( claim_type in ( 'TOTAL_LOSS', 'DELAY' )
                     and damage_apparent_yn is null ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_claim_no_ck
        check ( regexp_like ( claim_no,
                              '^CLM-[0123456789]{4}-[0123456789]{6}$',
                              'c' ) ) enable;

alter table emk_data.emk_claims add constraint emk_claims_claim_no_uk unique ( claim_no )
    using index enable;

alter table emk_data.emk_claims
    add constraint emk_claims_currency_ck
        check ( currency_code is not null
                or ( claimed_amount is null
                     and settled_amount is null
                     and recovered_amount is null ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_day_ck
        check ( registration_date = trunc(registration_date)
                and ( joint_check_date is null
                      or joint_check_date = trunc(joint_check_date) )
                and ( reservation_date is null
                      or reservation_date = trunc(reservation_date) )
                and ( written_claim_date is null
                      or written_claim_date = trunc(written_claim_date) )
                and ( carrier_rejection_date is null
                      or carrier_rejection_date = trunc(carrier_rejection_date) ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_deleted_ck
        check ( ( deleted_yn = 'N'
                  and deleted_at is null
                  and deleted_by is null )
                or ( deleted_yn = 'Y'
                     and deleted_at is not null
                     and deleted_by is not null ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_deleted_yn_ck
        check ( deleted_yn in ( 'Y', 'N' ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_pk primary key ( claim_id )
        using index enable;

alter table emk_data.emk_claims
    add constraint emk_claims_rejection_ck
        check ( carrier_rejection_date is null
                or ( written_claim_date is not null
                     and carrier_rejection_date >= written_claim_date ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_status_ck
        check ( status in ( 'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION', 'RESOLVED',
                            'REJECTED', 'ESCALATED' ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_type_ck
        check ( claim_type in ( 'TOTAL_LOSS', 'PARTIAL_LOSS', 'DAMAGE', 'DELAY' ) ) enable;

alter table emk_data.emk_claims
    add constraint emk_claims_weight_ck
        check ( weight_short_kg is null
                or weight_short_kg > 0 ) enable;


-- sqlcl_snapshot {"hash":"f7aab958e3c6aed26d60f9807fe05518d6735b70","type":"TABLE","name":"EMK_CLAIMS","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIMS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <IDENTITY_COLUMN>\n               <SCHEMA>EMK_DATA</SCHEMA>\n               \n            </IDENTITY_COLUMN>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_NO</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>15</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>SHIPMENT_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_TYPE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DAMAGE_APPARENT_YN</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>STATUS</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'DRAFT'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>HANDLER</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>REGISTRATION_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            <DEFAULT_ON_NULL>TRUNC(SYSDATE)</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>JOINT_CHECK_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>RESERVATION_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>WRITTEN_CLAIM_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CARRIER_REJECTION_DATE</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>WEIGHT_SHORT_KG</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>12</PRECISION>\n            <SCALE>3</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CLAIMED_AMOUNT</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>14</PRECISION>\n            <SCALE>2</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>SETTLED_AMOUNT</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>14</PRECISION>\n            <SCALE>2</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>RECOVERED_AMOUNT</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>14</PRECISION>\n            <SCALE>2</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>3</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DESCRIPTION</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>1000</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                                         SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                                         SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_YN</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'N'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_CLAIM_NO_CK</NAME>\n            <CONDITION>REGEXP_LIKE(claim_no, '^CLM-[0123456789]{4}-[0123456789]{6}$', 'c')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_DELETED_YN_CK</NAME>\n            <CONDITION>deleted_yn IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_REJECTION_CK</NAME>\n            <CONDITION>carrier_rejection_date IS NULL\n                                          OR (written_claim_date IS NOT NULL AND carrier_rejection_date >= written_claim_date)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_DELETED_CK</NAME>\n            <CONDITION>(deleted_yn = 'N' AND deleted_at IS NULL AND deleted_by IS NULL)\n                                            OR (deleted_yn = 'Y' AND deleted_at IS NOT NULL AND deleted_by IS NOT NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_CURRENCY_CK</NAME>\n            <CONDITION>currency_code IS NOT NULL\n                                          OR (claimed_amount IS NULL AND settled_amount IS NULL AND recovered_amount IS NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_TYPE_CK</NAME>\n            <CONDITION>claim_type IN ('TOTAL_LOSS', 'PARTIAL_LOSS', 'DAMAGE', 'DELAY')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_DAY_CK</NAME>\n            <CONDITION>registration_date = TRUNC(registration_date)\n                                          AND (joint_check_date IS NULL OR joint_check_date = TRUNC(joint_check_date))\n                                          AND (reservation_date IS NULL OR reservation_date = TRUNC(reservation_date))\n                                          AND (written_claim_date IS NULL OR written_claim_date = TRUNC(written_claim_date))\n                                          AND (carrier_rejection_date IS NULL OR carrier_rejection_date = TRUNC(carrier_rejection_date))</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_APPARENT_CK</NAME>\n            <CONDITION>(claim_type IN ('PARTIAL_LOSS', 'DAMAGE') AND damage_apparent_yn IS NOT NULL AND damage_apparent_yn IN ('Y', 'N'))\n        OR (claim_type IN ('TOTAL_LOSS', 'DELAY') AND damage_apparent_yn IS NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_AMOUNTS_CK</NAME>\n            <CONDITION>(claimed_amount IS NULL OR claimed_amount >= 0)\n                                          AND (settled_amount IS NULL\n                                               OR (claimed_amount IS NOT NULL AND settled_amount BETWEEN 0 AND claimed_amount))\n                                          AND (recovered_amount IS NULL\n                                               OR (settled_amount IS NOT NULL AND recovered_amount BETWEEN 0 AND settled_amount))</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_STATUS_CK</NAME>\n            <CONDITION>status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION',\n                                                        'RESOLVED', 'REJECTED', 'ESCALATED')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_WEIGHT_CK</NAME>\n            <CONDITION>weight_short_kg IS NULL OR weight_short_kg > 0</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>CLAIM_ID</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <UNIQUE_KEY_CONSTRAINT_LIST>\n         <UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIMS_CLAIM_NO_UK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>CLAIM_NO</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </UNIQUE_KEY_CONSTRAINT_LIST_ITEM>\n      </UNIQUE_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}