create index emk_data.emk_shipments_currency_ix on
    emk_data.emk_shipments (
        currency_code
    );


-- sqlcl_snapshot {"hash":"eedbd217887065a6ed1784f119e27e1265eacf35","type":"INDEX","name":"EMK_SHIPMENTS_CURRENCY_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_CURRENCY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}