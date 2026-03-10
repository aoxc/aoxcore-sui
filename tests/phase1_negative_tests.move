#[test_only]
module aoxc::phase1_negative_tests {
    use std::string;
    use std::vector;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::neural_bridge;
    use aoxc::liquidity_manager;
    use aoxc::marketplace;
    use aoxc::staking;
    use aoxc::relay;
    use aoxc::reputation;
    use aoxc::sentinel_dao;
    use aoxc::treasury;
    use aoxc::walrus_connector;
    use aoxc::auto_rebalancer;
    use aoxc::verifier_registry;

    #[test, expected_failure(abort_code = errors::E_STATUS_INVALID)]
    fun aoxc_rejects_invalid_status() {
        aoxc::validate_status(255);
    }

    #[test, expected_failure(abort_code = errors::E_PROTOCOL_PAUSED)]
    fun breaker_rejects_paused_flag() {
        circuit_breaker::validate_live_flag(true);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun bridge_rejects_zero_min_confirmations() {
        neural_bridge::validate_min_confirmations(0);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun bridge_rejects_empty_signer_set() {
        neural_bridge::validate_signer_set(&vector::empty<vector<u8>>());
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun bridge_rejects_empty_signer_pubkey() {
        let keys = vector[vector::empty<u8>()];
        neural_bridge::validate_signer_set(&keys);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun relay_rejects_unknown_report_type() {
        relay::validate_report_type(99);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun relay_rejects_signers_over_active_attestors() {
        relay::assert_signer_bounds(4, 3);
    }

    #[test, expected_failure(abort_code = errors::E_EMPTY_HASH)]
    fun reputation_rejects_empty_evidence_hash() {
        let empty = vector::empty<u8>();
        reputation::validate_evidence_hash(&empty);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun dao_rejects_anomaly_score_over_100() {
        sentinel_dao::validate_anomaly_score(10_001);
    }

    #[test, expected_failure(abort_code = errors::E_EMPTY_HASH)]
    fun walrus_rejects_empty_blob_hash() {
        walrus_connector::validate_blob_inputs(&vector::empty<u8>(), &b"cert", &b"bridge");
    }



    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun intent_rejects_bad_success_bps() {
        bridge_payload::validate_intent(&string::utf8(b"ok"), 10_001, 1);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun verifier_registry_rejects_unknown_verifier() {
        verifier_registry::validate_verifier(&string::utf8(b"unknown-verifier"));
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun walrus_rejects_empty_credential_issuer() {
        walrus_connector::validate_credential_inputs(&vector::empty<u8>(), &b"subject", &b"claim", &b"cert");
    }



    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun rebalancer_rejects_invalid_thresholds() {
        auto_rebalancer::validate_thresholds(100, 99);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun dao_rejects_unknown_action() {
        sentinel_dao::validate_action_type(200);
    }

    #[test, expected_failure(abort_code = errors::E_LENGTH_MISMATCH)]
    fun treasury_rejects_mismatched_distribution_vectors() {
        treasury::validate_distribution_vectors(1, 2);
    }

    #[test, expected_failure(abort_code = errors::E_SCHEMA_VERSION)]
    fun payload_rejects_bad_schema_version() {
        bridge_payload::validate_schema_version(9);
    }

    #[test, expected_failure(abort_code = errors::E_TARGET_NOT_ALLOWED)]
    fun payload_rejects_bad_target_for_fund_update() {
        let bad_target = bridge_payload::target_breaker();
        bridge_payload::validate_target_module(&bad_target, bridge_payload::kind_fund_update());
    }

    #[test, expected_failure(abort_code = errors::E_CHAIN_ID_INVALID)]
    fun payload_rejects_bad_chain_id() {
        bridge_payload::validate_chain_id(1);
    }

    #[test, expected_failure(abort_code = errors::E_CHECKSUM_MISMATCH)]
    fun branding_checksum_must_match() {
        let gov = b"expected";
        let proposed = b"different";
        aoxc::assert_logo_checksum(&gov, &proposed);
    }

    #[test, expected_failure(abort_code = errors::E_SLASH_TOO_HIGH)]
    fun staking_rejects_over_slash_limit() {
        staking::validate_slash_bps(5000);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun liquidity_rejects_unknown_dex() {
        let dex = string::utf8(b"unknown-dex");
        liquidity_manager::validate_dex(&dex);
    }

    #[test, expected_failure(abort_code = errors::E_MARKETPLACE_LICENSE)]
    fun marketplace_rejects_empty_license() {
        marketplace::validate_listing_inputs(&b"walrus-blob", &vector::empty<u8>(), 10);
    }

    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun liquidity_rejects_excessive_slippage_limit() {
        liquidity_manager::validate_slippage_bps(4000);
    }



    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun treasury_reconciliation_rejects_non_interval_block() {
        treasury::validate_reconciliation_checkpoint(1000, 1001, 0, 32);
    }

    #[test, expected_failure(abort_code = errors::E_RECONCILIATION_FAILED)]
    fun staking_rejects_broken_capital_equation() {
        staking::validate_capital_equation(10, 15, 20);
    }

    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun treasury_reconciliation_rejects_non_interval_block() {
        treasury::validate_reconciliation_checkpoint(1000, 1001, 0, 32);
    }

    #[test, expected_failure(abort_code = errors::E_RECONCILIATION_FAILED)]
    fun staking_rejects_broken_capital_equation() {
        staking::validate_capital_equation(10, 15, 20);
    }

    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun treasury_reconciliation_rejects_non_interval_block() {
        treasury::validate_reconciliation_checkpoint(1000, 1001, 0, 32);
    }

    #[test, expected_failure(abort_code = errors::E_RECONCILIATION_FAILED)]
    fun staking_rejects_broken_capital_equation() {
        staking::validate_capital_equation(10, 15, 20);
    }

    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun treasury_reconciliation_rejects_non_interval_block() {
        treasury::validate_reconciliation_checkpoint(1000, 1001, 0, 32);
    }

    #[test, expected_failure(abort_code = errors::E_RECONCILIATION_FAILED)]
    fun staking_rejects_broken_capital_equation() {
        staking::validate_capital_equation(10, 15, 20);
    }

    #[test, expected_failure(abort_code = errors::E_POLICY_LIMIT)]
    fun staking_rejects_excessive_reward_bps() {
        staking::validate_reward_bps(5000);
    }

    #[test, expected_failure(abort_code = errors::E_POOL_NOT_ENABLED)]
    fun treasury_rejects_disabled_yield_policy() {
        treasury::validate_yield_policy(false, false, 0, 0, 0, 0);
    }

}
