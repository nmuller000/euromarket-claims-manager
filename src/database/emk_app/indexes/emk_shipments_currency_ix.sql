create index emk_app.emk_shipments_currency_ix on
    emk_app.emk_shipments (
        currency_code
    );


-- sqlcl_snapshot {"hash":"146ea13119850c76103189381dbbc92f53998ac1","type":"INDEX","name":"EMK_SHIPMENTS_CURRENCY_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_SHIPMENTS_CURRENCY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CURRENCY_CODE</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}