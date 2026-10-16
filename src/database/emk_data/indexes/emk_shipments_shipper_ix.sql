create index emk_data.emk_shipments_shipper_ix on
    emk_data.emk_shipments (
        shipper_id
    );


-- sqlcl_snapshot {"hash":"dc2c3015ce3ab6975c946dfc6aa348326d04bce3","type":"INDEX","name":"EMK_SHIPMENTS_SHIPPER_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_SHIPPER_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>SHIPPER_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}