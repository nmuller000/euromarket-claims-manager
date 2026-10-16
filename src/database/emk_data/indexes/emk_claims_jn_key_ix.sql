create index emk_data.emk_claims_jn_key_ix on
    emk_data.emk_claims_jn (
        claim_id,
    sys_extract_utc(jn_at) )
        local ( partition p_initial nocompress );


-- sqlcl_snapshot {"hash":"169c7d7c8cf640cba7c14185593a3fab8650eac3","type":"INDEX","name":"EMK_CLAIMS_JN_KEY_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIMS_JN_KEY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIMS_JN</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <DEFAULT_EXPRESSION>SYS_EXTRACT_UTC(\"JN_AT\")</DEFAULT_EXPRESSION>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n      <LOCAL_PARTITIONING>\n         <PARTITION_LIST>\n            <PARTITION_LIST_ITEM>\n               <NAME>P_INITIAL</NAME>\n            </PARTITION_LIST_ITEM>\n            <PARTITION_LIST_ITEM>\n               <NAME>SYS_P8353</NAME>\n            </PARTITION_LIST_ITEM>\n         </PARTITION_LIST>\n      </LOCAL_PARTITIONING>\n   </TABLE_INDEX>\n</INDEX>"}