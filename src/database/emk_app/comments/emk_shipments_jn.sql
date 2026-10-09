comment on table emk_app.emk_shipments_jn is
    'Journal of EMK_SHIPMENTS: previous row on UPDATE (U) and DELETE (D); written by trigger EMK_SHIPMENTS_JN_AUD';

comment on column emk_app.emk_shipments_jn.jn_at is
    'When the change happened';

comment on column emk_app.emk_shipments_jn.jn_by is
    'Who made the change (APEX user, proxy user or session user)';

comment on column emk_app.emk_shipments_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_shipments_jn.jn_operation is
    'U = update (also soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"56a321aa65bf5af0228e30cc897530c427c5a898","type":"COMMENT","name":"emk_shipments_jn","schemaName":"emk_app","sxml":""}