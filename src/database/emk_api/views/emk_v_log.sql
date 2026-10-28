create or replace force editionable view emk_api.emk_v_log (
    log_id,
    log_level,
    module,
    message,
    context,
    error_stack,
    created_at,
    created_by
) as
    select
    /**
     * Technical log for the read-only log page of the administrator (D-64):
     * level, module, message, context as text, error stack, time and user.
     * Messages and context never contain personal data (spec §1.3 Logging).
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */
        log_id,
        log_level,
        module,
        message,
        json_serialize(context returning clob) as context,
        error_stack,
        created_at,
        created_by
    from
        emk_api.emk_log;


-- sqlcl_snapshot {"hash":"237c7ae0f2357ce60cf8f799b846c40ea7413df6","type":"VIEW","name":"EMK_V_LOG","schemaName":"EMK_API","sxml":""}