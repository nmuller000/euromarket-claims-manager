create index emk_data.emk_shipments_dest_ix on
    emk_data.emk_shipments (
        destination_country
    );


-- sqlcl_snapshot {"hash":"96b09ec6da8a5146b951aebf82bbc3e9548b17b8","type":"INDEX","name":"EMK_SHIPMENTS_DEST_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_DEST_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>DESTINATION_COUNTRY</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}