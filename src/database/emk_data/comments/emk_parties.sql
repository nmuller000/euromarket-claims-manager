comment on table emk_data.emk_parties is
    'Companies (sender, consignee, carrier, …); soft delete; previous versions in EMK_PARTIES_JN';

comment on column emk_data.emk_parties.city is
    'City; required (D-89)';

comment on column emk_data.emk_parties.country_code is
    'Country of registration (ISO 3166-1 alpha-2)';

comment on column emk_data.emk_parties.deleted_yn is
    'Y = soft-deleted (BR-13); deleted_by and deleted_at are then set';

comment on column emk_data.emk_parties.language_code is
    'Language for letters (EMK_LANGUAGES); required, no default (D-71)';

comment on column emk_data.emk_parties.name is
    'Legal company name';

comment on column emk_data.emk_parties.postal_code is
    'Postcode: upper case, 2 to 10 letters, digits, spaces and hyphens (EMK_PARTIES_POSTCODE_CK); required and in the format of the country where EMK_POSTAL_FORMATS says so, checked by EMK_PARTY_API (BR-20, D-89, D-90)'
    ;

comment on column emk_data.emk_parties.street is
    'Street and number; required (D-89, CMR Art. 6(1) name and address); letters (M4)';

comment on column emk_data.emk_parties.vat_number is
    'EU VAT number (VIES format: prefix of EMK_VAT_FORMATS and national part, upper case, no spaces); unique including soft-deleted parties (restore instead of re-create, D-39)'
    ;


-- sqlcl_snapshot {"hash":"ff03e59e297458e642c381cdb0c47422c7afac78","type":"COMMENT","name":"emk_parties","schemaName":"emk_data","sxml":""}