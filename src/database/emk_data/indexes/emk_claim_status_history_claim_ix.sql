create index emk_data.emk_claim_status_history_claim_ix on
    emk_data.emk_claim_status_history (
        claim_id,
    sys_extract_utc(created_at) );


-- sqlcl_snapshot {"hash":"02db8cf308642a45e0dab9ac13cb720cf20833c4","type":"INDEX","name":"EMK_CLAIM_STATUS_HISTORY_CLAIM_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIM_STATUS_HISTORY_CLAIM_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIM_STATUS_HISTORY</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <DEFAULT_EXPRESSION>SYS_EXTRACT_UTC(\"CREATED_AT\")</DEFAULT_EXPRESSION>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}