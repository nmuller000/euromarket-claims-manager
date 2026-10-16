create index emk_data.emk_claim_documents_claim_ix on
    emk_data.emk_claim_documents (
        claim_id
    );


-- sqlcl_snapshot {"hash":"ddb4696954c30933cb7605673de1548290d6a680","type":"INDEX","name":"EMK_CLAIM_DOCUMENTS_CLAIM_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIM_DOCUMENTS_CLAIM_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIM_DOCUMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CLAIM_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}