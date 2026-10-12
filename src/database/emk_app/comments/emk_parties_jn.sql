comment on table emk_app.emk_parties_jn is
    'Journal of EMK_PARTIES: previous row on UPDATE (U) and DELETE (D); written by trigger EMK_PARTIES_JN_AUD';

comment on column emk_app.emk_parties_jn.jn_at is
    'When the change happened';

comment on column emk_app.emk_parties_jn.jn_by is
    'Who made the change (APEX user, proxy user or session user)';

comment on column emk_app.emk_parties_jn.jn_on is
    'Virtual UTC date-time of jn_at; monthly interval partition key';

comment on column emk_app.emk_parties_jn.jn_operation is
    'U = update (also soft delete and restore), D = delete';


-- sqlcl_snapshot {"hash":"7971ad760635b15bf3fd69a9843aea33527f5112","type":"COMMENT","name":"emk_parties_jn","schemaName":"emk_app","sxml":""}