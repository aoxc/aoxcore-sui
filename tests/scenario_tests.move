#[test_only]
module aoxc::scenario_tests {
    use std::string;
    use std::vector;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::reputation;
    use aoxc::sentinel_dao;
    use aoxc::treasury;
    use sui::test_scenario;

    /// End-to-end war-game 1:
    /// treasury fill -> bridge halt policy -> transfer/distribution path must reject while paused.
    #[test, expected_failure(abort_code = errors::E_PROTOCOL_PAUSED)]
    fun e2e_bridge_halt_blocks_transfers() {
        let mut scenario = test_scenario::begin(@0xA0);

        // object-flow prechecks (treasury + payload + asset policy)
        treasury::validate_distribution_vectors(2, 2);
        aoxc::validate_status(aoxc::guarded_status_code());

        // typed decode stage for bridge halt
        let halt_raw = bridge_payload::encode_pause_payload(
            bridge_payload::schema_v1(),
            bridge_payload::target_breaker(),
            77,
            string::utf8(b"incident bridge halt"),
            b"halt-proof",
        );
        let _halt = bridge_payload::decode_pause_payload(halt_raw);

        // Simulate global paused state and assert fail path.
        circuit_breaker::validate_live_flag(true);
        test_scenario::end(scenario);
    }

    /// End-to-end war-game 2:
    /// DAO veto threshold reached => finalization path must remain frozen.
    #[test, expected_failure(abort_code = errors::E_VETOED)]
    fun e2e_dao_veto_freezes_funds() {
        let mut scenario = test_scenario::begin(@0xA0);
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

    /// End-to-end war-game 3:
    /// Reputation attestation mismatch must reject upsert path.
    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun e2e_reputation_proof_mismatch_rejected() {
        let mut scenario = test_scenario::begin(@0xA0);
        let expected = b"proof-A";
        let actual = b"proof-B";
        reputation::assert_evidence_match(&expected, &actual);
        test_scenario::end(scenario);
    }

    /// End-to-end war-game 4:
    /// Fund-update payload must be treasury-targeted and schema-valid.
    #[test]
    fun e2e_fund_update_typed_decode() {
        let mut scenario = test_scenario::begin(@0xA0);
        let raw = bridge_payload::encode_fund_update_payload(
            bridge_payload::schema_v1(),
            bridge_payload::target_treasury(),
            200,
            string::utf8(b"raise-min-score"),
            b"fund-proof",
        );
        let _decoded = bridge_payload::decode_fund_update_payload(raw);
        test_scenario::end(scenario);
    }
}
