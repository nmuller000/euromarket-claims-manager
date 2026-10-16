create index emk_data.emk_shipments_origin_ix on
    emk_data.emk_shipments (
        origin_country
    );


-- sqlcl_snapshot {"hash":"1cab43008b0e4cbea32d6434d750f0a67a52635c","type":"INDEX","name":"EMK_SHIPMENTS_ORIGIN_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_ORIGIN_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ORIGIN_COUNTRY</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}