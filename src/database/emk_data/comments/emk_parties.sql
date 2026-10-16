comment on table emk_data.emk_parties is
    'Companies (shipper, consignee, carrier, …); soft delete; previous versions in EMK_PARTIES_JN';

comment on column emk_data.emk_parties.city is
    'City';

comment on column emk_data.emk_parties.country_code is
    'Country of registration (ISO 3166-1 alpha-2)';

comment on column emk_data.emk_parties.deleted_yn is
    'Y = soft-deleted (BR-13); deleted_by and deleted_at are then set';

comment on column emk_data.emk_parties.language_code is
    'Language for letters (ISO 639-1: en or de in Release 1)';

comment on column emk_data.emk_parties.name is
    'Legal company name';

comment on column emk_data.emk_parties.postal_code is
    'Postal code (text: letters and spaces in several countries)';

comment on column emk_data.emk_parties.street is
    'Postal address for letters (M4)';

comment on column emk_data.emk_parties.vat_number is
    'EU VAT number (VIES format, upper case, no spaces); unique including soft-deleted parties (restore instead of re-create, D-39)';


-- sqlcl_snapshot {"hash":"92a2f5b2dc6db5e01430aa86a938e7f655247598","type":"COMMENT","name":"emk_parties","schemaName":"emk_data","sxml":""}