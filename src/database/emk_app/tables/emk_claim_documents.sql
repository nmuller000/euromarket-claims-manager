create table emk_app.emk_claim_documents (
    document_id    number generated always as identity not null enable,
    claim_id       number not null enable,
    doc_type       varchar2(30 char) not null enable,
    file_name      varchar2(255 char) not null enable,
    mime_type      varchar2(100 char) not null enable,
    file_size      number(10, 0) not null enable,
    content        blob not null enable,
    extracted_text clob,
    created_at     timestamp(6) with time zone default on null systimestamp not null enable,
    created_by     varchar2(255 char) default on null coalesce(
        sys_context('APEX$SESSION', 'APP_USER'),
        sys_context('USERENV', 'PROXY_USER'),
        sys_context('USERENV', 'SESSION_USER')
    ) not null enable,
    updated_at     timestamp(6) with time zone,
    updated_by     varchar2(255 char),
    deleted_yn     char(1 char) default on null 'N' not null enable,
    deleted_by     varchar2(255 char),
    deleted_at     timestamp(6) with time zone
);

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_deleted_ck
        check ( ( deleted_yn = 'N'
                  and deleted_at is null
                  and deleted_by is null )
                or ( deleted_yn = 'Y'
                     and deleted_at is not null
                     and deleted_by is not null ) ) enable;

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_deleted_yn_ck
        check ( deleted_yn in ( 'Y', 'N' ) ) enable;

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_mime_ck
        check ( mime_type in ( 'application/pdf', 'image/jpeg', 'image/png' ) ) enable;

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_pk primary key ( document_id )
        using index enable;

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_size_ck check ( file_size between 1 and 10485760 ) enable;

alter table emk_app.emk_claim_documents
    add constraint emk_claim_documents_type_ck
        check ( doc_type in ( 'CMR_NOTE', 'DAMAGE_REPORT', 'PHOTO', 'INVOICE', 'CORRESPONDENCE',
                              'OTHER' ) ) enable;


-- sqlcl_snapshot {"hash":"d81be36b6ea79aebcc24a47dc6ba186700007cf9","type":"TABLE","name":"EMK_CLAIM_DOCUMENTS","schemaName":"EMK_APP","sxml":"\n  <TABLE xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_CLAIM_DOCUMENTS</NAME>\n   <RELATIONAL_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>DOCUMENT_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <IDENTITY_COLUMN>\n               <SCHEMA>EMK_APP</SCHEMA>\n               \n            </IDENTITY_COLUMN>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DOC_TYPE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>30</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>FILE_NAME</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>MIME_TYPE</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>100</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>FILE_SIZE</NAME>\n            <DATATYPE>NUMBER</DATATYPE>\n            <PRECISION>10</PRECISION>\n            <SCALE>0</SCALE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CONTENT</NAME>\n            <DATATYPE>BLOB</DATATYPE>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>EXTRACTED_TEXT</NAME>\n            <DATATYPE>CLOB</DATATYPE>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            <DEFAULT_ON_NULL>SYSTIMESTAMP</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>CREATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>COALESCE(SYS_CONTEXT('APEX$SESSION', 'APP_USER'),\n                                 SYS_CONTEXT('USERENV', 'PROXY_USER'),\n                                 SYS_CONTEXT('USERENV', 'SESSION_USER'))</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>UPDATED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_YN</NAME>\n            <DATATYPE>CHAR</DATATYPE>\n            <LENGTH>1</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            <DEFAULT_ON_NULL>'N'</DEFAULT_ON_NULL>\n            <NOT_NULL></NOT_NULL>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_BY</NAME>\n            <DATATYPE>VARCHAR2</DATATYPE>\n            <LENGTH>255</LENGTH>\n            <CHAR_SEMANTICS></CHAR_SEMANTICS>\n            <COLLATE_NAME>USING_NLS_COMP</COLLATE_NAME>\n            \n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>DELETED_AT</NAME>\n            <DATATYPE>TIMESTAMP_WITH_TIMEZONE</DATATYPE>\n            <SCALE>6</SCALE>\n            \n         </COL_LIST_ITEM>\n      </COL_LIST>\n      <CHECK_CONSTRAINT_LIST>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_SIZE_CK</NAME>\n            <CONDITION>file_size BETWEEN 1 AND 10485760</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_DELETED_YN_CK</NAME>\n            <CONDITION>deleted_yn IN ('Y', 'N')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_DELETED_CK</NAME>\n            <CONDITION>(deleted_yn = 'N' AND deleted_at IS NULL AND deleted_by IS NULL)\n                                                     OR (deleted_yn = 'Y' AND deleted_at IS NOT NULL AND deleted_by IS NOT NULL)</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_TYPE_CK</NAME>\n            <CONDITION>doc_type IN ('CMR_NOTE', 'DAMAGE_REPORT', 'PHOTO',\n                                                                 'INVOICE', 'CORRESPONDENCE', 'OTHER')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n         <CHECK_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_MIME_CK</NAME>\n            <CONDITION>mime_type IN ('application/pdf', 'image/jpeg', 'image/png')</CONDITION>\n         </CHECK_CONSTRAINT_LIST_ITEM>\n      </CHECK_CONSTRAINT_LIST>\n      <PRIMARY_KEY_CONSTRAINT_LIST>\n         <PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n            <NAME>EMK_CLAIM_DOCUMENTS_PK</NAME>\n            <COL_LIST>\n               <COL_LIST_ITEM>\n                  <NAME>DOCUMENT_ID</NAME>\n               </COL_LIST_ITEM>\n            </COL_LIST>\n            <USING_INDEX></USING_INDEX>\n         </PRIMARY_KEY_CONSTRAINT_LIST_ITEM>\n      </PRIMARY_KEY_CONSTRAINT_LIST>\n      <DEFAULT_COLLATION>USING_NLS_COMP</DEFAULT_COLLATION>\n      <PHYSICAL_PROPERTIES>\n         <HEAP_TABLE></HEAP_TABLE>\n      </PHYSICAL_PROPERTIES>\n      \n   </RELATIONAL_TABLE>\n</TABLE>"}