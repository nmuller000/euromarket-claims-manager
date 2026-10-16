create index emk_data.emk_claims_shipment_ix on
    emk_data.emk_claims (
        shipment_id
    );


-- sqlcl_snapshot {"hash":"ae910aef2665fdad3811f985e0e3ee23e73a23b6","type":"INDEX","name":"EMK_CLAIMS_SHIPMENT_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CLAIMS_SHIPMENT_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CLAIMS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>SHIPMENT_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}