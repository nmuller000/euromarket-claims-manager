create index emk_data.emk_contacts_party_ix on
    emk_data.emk_contacts (
        party_id
    );


-- sqlcl_snapshot {"hash":"71538b9538a567be550386aa96357dfafebc0f4d","type":"INDEX","name":"EMK_CONTACTS_PARTY_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_CONTACTS_PARTY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_CONTACTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>PARTY_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}