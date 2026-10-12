create index emk_app.emk_contacts_party_ix on
    emk_app.emk_contacts (
        party_id
    );


-- sqlcl_snapshot {"hash":"b9080fa66b87d6720232918d000f7ec26ae2275a","type":"INDEX","name":"EMK_CONTACTS_PARTY_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_CONTACTS_PARTY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_CONTACTS</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>PARTY_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}