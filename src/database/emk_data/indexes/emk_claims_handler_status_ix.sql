create index emk_data.emk_claims_handler_status_ix on
    emk_data.emk_claims (
        handler,
        status
    );


-- sqlcl_snapshot {"hash":"55418bd48f0f9ad902ad78690729b798525c50ad","type":"INDEX","name":"EMK_CLAIMS_HANDLER_STATUS_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIMS_HANDLER_STATUS_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIMS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>HANDLER</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>STATUS</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}