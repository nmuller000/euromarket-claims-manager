create index emk_app.emk_parties_country_ix on
    emk_app.emk_parties (
        country_code
    );


-- sqlcl_snapshot {"hash":"5ab2ff795653a2327954f30691c1c95dc0c209be","type":"INDEX","name":"EMK_PARTIES_COUNTRY_IX","schemaName":"EMK_APP","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_APP</SCHEMA>\n   <NAME>EMK_PARTIES_COUNTRY_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_APP</SCHEMA>\n         <NAME>EMK_PARTIES</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>COUNTRY_CODE</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}