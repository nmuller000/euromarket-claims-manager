create index emk_data.emk_party_roles_role_ix on
    emk_data.emk_party_roles (
        role_code,
        party_id
    );


-- sqlcl_snapshot {"hash":"4f461b6e4517198d370399a95f3b478f81e39fa6","type":"INDEX","name":"EMK_PARTY_ROLES_ROLE_IX","schemaName":"EMK_DATA","sxml":"\n  <INDEX xmlns=\"http://xmlns.oracle.com/ku\" version=\"1.0\">\n   <SCHEMA>EMK_DATA</SCHEMA>\n   <NAME>EMK_PARTY_ROLES_ROLE_IX</NAME>\n   <TABLE_INDEX>\n      <ON_TABLE>\n         <SCHEMA>EMK_DATA</SCHEMA>\n         <NAME>EMK_PARTY_ROLES</NAME>\n      </ON_TABLE>\n      <COL_LIST>\n         <COL_LIST_ITEM>\n            <NAME>ROLE_CODE</NAME>\n         </COL_LIST_ITEM>\n         <COL_LIST_ITEM>\n            <NAME>PARTY_ID</NAME>\n         </COL_LIST_ITEM>\n      </COL_LIST>\n      \n   </TABLE_INDEX>\n</INDEX>"}