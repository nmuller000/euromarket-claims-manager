comment on table emk_data.emk_party_role_types is
    'Roles a company can play (BR-16); a code list with validity, maintained by the administrator (D-68). The roles named in EMK_CODES_PKG cannot be retired'
    ;

comment on column emk_data.emk_party_role_types.description is
    'Meaning of the role';

comment on column emk_data.emk_party_role_types.name is
    'English display name';

comment on column emk_data.emk_party_role_types.role_code is
    'Role code, upper case (UN/EDIFACT 3035: CZ, CN, CA, FW)';

comment on column emk_data.emk_party_role_types.sort_order is
    'Position in lists';

comment on column emk_data.emk_party_role_types.valid_from is
    'Start of validity';

comment on column emk_data.emk_party_role_types.valid_to is
    'End of validity; NULL = still valid. Companies keep a retired role; it cannot be given again';


-- sqlcl_snapshot {"hash":"3ad968f743568ec2a91a361e7f987121c86350f1","type":"COMMENT","name":"emk_party_role_types","schemaName":"emk_data","sxml":""}