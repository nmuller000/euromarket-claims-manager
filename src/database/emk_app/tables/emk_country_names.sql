create table emk_app.emk_country_names (
    country_code  char(2 char) not null enable,
    language_code char(2 char) not null enable,
    name          varchar2(100 char) not null enable,
    created_at    timestamp(6) with time zone default on null systimestamp not null enable,
    created_by    varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at    timestamp(6) with time zone,
    updated_by    varchar2(255 char)
);

alter table emk_app.emk_country_names
    add constraint emk_country_names_lang_ck
        check ( regexp_like ( language_code,
                              '^[abcdefghijklmnopqrstuvwxyz]{2}$',
                              'c' )
                and language_code <> 'en' ) enable;

alter table emk_app.emk_country_names
    add constraint emk_country_names_pk primary key ( country_code,
                                                      language_code )
        using index enable;


-- sqlcl_snapshot {"hash":"d5c782bb7b969dc04b605da2a0b7b6e320e2b929","type":"TABLE","name":"EMK_COUNTRY_NAMES","schemaName":"EMK_APP","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_COUNTRY_NAMES</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>COUNTRY_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>2</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>LANGUAGE_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>2</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>NAME</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>100</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                                SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                                SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_COUNTRY_NAMES_LANG_CK</NAME>\n            <CONDITION>REGEXP_LIKE(language_code, '^[abcdefghijklmnopqrstuvwxyz]{2}$', 'c') AND language_code &#60;> 'en'</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_COUNTRY_NAMES_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>COUNTRY_CODE</NAME>\n               </COL_LIST_ITEM>\n               <COL_LIST_ITEM>\n                  <NAME>LANGUAGE_CODE</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}