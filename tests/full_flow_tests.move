#[test_only]
module aoxc::full_flow_tests {
    use std::string;
    use std::vector;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::relay;
    use aoxc::sentinel_dao;
    use aoxc::treasury;

    /// Phase-2A typed payload/governance smoke flow:
    /// bridge payload + governance action + policy validators must compose.
    #[test]
    fun typed_flow_smoke() {
        let root = b"proof-root-1";
        let payload = bridge_payload::new_bridge_payload(
            bridge_payload::kind_system_halt(),
            42,
            string::utf8(b"Bridge halt request"),
            root,
        );
        let action = bridge_payload::new_governance_action(
            bridge_payload::kind_system_resume(),
            43,
            string::utf8(b"DAO resume after review"),
            b"proof-root-2",
        );

        // Cross-module typed guards.
        relay::validate_report_type(relay::reputation_report_type());
        sentinel_dao::validate_action_type(bridge_payload::action_type(&action));
        treasury::validate_distribution_vectors(1, 1);
        aoxc::validate_status(aoxc::guarded_status_code());

        // consume to avoid warnings in stricter toolchains
        let _ = payload;
        let _ = action;
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun typed_payload_rejects_invalid_kind() {
        let _ = bridge_payload::new_bridge_payload(
            99,
            1,
            string::utf8(b"invalid"),
            b"proof",
        );
    }

    #[test]
    #[expected_failure(abort_code = 15)]
    fun typed_governance_rejects_empty_proof() {
        let _ = bridge_payload::new_governance_action(
            bridge_payload::kind_system_halt(),
            1,
            string::utf8(b"missing proof"),
            vector::empty<u8>(),
        );
    }
}
