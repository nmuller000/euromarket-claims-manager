comment on table emk_api.emk_log is
    'Technical application log; written by EMK_LOG_PKG in an autonomous transaction; 90-day retention by partition';

comment on column emk_api.emk_log.context is
    'Technical context (ids, parameters, APEX app/page/session); no personal data, no secrets';

comment on column emk_api.emk_log.created_on is
    'Virtual UTC date-time of created_at; monthly interval partition key';

comment on column emk_api.emk_log.error_stack is
    'FORMAT_ERROR_STACK and FORMAT_ERROR_BACKTRACE for errors';

comment on column emk_api.emk_log.log_level is
    'DEBUG, INFO, WARN or ERROR';

comment on column emk_api.emk_log.message is
    'Short message; no personal data, no secrets';

comment on column emk_api.emk_log.module is
    'PACKAGE.SUBPROGRAM that wrote the entry';


-- sqlcl_snapshot {"hash":"30b60c7ed4aea2b6f67af725498f129eef717709","type":"COMMENT","name":"emk_log","schemaName":"emk_api","sxml":""}