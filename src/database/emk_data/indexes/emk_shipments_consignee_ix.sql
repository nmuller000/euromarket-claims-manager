create index emk_data.emk_shipments_consignee_ix on
    emk_data.emk_shipments (
        consignee_id
    );


-- sqlcl_snapshot {"hash":"67471c0a7e6c0e1167167b444999c7a1e0d47eb6","type":"INDEX","name":"EMK_SHIPMENTS_CONSIGNEE_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_SHIPMENTS_CONSIGNEE_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CONSIGNEE_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}