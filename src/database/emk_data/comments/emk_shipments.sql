comment on table emk_data.emk_shipments is
    'Shipments under the CMR (BR-17); soft delete; previous versions in EMK_SHIPMENTS_JN';

comment on column emk_data.emk_shipments.agreed_delivery_date is
    'Agreed time-limit (delay, total loss; CMR Art. 19, 20)';

comment on column emk_data.emk_shipments.carriage_charges is
    'Carriage charges; delay compensation limit (BR-10, Art. 23(5))';

comment on column emk_data.emk_shipments.carrier_id is
    'Carrier (party with role CARRIER, BR-16)';

comment on column emk_data.emk_shipments.cmr_note_date is
    'Date of the consignment note (CMR Art. 6(1)(a)); taken as the making of the contract (Art. 32(1)(c), spec §5.3 L11); any order with pickup_date (L14)'
    ;

comment on column emk_data.emk_shipments.cmr_note_no is
    'CMR consignment note number, trimmed and upper case; unique per carrier including soft-deleted rows (BR-03)';

comment on column emk_data.emk_shipments.consignee_id is
    'Consignee (party with role CONSIGNEE, BR-16)';

comment on column emk_data.emk_shipments.currency_code is
    'Currency of carriage_charges (ISO 4217)';

comment on column emk_data.emk_shipments.declared_value is
    'Value declared in the consignment note (Art. 24): replaces the 8.33 SDR/kg limit';

comment on column emk_data.emk_shipments.declared_value_currency is
    'Currency of declared_value: EUR or with an ECB rate on the pickup date (API)';

comment on column emk_data.emk_shipments.deleted_yn is
    'Y = soft-deleted (BR-13); deleted_by and deleted_at are then set';

comment on column emk_data.emk_shipments.delivery_date is
    'Delivery; starts the reservation and limitation periods';

comment on column emk_data.emk_shipments.delivery_place is
    'Place designated for delivery (Art. 6(1)(d)); its holidays drive the reservation deadline';

comment on column emk_data.emk_shipments.destination_country is
    'Country of delivery_place (ISO 3166-1 alpha-2)';

comment on column emk_data.emk_shipments.disposal_date is
    'Goods placed at the consignee''s disposal (Art. 30(3)): start of the delay reservation; NULL = use delivery_date (L12)';

comment on column emk_data.emk_shipments.gross_weight_kg is
    'Gross weight in kg (SI), gram precision; basis of the liability cap (Art. 23)';

comment on column emk_data.emk_shipments.origin_country is
    'Country of pickup_place (ISO 3166-1 alpha-2)';

comment on column emk_data.emk_shipments.packages is
    'Number of packages';

comment on column emk_data.emk_shipments.pickup_date is
    'Taking over of the goods (date without time)';

comment on column emk_data.emk_shipments.pickup_place is
    'Place of taking over the goods (CMR Art. 6(1)(d)); relevant for jurisdiction (Art. 31)';

comment on column emk_data.emk_shipments.shipper_id is
    'Shipper (party with role SHIPPER, BR-16)';

comment on column emk_data.emk_shipments.special_interest is
    'Special interest in delivery declared in the consignment note (Art. 26)';

comment on column emk_data.emk_shipments.special_interest_currency is
    'Currency of special_interest: EUR or with an ECB rate on the pickup date (API)';


-- sqlcl_snapshot {"hash":"9187cc4cce7260b11bbc787561d233b57b68d016","type":"COMMENT","name":"emk_shipments","schemaName":"emk_data","sxml":""}