create table emk_data.emk_party_roles (
    party_id   number not null enable,
    role_code  varchar2(20 char) not null enable,
    created_at timestamp(6) with time zone default on null systimestamp not null enable,
    created_by varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable
);

alter table emk_data.emk_party_roles
    add constraint emk_party_roles_pk primary key ( party_id,
                                                    role_code )
        using index enable;

alter table emk_data.emk_party_roles
    add constraint emk_party_roles_role_ck
        check ( role_code in ( 'SHIPPER', 'CONSIGNEE', 'CARRIER', 'FORWARDER', 'INSURER',
                               'SURVEYOR' ) ) enable;


-- sqlcl_snapshot {"hash":"2bdd00bc040ea0d15876b4a25f8ab089376534ee","type":"TABLE","name":"EMK_PARTY_ROLES","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_PARTY_ROLES</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>PARTY_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>ROLE_CODE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>20</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                             SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                             SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_PARTY_ROLES_ROLE_CK</NAME>\n            <CONDITION>role_code IN ('SHIPPER', 'CONSIGNEE', 'CARRIER',\n                                                               'FORWARDER', 'INSURER', 'SURVEYOR')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_PARTY_ROLES_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>PARTY_ID</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>ROLE_CODE</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}