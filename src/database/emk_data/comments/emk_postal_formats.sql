comment on table emk_data.emk_postal_formats is
    'Postcode rule per country (D-90, BR-20): required or not, pattern, example, prefix. Source: UPU Universal POST*CODE DataBase. Changed only by versioned MERGE scripts; whether a postcode exists is not checked'
    ;

comment on column emk_data.emk_postal_formats.country_code is
    'Country (EMK_COUNTRIES)';

comment on column emk_data.emk_postal_formats.postal_code_example is
    'Example shown to the user; it follows postal_code_format';

comment on column emk_data.emk_postal_formats.postal_code_format is
    'Regular expression of the whole postcode: anchored, explicit character lists, no ranges (P-20); an inner space optional; NULL = format not checked'
    ;

comment on column emk_data.emk_postal_formats.postal_code_prefix is
    'Prefix that is part of the official postcode (e.g. LV-, L-, AZ); EMK_PARTY_API adds it when the user types only the digits';

comment on column emk_data.emk_postal_formats.postal_code_required_yn is
    'Y = an address in the country needs a postcode; N = the country does not use postcodes (UPU; of the 60 countries only Syria)';

comment on column emk_data.emk_postal_formats.valid_from is
    'Start of validity';

comment on column emk_data.emk_postal_formats.valid_to is
    'End of validity; NULL = still valid';


-- sqlcl_snapshot {"hash":"f461352290471b91cc56fabdf3643ebc15ec1f13","type":"COMMENT","name":"emk_postal_formats","schemaName":"emk_data","sxml":""}