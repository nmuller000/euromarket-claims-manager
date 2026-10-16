comment on table emk_data.emk_party_roles is
    'Roles of a company (party-role pattern; BR-16); a role change is a DELETE plus an INSERT, recorded in EMK_PARTY_ROLES_JN';

comment on column emk_data.emk_party_roles.role_code is
    'SHIPPER, CONSIGNEE, CARRIER, FORWARDER, INSURER or SURVEYOR (UN/EDIFACT 3035: CZ, CN, CA, FW)';


-- sqlcl_snapshot {"hash":"fed042cf9f7bd03020334453fb8d377989fe00ca","type":"COMMENT","name":"emk_party_roles","schemaName":"emk_data","sxml":""}