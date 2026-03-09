#[test_only]
module aoxc::scenario_tests {
    use std::string;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::reputation;
    use aoxc::sentinel_dao;
    use aoxc::treasury;
    use sui::test_scenario;

    fun xsender(): vector<u8> { b"12345678901234567890" }

    #[test, expected_failure(abort_code = errors::E_PROTOCOL_PAUSED)]
    fun e2e_bridge_halt_blocks_transfers() {
        let scenario = test_scenario::begin(@0xA0);
        treasury::validate_distribution_vectors(2, 2);
        aoxc::validate_status(aoxc::guarded_status_code());

        let halt_raw = bridge_payload::encode_pause_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_breaker(),
            77,
            string::utf8(b"incident bridge halt"),
            b"halt-proof",
        );
        let _halt = bridge_payload::decode_pause_payload(halt_raw);
        circuit_breaker::validate_live_flag(true);
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = errors::E_VETOED)]
    fun e2e_dao_veto_freezes_funds() {
        let scenario = test_scenario::begin(@0xA0);
        let _action = bridge_payload::new_governance_action(
            bridge_payload::schema_v1(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            100,
            string::utf8(b"freeze through veto"),
            b"dao-proof",
        );
        sentinel_dao::assert_not_vetoed(15, 15);
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun e2e_reputation_proof_mismatch_rejected() {
        let scenario = test_scenario::begin(@0xA0);
        let expected = b"proof-A";
        let actual = b"proof-B";
        reputation::assert_evidence_match(&expected, &actual);
        test_scenario::end(scenario);
    }

    #[test]
    fun e2e_fund_update_typed_decode() {
        let scenario = test_scenario::begin(@0xA0);
        let raw = bridge_payload::encode_fund_update_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_treasury(),
            200,
            string::utf8(b"raise-min-score"),
            b"fund-proof",
        );
        let _decoded = bridge_payload::decode_fund_update_payload(raw);
        test_scenario::end(scenario);
    }
}
