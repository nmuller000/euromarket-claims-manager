create index emk_data.emk_shipments_jn_key_ix on
    emk_data.emk_shipments_jn (
        shipment_id,
    sys_extract_utc(jn_at) )
        local ( partition p_initial nocompress );


-- sqlcl_snapshot {"hash":"86f7a797c3cd374868c7afb2e6bf3fb6913ef36d","type":"INDEX","name":"EMK_SHIPMENTS_JN_KEY_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_JN_KEY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS_JN</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>SHIPMENT_ID</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <DEFAULT_EXPRESSION>SYS_EXTRACT_UTC(\"JN_AT\")</DEFAULT_EXPRESSION>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n      <LOCAL_PARTITIONING>\n         <PARTITION_LIST>\n            <PARTITION_LIST_ITEM>\n               <NAME>P_INITIAL</NAME>\n            </PARTITION_LIST_ITEM>\n            <PARTITION_LIST_ITEM>\n               <NAME>SYS_P8339</NAME>\n            </PARTITION_LIST_ITEM>\n         </PARTITION_LIST>\n      </LOCAL_PARTITIONING>\n   </TABLE_INDEX>\n</INDEX>"}