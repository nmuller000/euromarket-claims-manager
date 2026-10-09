create index emk_app.emk_shipments_origin_ix on
    emk_app.emk_shipments (
        origin_country
    );


-- sqlcl_snapshot {"hash":"516899b7b6598b422e3fe8f27127fcf4f25ae50e","type":"INDEX","name":"EMK_SHIPMENTS_ORIGIN_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_SHIPMENTS_ORIGIN_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ORIGIN_COUNTRY</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}