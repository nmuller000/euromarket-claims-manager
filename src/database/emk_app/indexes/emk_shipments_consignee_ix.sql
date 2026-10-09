create index emk_app.emk_shipments_consignee_ix on
    emk_app.emk_shipments (
        consignee_id
    );


-- sqlcl_snapshot {"hash":"e23f46a9a85a6fb07319ed06e692f95a62c4cc99","type":"INDEX","name":"EMK_SHIPMENTS_CONSIGNEE_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_SHIPMENTS_CONSIGNEE_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_SHIPMENTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>CONSIGNEE_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}