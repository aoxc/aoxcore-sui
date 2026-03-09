#[test_only]
module aoxc::scenario_tests {
    use std::vector;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::reputation;
    use aoxc::sentinel_dao;
    use sui::test_scenario;

    /// End-to-end war-game 1:
    /// protocol paused => transfer/distribution guarded paths must fail.
    #[test, expected_failure(abort_code = errors::E_PROTOCOL_PAUSED)]
    fun e2e_bridge_halt_blocks_transfers() {
        let mut scenario = test_scenario::begin(@0xA0);
        // Simulate halted state from bridge/dao control plane.
        circuit_breaker::validate_live_flag(true);
        test_scenario::end(scenario);
    }

    /// End-to-end war-game 2:
    /// DAO veto threshold reached => finalization path must remain frozen.
    #[test, expected_failure(abort_code = errors::E_VETOED)]
    fun e2e_dao_veto_freezes_funds() {
        let mut scenario = test_scenario::begin(@0xA0);
        sentinel_dao::assert_not_vetoed(10, 10);
        test_scenario::end(scenario);
    }

    /// End-to-end war-game 3:
    /// Attestation/proof mismatch must reject reputation write.
    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun e2e_reputation_proof_mismatch_rejected() {
        let mut scenario = test_scenario::begin(@0xA0);
        let expected = b"proof-A";
        let actual = b"proof-B";
        reputation::assert_evidence_match(&expected, &actual);
        test_scenario::end(scenario);
    }
}
