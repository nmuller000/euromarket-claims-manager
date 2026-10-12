comment on table emk_app.emk_party_roles is
    'Roles of a company (party-role pattern; BR-16); a role change is a DELETE plus an INSERT, recorded in EMK_PARTY_ROLES_JN';

comment on column emk_app.emk_party_roles.role_code is
    'SHIPPER, CONSIGNEE, CARRIER, FORWARDER, INSURER or SURVEYOR (UN/EDIFACT 3035: CZ, CN, CA, FW)';


-- sqlcl_snapshot {"hash":"a96211d2370ccdc8deb926569c37bcea2bbf49fa","type":"COMMENT","name":"emk_party_roles","schemaName":"emk_app","sxml":""}