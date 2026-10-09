create index emk_app.emk_shipments_shipper_ix on
    emk_app.emk_shipments (
        shipper_id
    );


-- sqlcl_snapshot {"hash":"30a2b02e4dac8fc8b9a659da4e9912d2f662b8f8","type":"INDEX","name":"EMK_SHIPMENTS_SHIPPER_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_SHIPMENTS_SHIPPER_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>SHIPPER_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}