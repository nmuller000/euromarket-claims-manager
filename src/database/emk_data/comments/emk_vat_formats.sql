comment on table emk_data.emk_vat_formats is
    'Format of the national part of an EU VAT number per VAT prefix (D-88): the 27 member states and XI (Northern Ireland, country GB). Sources: BZSt "Aufbau der USt-IdNr.", HMRC. Changed only by versioned MERGE scripts'
    ;

comment on column emk_data.emk_vat_formats.country_code is
    'Country of the companies that use the prefix (EMK_COUNTRIES); no index: 28 rows';

comment on column emk_data.emk_vat_formats.national_example is
    'Example of the national part, shown to the user; it follows national_format';

comment on column emk_data.emk_vat_formats.national_format is
    'Regular expression of the national part, after the prefix: anchored, explicit character lists, no ranges (P-20)';

comment on column emk_data.emk_vat_formats.valid_from is
    'Start of validity (XI: 2021-01-01, Windsor Framework)';

comment on column emk_data.emk_vat_formats.valid_to is
    'End of validity; NULL = still valid. Companies keep a VAT number with a retired prefix';

comment on column emk_data.emk_vat_formats.vat_prefix is
    'VAT (VIES) prefix; differs from the ISO code for Greece (EL) and Northern Ireland (XI)';


-- sqlcl_snapshot {"hash":"0e372d82935f5b80f8408a68780ab017a95133ba","type":"COMMENT","name":"emk_vat_formats","schemaName":"emk_data","sxml":""}