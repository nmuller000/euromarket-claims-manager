create index emk_app.emk_shipments_dest_ix on
    emk_app.emk_shipments (
        destination_country
    );


-- sqlcl_snapshot {"hash":"d5e4fed775be8de680263bd70e158d96973a11c2","type":"INDEX","name":"EMK_SHIPMENTS_DEST_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_SHIPMENTS_DEST_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>DESTINATION_COUNTRY</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}