create index emk_data.emk_claim_documents_jn_key_ix on
    emk_data.emk_claim_documents_jn (
        document_id,
    sys_extract_utc(jn_at) )
        local ( partition p_initial nocompress );


-- sqlcl_snapshot {"hash":"bb7f0191cb5e4755c7b985250939acfb135b7b41","type":"INDEX","name":"EMK_CLAIM_DOCUMENTS_JN_KEY_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIM_DOCUMENTS_JN_KEY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIM_DOCUMENTS_JN</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>DOCUMENT_ID</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <DEFAULT_EXPRESSION>SYS_EXTRACT_UTC(\"JN_AT\")</DEFAULT_EXPRESSION>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n      <LOCAL_PARTITIONING>\n         <PARTITION_LIST>\n            <PARTITION_LIST_ITEM>\n               <NAME>P_INITIAL</NAME>\n            </PARTITION_LIST_ITEM>\n            <PARTITION_LIST_ITEM>\n               <NAME>SYS_P8354</NAME>\n            </PARTITION_LIST_ITEM>\n         </PARTITION_LIST>\n      </LOCAL_PARTITIONING>\n   </TABLE_INDEX>\n</INDEX>"}