create or replace package body emk_api.emk_codes_pkg as
    /**
     * Implementation of EMK_CODES_PKG; its specification documents the
     * public subprograms.
     *
     * @author Natalia Müller
     * @since  2026-10-21
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    function is_protected_role (
        in_role_code in emk_data.emk_party_role_types.role_code%type
    ) return boolean is
    begin
        return
            in_role_code is not null   -- FALSE, not NULL, for an empty code
            and in_role_code in ( c_role_shipper, c_role_carrier, c_role_consignee );
    end is_protected_role;

end emk_codes_pkg;
/


-- sqlcl_snapshot {"hash":"36d6cd0b692b8285b1bc026a95f7c1cb719e9844","type":"PACKAGE_BODY","name":"EMK_CODES_PKG","schemaName":"EMK_API","sxml":""}