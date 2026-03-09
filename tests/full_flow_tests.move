#[test_only]
module aoxc::full_flow_tests {
    use std::string;
    use std::vector;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::liquidity_manager;
    use aoxc::marketplace;
    use aoxc::relay;
    use aoxc::sentinel_dao;
    use aoxc::staking;
    use aoxc::treasury;

    fun xsender(): vector<u8> { b"12345678901234567890" }

    #[test]
    fun typed_flow_smoke() {
        let payload = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            42,
            string::utf8(b"Bridge halt request"),
            b"proof-root-1",
        );
        let pause_raw = bridge_payload::encode_pause_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_breaker(),
            44,
            string::utf8(b"decoded halt"),
            b"proof-root-3",
        );
        let decoded_pause = bridge_payload::decode_pause_payload(pause_raw);
        let pause_target = bridge_payload::target_module_bytes(&decoded_pause);
        let action = bridge_payload::new_governance_action(
            bridge_payload::schema_v1(),
            bridge_payload::kind_system_resume(),
            bridge_payload::target_breaker(),
            43,
            string::utf8(b"DAO resume after review"),
            b"proof-root-2",
        );

        relay::validate_report_type(relay::reputation_report_type());
        sentinel_dao::validate_action_type(bridge_payload::action_type(&action));
        treasury::validate_distribution_vectors(1, 1);
        aoxc::validate_status(aoxc::guarded_status_code());
        staking::validate_slash_bps(1000);
        liquidity_manager::validate_dex(&string::utf8(b"cetus"));
        marketplace::validate_listing_inputs(&b"walrus-blob", &b"license-hash", 100);

        let _ = payload;
        let _ = decoded_pause;
        let _ = pause_target;
        let _ = action;
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun typed_payload_rejects_invalid_kind() {
        let _ = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            99,
            bridge_payload::target_breaker(),
            1,
            string::utf8(b"invalid"),
            b"proof",
        );
    }

    #[test]
    #[expected_failure(abort_code = 15)]
    fun typed_governance_rejects_empty_proof() {
        let _ = bridge_payload::new_governance_action(
            bridge_payload::schema_v1(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            1,
            string::utf8(b"missing proof"),
            vector::empty<u8>(),
        );
    }

    #[test]
    #[expected_failure(abort_code = 23)]
    fun fund_update_rejects_wrong_target() {
        let _ = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::kind_fund_update(),
            bridge_payload::target_breaker(),
            2,
            string::utf8(b"wrong target"),
            b"proof",
        );
    }
}
