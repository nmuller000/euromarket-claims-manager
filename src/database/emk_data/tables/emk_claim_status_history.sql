create table emk_data.emk_claim_status_history (
    history_id  number generated always as identity not null enable,
    claim_id    number not null enable,
    from_status varchar2(20 char),
    to_status   varchar2(20 char) not null enable,
    reason      varchar2(1000 char),
    created_at  timestamp(6) with time zone default on null systimestamp not null enable,
    created_by  varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable
);

alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_from_ck
        check ( from_status is null
                or from_status in ( 'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION', 'RESOLVED',
                                    'REJECTED', 'ESCALATED' ) ) enable;

alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_pk primary key ( history_id )
        using index enable;

alter table emk_data.emk_claim_status_history
    add constraint emk_claim_status_history_to_ck
        check ( to_status in ( 'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION', 'RESOLVED',
                               'REJECTED', 'ESCALATED' ) ) enable;


-- sqlcl_snapshot {"hash":"eb7cc6207a8301fbb95f291d24cb5b83201f606d","type":"TABLE","name":"EMK_CLAIM_STATUS_HISTORY","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIM_STATUS_HISTORY</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>HISTORY_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <IDENTITY_COLUMN>\n               <SCHEMA>EMK_DATA</SCHEMA>\n               \n            </IDENTITY_COLUMN>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>FROM_STATUS</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>TO_STATUS</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>REASON</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>1000</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                              SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                              SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_STATUS_HISTORY_TO_CK</NAME>\n            <CONDITION>to_status IN\n                                                        ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION',\n                                                         'RESOLVED', 'REJECTED', 'ESCALATED')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_STATUS_HISTORY_FROM_CK</NAME>\n            <CONDITION>from_status IS NULL OR from_status IN\n                                                        ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEGOTIATION',\n                                                         'RESOLVED', 'REJECTED', 'ESCALATED')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_STATUS_HISTORY_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>HISTORY_ID</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}