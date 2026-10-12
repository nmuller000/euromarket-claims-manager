create index emk_app.emk_claims_currency_ix on
    emk_app.emk_claims (
        currency_code
    );


-- sqlcl_snapshot {"hash":"b50efc4770445e63049fa7bbc70c001facbfda31","type":"INDEX","name":"EMK_CLAIMS_CURRENCY_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_CLAIMS_CURRENCY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_CLAIMS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}