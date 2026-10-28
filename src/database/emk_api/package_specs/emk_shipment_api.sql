create or replace package emk_api.emk_shipment_api as
    /**
     * Business API of shipments (api-design.md §3, step 7). The only way to
     * change EMK_SHIPMENTS: APEX pages, the import (EMK_INT, M1b) and scripts
     * call these subprograms; the connect user EMK_UI has EXECUTE on this
     * package and no privilege on the table (ADR-008).
     *
     * Rules across tables, checked here (rules within a row are check
     * constraints of EMK_SHIPMENTS and reach the caller unchanged):
     *   - BR-16: the sender, carrier and consignee are active companies with
     *     the role SENDER, CARRIER and CONSIGNEE (EMK_PARTY_API.has_role).
     *   - CMR Art. 1(1), contract "for reward" with a third party (D-64): the
     *     carrier is never the sender or the consignee of the same shipment
     *     (no carriage on own account); sender = consignee is allowed.
     *   - BR-17: the carriage falls under the CMR: the origin or the
     *     destination country is a CMR party on the date of taking over.
     *   - Reference validity (D-64): both countries and the currency are valid
     *     on the date of taking over, not today, because a shipment is a past event;
     *     the currency is EUR or has an ECB rate (BR-12).
     *   - BR-03: a carrier never reuses a CMR note number, also of a deleted
     *     shipment (unique key of the table, translated here).
     *   - The date of the consignment note is required (CMR Art. 6(1)(a),
     *     D-79); the currencies of the declared value and of the special
     *     interest in delivery follow the rule of the carriage charges (D-78).
     * Rejections by BR-16 and BR-17 are logged as WARN (ids only, no personal
     * data), so that refused entries of pages and imports can be analysed in
     * the technical log page (D-64).
     * Values are normalised: CMR note number upper case and trimmed, places
     * and goods trimmed, dates without time. Soft delete (BR-13), restore
     * (D-39) and optimistic locking (D-43) as in EMK_PARTY_API. No COMMIT.
     *
     * @author Natalia Müller
     * @since  2026-10-17
     *
     * Copyright (c) 2026 Natalia Müller. All rights reserved.
     */

    /**
     * Creates a shipment.
     *
     * @param  in_cmr_note_no               number of the CMR consignment note
     * @param  in_cmr_note_date             date of the consignment note (CMR Art. 6(1)(a)), required; any order with the date of taking over (spec §5.3 L14)
     * @param  in_sender_id                 company with the role SENDER
     * @param  in_carrier_id                company with the role CARRIER
     * @param  in_consignee_id              company with the role CONSIGNEE
     * @param  in_taking_over_place         place of taking over the goods (CMR Art. 6(1)(d))
     * @param  in_origin_country            country of the place of taking over
     * @param  in_delivery_place            place designated for delivery
     * @param  in_destination_country       country of the delivery place
     * @param  in_taking_over_date          date of taking over the goods
     * @param  in_agreed_time_limit         agreed time-limit, if any (delay claims)
     * @param  in_delivery_date             actual delivery date, if known
     * @param  in_disposal_date             date the goods were placed at the consignee's disposal (Art. 30(3)), if known
     * @param  in_goods_description         description of the goods
     * @param  in_packages                  number of packages
     * @param  in_gross_weight_kg           gross weight in kg
     * @param  in_carriage_charges          carriage charges, with in_currency_code
     * @param  in_currency_code             ISO 4217 currency of the charges
     * @param  in_declared_value            value declared in the consignment note (Art. 24), if any, with its currency
     * @param  in_declared_value_currency   currency of the declared value
     * @param  in_special_interest          special interest in delivery (Art. 26), if any, with its currency
     * @param  in_special_interest_currency currency of the special interest
     * @param  out_shipment_id              id of the new shipment
     * @throws emk_errors_pkg.e_invalid_argument  no date of taking over or no date of the consignment note
     * @throws emk_errors_pkg.e_carrier_not_third_party the carrier is also the sender or the consignee
     * @throws emk_errors_pkg.e_party_role_missing  BR-16: a company is missing, deleted or lacks its role
     * @throws emk_errors_pkg.e_cmr_not_applicable  BR-17: no CMR party on the date of taking over
     * @throws emk_errors_pkg.e_reference_not_valid a country or a currency is not valid
     *                                              on the date of taking over, or a currency has no ECB rate
     * @throws emk_errors_pkg.e_duplicate_cmr_note  BR-03: the carrier already used the note number
     */
    procedure create_shipment (
        in_cmr_note_no               in emk_data.emk_shipments.cmr_note_no%type,
        in_cmr_note_date             in emk_data.emk_shipments.cmr_note_date%type,
        in_sender_id                 in emk_data.emk_shipments.sender_id%type,
        in_carrier_id                in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id              in emk_data.emk_shipments.consignee_id%type,
        in_taking_over_place         in emk_data.emk_shipments.taking_over_place%type,
        in_origin_country            in emk_data.emk_shipments.origin_country%type,
        in_delivery_place            in emk_data.emk_shipments.delivery_place%type,
        in_destination_country       in emk_data.emk_shipments.destination_country%type,
        in_taking_over_date          in emk_data.emk_shipments.taking_over_date%type,
        in_agreed_time_limit         in emk_data.emk_shipments.agreed_time_limit%type,
        in_delivery_date             in emk_data.emk_shipments.delivery_date%type,
        in_disposal_date             in emk_data.emk_shipments.disposal_date%type,
        in_goods_description         in emk_data.emk_shipments.goods_description%type,
        in_packages                  in emk_data.emk_shipments.packages%type,
        in_gross_weight_kg           in emk_data.emk_shipments.gross_weight_kg%type,
        in_carriage_charges          in emk_data.emk_shipments.carriage_charges%type,
        in_currency_code             in emk_data.emk_shipments.currency_code%type,
        in_declared_value            in emk_data.emk_shipments.declared_value%type,
        in_declared_value_currency   in emk_data.emk_shipments.declared_value_currency%type,
        in_special_interest          in emk_data.emk_shipments.special_interest%type,
        in_special_interest_currency in emk_data.emk_shipments.special_interest_currency%type,
        out_shipment_id              out emk_data.emk_shipments.shipment_id%type
    );

    /**
     * Changes a shipment, with the checks of create_shipment. Nothing is
     * written if no value changed.
     *
     * @param  in_shipment_id         shipment
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @param  in_cmr_note_no         … in_currency_code as in create_shipment
     * @throws emk_errors_pkg.e_not_found      shipment does not exist or is deleted
     * @throws emk_errors_pkg.e_record_changed changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked  locked by another transaction
     * @throws the errors of create_shipment
     */
    procedure update_shipment (
        in_shipment_id               in emk_data.emk_shipments.shipment_id%type,
        in_expected_updated_at       in emk_data.emk_shipments.updated_at%type,
        in_cmr_note_no               in emk_data.emk_shipments.cmr_note_no%type,
        in_cmr_note_date             in emk_data.emk_shipments.cmr_note_date%type,
        in_sender_id                 in emk_data.emk_shipments.sender_id%type,
        in_carrier_id                in emk_data.emk_shipments.carrier_id%type,
        in_consignee_id              in emk_data.emk_shipments.consignee_id%type,
        in_taking_over_place         in emk_data.emk_shipments.taking_over_place%type,
        in_origin_country            in emk_data.emk_shipments.origin_country%type,
        in_delivery_place            in emk_data.emk_shipments.delivery_place%type,
        in_destination_country       in emk_data.emk_shipments.destination_country%type,
        in_taking_over_date          in emk_data.emk_shipments.taking_over_date%type,
        in_agreed_time_limit         in emk_data.emk_shipments.agreed_time_limit%type,
        in_delivery_date             in emk_data.emk_shipments.delivery_date%type,
        in_disposal_date             in emk_data.emk_shipments.disposal_date%type,
        in_goods_description         in emk_data.emk_shipments.goods_description%type,
        in_packages                  in emk_data.emk_shipments.packages%type,
        in_gross_weight_kg           in emk_data.emk_shipments.gross_weight_kg%type,
        in_carriage_charges          in emk_data.emk_shipments.carriage_charges%type,
        in_currency_code             in emk_data.emk_shipments.currency_code%type,
        in_declared_value            in emk_data.emk_shipments.declared_value%type,
        in_declared_value_currency   in emk_data.emk_shipments.declared_value_currency%type,
        in_special_interest          in emk_data.emk_shipments.special_interest%type,
        in_special_interest_currency in emk_data.emk_shipments.special_interest_currency%type
    );

    /**
     * Soft-deletes a shipment.
     *
     * @param  in_shipment_id         shipment
     * @param  in_expected_updated_at version read by the caller (row_version)
     * @throws emk_errors_pkg.e_not_found        shipment does not exist or is already deleted
     * @throws emk_errors_pkg.e_shipment_in_use  the shipment has an active claim
     * @throws emk_errors_pkg.e_record_changed   changed by another user since it was read
     * @throws emk_errors_pkg.e_record_locked    locked by another transaction
     */
    procedure delete_shipment (
        in_shipment_id         in emk_data.emk_shipments.shipment_id%type,
        in_expected_updated_at in emk_data.emk_shipments.updated_at%type
    );

    /**
     * Restores a soft-deleted shipment (D-39). Checks BR-16 again: a company
     * may have been deleted or lost its role in the meantime. Does nothing if
     * the shipment is not deleted.
     *
     * @param  in_shipment_id shipment
     * @throws emk_errors_pkg.e_not_found          shipment does not exist
     * @throws emk_errors_pkg.e_party_role_missing BR-16: a company is no longer active with its role
     * @throws emk_errors_pkg.e_record_locked      locked by another transaction
     */
    procedure restore_shipment (
        in_shipment_id in emk_data.emk_shipments.shipment_id%type
    );

end emk_shipment_api;
/


-- sqlcl_snapshot {"hash":"7a644f3d7ab414199125017bdd317ae3e038d3c6","type":"PACKAGE_SPEC","name":"EMK_SHIPMENT_API","schemaName":"EMK_API","sxml":""}