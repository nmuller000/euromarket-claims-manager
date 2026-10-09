comment on table emk_app.emk_shipments is
    'Shipments under the CMR (BR-17); soft delete; previous versions in EMK_SHIPMENTS_JN';

comment on column emk_app.emk_shipments.agreed_delivery_date is
    'Agreed time-limit (delay, total loss; CMR Art. 19, 20)';

comment on column emk_app.emk_shipments.carriage_charges is
    'Carriage charges; delay compensation limit (BR-10, Art. 23(5))';

comment on column emk_app.emk_shipments.carrier_id is
    'Carrier (party with role CARRIER, BR-16)';

comment on column emk_app.emk_shipments.cmr_note_no is
    'CMR consignment note number, trimmed and upper case; unique per carrier including soft-deleted rows (BR-03)';

comment on column emk_app.emk_shipments.consignee_id is
    'Consignee (party with role CONSIGNEE, BR-16)';

comment on column emk_app.emk_shipments.currency_code is
    'Currency of carriage_charges (ISO 4217)';

comment on column emk_app.emk_shipments.deleted_yn is
    'Y = soft-deleted (BR-13); deleted_by and deleted_at are then set';

comment on column emk_app.emk_shipments.delivery_date is
    'Delivery; starts the reservation and limitation periods';

comment on column emk_app.emk_shipments.delivery_place is
    'Place designated for delivery (Art. 6(1)(d)); its holidays drive the reservation deadline';

comment on column emk_app.emk_shipments.destination_country is
    'Country of delivery_place (ISO 3166-1 alpha-2)';

comment on column emk_app.emk_shipments.gross_weight_kg is
    'Gross weight in kg (SI), gram precision; basis of the liability cap (Art. 23)';

comment on column emk_app.emk_shipments.origin_country is
    'Country of pickup_place (ISO 3166-1 alpha-2)';

comment on column emk_app.emk_shipments.packages is
    'Number of packages';

comment on column emk_app.emk_shipments.pickup_date is
    'Taking over of the goods (date without time)';

comment on column emk_app.emk_shipments.pickup_place is
    'Place of taking over the goods (CMR Art. 6(1)(d)); relevant for jurisdiction (Art. 31)';

comment on column emk_app.emk_shipments.shipper_id is
    'Shipper (party with role SHIPPER, BR-16)';


-- sqlcl_snapshot {"hash":"2ee21002af8d024a14d6fced9101da642ea464d4","type":"COMMENT","name":"emk_shipments","schemaName":"emk_app","sxml":""}