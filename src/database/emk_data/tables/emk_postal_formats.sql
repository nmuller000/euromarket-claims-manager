create table emk_data.emk_postal_formats (
    country_code            char(2 char) not null enable,
    postal_code_required_yn char(1 char) default on null 'Y' not null enable,
    postal_code_prefix      varchar2(3 char),
    postal_code_format      varchar2(200 char),
    postal_code_example     varchar2(10 char),
    valid_from              date default on null date '1900-01-01' not null enable,
    valid_to                date,
    created_at              timestamp(6) with time zone default on null systimestamp not null enable,
    created_by              varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at              timestamp(6) with time zone,
    updated_by              varchar2(255 char)
);

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_example_ck
        check ( ( postal_code_format is null
                  and postal_code_example is null )
                or ( postal_code_format is not null
                     and postal_code_example is not null ) ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_format_ck
        check ( postal_code_format is null
                or regexp_like ( postal_code_format,
                                 '^\^.+\$$',
                                 'c' ) ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_none_ck
        check ( postal_code_required_yn = 'Y'
                or postal_code_format is null ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_pk primary key ( country_code )
        using index enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_prefix_ck
        check ( postal_code_prefix is null
                or regexp_like ( postal_code_prefix,
                                 '^[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{1,2}-?$',
                                 'c' ) ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_required_ck
        check ( postal_code_required_yn in ( 'Y', 'N' ) ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_valid_ck
        check ( valid_to is null
                or valid_to >= valid_from ) enable;

alter table emk_data.emk_postal_formats
    add constraint emk_postal_formats_with_prefix_ck
        check ( postal_code_prefix is null
                or postal_code_format is not null ) enable;


-- sqlcl_snapshot {"hash":"9c5e76175e02359b057b3375872d37f1084aebbc","type":"TABLE","name":"EMK_POSTAL_FORMATS","schemaName":"EMK_DATA","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_POSTAL_FORMATS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>COUNTRY_CODE</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>2</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>POSTAL_CODE_REQUIRED_YN</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'Y'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>POSTAL_CODE_PREFIX</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>3</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>POSTAL_CODE_FORMAT</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>200</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>POSTAL_CODE_EXAMPLE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>10</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>VALID_FROM</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            <DEFAULT_ON_NULL>date '1900-01-01'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>VALID_TO</NAME>\n            <DATATYPE>DATE</DATATYPE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>systimestamp</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>coalesce(sys_context('APEX$SESSION', 'APP_USER'),\n                                         sys_context('USERENV', 'PROXY_USER'),\n                                         sys_context('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_REQUIRED_CK</NAME>\n            <CONDITION>postal_code_required_yn in ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_FORMAT_CK</NAME>\n            <CONDITION>postal_code_format is null\n                                                      or regexp_like(postal_code_format, '^\\^.+\\$$', 'c')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_PREFIX_CK</NAME>\n            <CONDITION>postal_code_prefix is null\n                                                      or regexp_like(postal_code_prefix, '^[ABCDEFGHIJKLMNOPQRSTUVWXYZ]{1,2}-?$', 'c')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_EXAMPLE_CK</NAME>\n            <CONDITION>(postal_code_format is null and postal_code_example is null)\n                                                      or (postal_code_format is not null and postal_code_example is not null)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_WITH_PREFIX_CK</NAME>\n            <CONDITION>postal_code_prefix is null or postal_code_format is not null</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_NONE_CK</NAME>\n            <CONDITION>postal_code_required_yn = 'Y' or postal_code_format is null</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_VALID_CK</NAME>\n            <CONDITION>valid_to is null or valid_to >= valid_from</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_POSTAL_FORMATS_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>COUNTRY_CODE</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}