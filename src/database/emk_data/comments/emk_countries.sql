comment on table emk_data.emk_countries is
    'Countries in scope: 58 CMR parties plus IS and LI (ISO 3166-1 alpha-2); changed only by versioned MERGE scripts';

comment on column emk_data.emk_countries.cmr_party_since is
    'Entry into force of the CMR for the country (deposit + 90 days, Art. 43); NULL = not a party';

comment on column emk_data.emk_countries.country_code is
    'ISO 3166-1 alpha-2 code';

comment on column emk_data.emk_countries.eea_member_yn is
    'Y = EEA member (EU plus IS, LI, NO)';

comment on column emk_data.emk_countries.eu_member_yn is
    'Y = EU member';

comment on column emk_data.emk_countries.eu_vat_prefix is
    'EU VAT (VIES) prefix; EL for Greece; NULL outside the EU';

comment on column emk_data.emk_countries.iso_name is
    'English short name of ISO 3166-1 (traceability to the standard)';

comment on column emk_data.emk_countries.name is
    'English display name from the EU authority table Countries and territories';

comment on column emk_data.emk_countries.valid_from is
    'Start of validity';

comment on column emk_data.emk_countries.valid_to is
    'End of validity; NULL = still valid';


-- sqlcl_snapshot {"hash":"f66d64eb3113d0f9bf42649ce3c67d32416e5a15","type":"COMMENT","name":"emk_countries","schemaName":"emk_data","sxml":""}