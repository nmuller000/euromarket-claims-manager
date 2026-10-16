alter table emk_data.emk_shipments
    add constraint emk_shipments_shipper_fk
        foreign key ( shipper_id )
            references emk_data.emk_parties ( party_id )
        enable;


-- sqlcl_snapshot {"hash":"f48257793ad3db309f44c2b3b6969f177c2abe47","type":"REF_CONSTRAINT","name":"EMK_SHIPMENTS_SHIPPER_FK","schemaName":"EMK_DATA","sxml":""}