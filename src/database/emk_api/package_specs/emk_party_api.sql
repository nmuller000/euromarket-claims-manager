create or replace package emk_api.emk_party_api as
    /**
     * Business API of companies (parties), their roles and their contact
     * persons (api-design.md §3, step 7). The only way to change
     * EMK_PARTIES, EMK_PARTY_ROLES and EMK_CONTACTS: APEX pages, the import
     * and scripts call these subprograms; the connect user EMK_UI has EXECUTE
     * on this package and no privilege on the tables (ADR-008).
     *
     * Rules:
     *   - Soft delete only (BR-13): delete sets deleted_yn = 'Y'; restore
     *     undoes it (D-39). Deleted rows are hidden by the views.
     *   - Optimistic locking (D-43): update and delete receive the version the
     *     caller read, NVL(updated_at, created_at) (column row_version of the
     *     views); a different current version raises c_record_changed. Rows are
     *     locked with FOR UPDATE NOWAIT: a row locked by another transaction
     *     raises c_record_locked instead of waiting.
     *   - Values are normalised before they are stored: names and places
     *     trimmed, VAT number upper case without spaces, phone without spaces.
     *   - Format rules within a row are check constraints of the tables; their
     *     errors reach the caller unchanged and the APEX error handling
     *     function turns them into messages (spec §1.3 Error handling).
     *   - No COMMIT: the caller ends the transaction.
     *   - Release 1 checks no application role here (api-design.md §5,
     *     decision 4): APEX authorization and the grants protect the calls.
     *
     * @author Natalia Müller
     * @since  2026-10-16
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    -- Parties ----------------------------------------------------------------

    /**
     * Creates a company.
     *
     * @param  in_name          company name (trimmed, required)
     * @param  in_vat_number    EU VAT number, VIES format; NULL if the company has none
     * @param  in_country_code  ISO 3166-1 alpha-2 country, valid today
     * @param  in_street        street and number
     * @param  in_postal_code   postal code
     * @param  in_city          city
     * @param  in_language_code language of letters: en or de (NULL = en)
     * @param  out_party_id     id of the new company
     * @throws emk_errors_pkg.e_reference_not_valid  unknown country or country not valid today
     * @throws emk_errors_pkg.e_vat_country_mismatch VAT prefix is not the country's EU VAT prefix
     *                                               (XI is also accepted for GB, Northern Ireland)
     * @throws emk_errors_pkg.e_duplicate_vat        VAT number already used; if by a deleted
     *                                               company, the message asks to restore it
     */
    procedure create_party (
        in_name          in emk_data.emk_parties.name%type,
        in_vat_number    in emk_data.emk_parties.vat_number%type,
        in_country_code  in emk_data.emk_parties.country_code%type,
        in_street        in emk_data.emk_parties.street%type,
        in_postal_code   in emk_data.emk_parties.postal_code%type,
        in_city          in emk_data.emk_parties.city%type,
        in_language_code in emk_data.emk_parties.language_code%type,
        out_party_id     out emk_data.emk_parties.party_id%type
    );

    /**
     * Changes a company. Nothing is written if no value changed.
     *
     * @param  in_party_id            company
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @param  in_name … in_language_code as in create_party
     * @throws emk_errors_pkg.e_not_found      company does not exist or is deleted
     * @throws emk_errors_pkg.e_record_changed changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked  locked by another transaction
     * @throws the errors of create_party
     */
    procedure update_party (
        in_party_id            in emk_data.emk_parties.party_id%type,
        in_expected_updated_at in emk_data.emk_parties.updated_at%type,
        in_name                in emk_data.emk_parties.name%type,
        in_vat_number          in emk_data.emk_parties.vat_number%type,
        in_country_code        in emk_data.emk_parties.country_code%type,
        in_street              in emk_data.emk_parties.street%type,
        in_postal_code         in emk_data.emk_parties.postal_code%type,
        in_city                in emk_data.emk_parties.city%type,
        in_language_code       in emk_data.emk_parties.language_code%type
    );

    /**
     * Soft-deletes a company and, in the same transaction, its active contacts.
     *
     * @param  in_party_id            company
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @throws emk_errors_pkg.e_not_found      company does not exist or is already deleted
     * @throws emk_errors_pkg.e_party_in_use   an active shipment uses the company
     * @throws emk_errors_pkg.e_record_changed changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked  locked by another transaction
     */
    procedure delete_party (
        in_party_id            in emk_data.emk_parties.party_id%type,
        in_expected_updated_at in emk_data.emk_parties.updated_at%type
    );

    /**
     * Restores a soft-deleted company (D-39). Its contacts stay deleted and
     * are restored one by one with restore_contact. Does nothing if the
     * company is not deleted.
     *
     * @param  in_party_id company
     * @throws emk_errors_pkg.e_not_found     company does not exist
     * @throws emk_errors_pkg.e_record_locked locked by another transaction
     */
    procedure restore_party (
        in_party_id in emk_data.emk_parties.party_id%type
    );

    -- Roles (BR-16) ----------------------------------------------------------

    /**
     * Gives a role to an active company. Does nothing if it already has it.
     *
     * @param  in_party_id  company
     * @param  in_role_code SHIPPER, CONSIGNEE, CARRIER, FORWARDER, INSURER or SURVEYOR
     * @throws emk_errors_pkg.e_not_found        company does not exist or is deleted
     * @throws emk_errors_pkg.e_invalid_argument unknown role
     */
    procedure add_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    );

    /**
     * Takes a role away from a company. Does nothing if it does not have it.
     *
     * @param  in_party_id  company
     * @param  in_role_code role
     * @throws emk_errors_pkg.e_not_found         company does not exist or is deleted
     * @throws emk_errors_pkg.e_party_role_in_use a shipment (also a deleted one) uses the
     *                                            company in this role (BR-16)
     */
    procedure remove_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    );

    /**
     * Sets the complete list of roles of a company: adds the missing ones and
     * removes the others, with the rules of add_role and remove_role. For a
     * checkbox list of an APEX page, so that the page does not compute the
     * difference itself (business logic stays in the API).
     *
     * @param  in_party_id   company
     * @param  in_role_codes roles separated by colons, e.g. SHIPPER:CARRIER
     *                       (the value of an APEX checkbox item); NULL = no role
     * @throws the errors of add_role and remove_role
     */
    procedure set_roles (
        in_party_id   in emk_data.emk_party_roles.party_id%type,
        in_role_codes in varchar2
    );

    /**
     * Tells whether an active company has a role. Used by EMK_SHIPMENT_API
     * (BR-16) and by APEX lists of values.
     *
     * @param  in_party_id  company
     * @param  in_role_code role
     * @return TRUE if the company exists, is not deleted and has the role
     */
    function has_role (
        in_party_id  in emk_data.emk_party_roles.party_id%type,
        in_role_code in emk_data.emk_party_roles.role_code%type
    ) return boolean;

    -- Contacts (personal data, spec §3.3) --------------------------------------

    /**
     * Creates a contact person of an active company.
     *
     * @param  in_party_id   company
     * @param  in_full_name  name (trimmed, required)
     * @param  in_email      email address
     * @param  in_phone      phone number, E.164 (+ and up to 15 digits; spaces are removed)
     * @param  out_contact_id id of the new contact
     * @throws emk_errors_pkg.e_not_found company does not exist or is deleted
     */
    procedure create_contact (
        in_party_id    in emk_data.emk_contacts.party_id%type,
        in_full_name   in emk_data.emk_contacts.full_name%type,
        in_email       in emk_data.emk_contacts.email%type,
        in_phone       in emk_data.emk_contacts.phone%type,
        out_contact_id out emk_data.emk_contacts.contact_id%type
    );

    /**
     * Changes a contact person. Nothing is written if no value changed.
     *
     * @param  in_contact_id          contact
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @param  in_full_name, in_email, in_phone as in create_contact
     * @throws emk_errors_pkg.e_not_found      contact does not exist or is deleted
     * @throws emk_errors_pkg.e_record_changed changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked  locked by another transaction
     */
    procedure update_contact (
        in_contact_id          in emk_data.emk_contacts.contact_id%type,
        in_expected_updated_at in emk_data.emk_contacts.updated_at%type,
        in_full_name           in emk_data.emk_contacts.full_name%type,
        in_email               in emk_data.emk_contacts.email%type,
        in_phone               in emk_data.emk_contacts.phone%type
    );

    /**
     * Soft-deletes a contact person.
     *
     * @param  in_contact_id          contact
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @throws emk_errors_pkg.e_not_found      contact does not exist or is already deleted
     * @throws emk_errors_pkg.e_record_changed changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked  locked by another transaction
     */
    procedure delete_contact (
        in_contact_id          in emk_data.emk_contacts.contact_id%type,
        in_expected_updated_at in emk_data.emk_contacts.updated_at%type
    );

    /**
     * Restores a soft-deleted contact person of an active company (D-39).
     * Does nothing if the contact is not deleted.
     *
     * @param  in_contact_id contact
     * @throws emk_errors_pkg.e_not_found     contact does not exist, or its company is deleted
     * @throws emk_errors_pkg.e_record_locked locked by another transaction
     */
    procedure restore_contact (
        in_contact_id in emk_data.emk_contacts.contact_id%type
    );

end emk_party_api;
/


-- sqlcl_snapshot {"hash":"853f815a8781d1ebe0329e6292e75764818422db","type":"PACKAGE_SPEC","name":"EMK_PARTY_API","schemaName":"EMK_API","sxml":""}