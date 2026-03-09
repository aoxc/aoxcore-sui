#[test_only]
module aoxc::phase1_negative_tests {
    use std::vector;
    use aoxc::aoxc;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use aoxc::neural_bridge;
    use aoxc::relay;
    use aoxc::reputation;
    use aoxc::sentinel_dao;
    use aoxc::treasury;

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
    fun relay_rejects_unknown_report_type() {
        relay::validate_report_type(99);
    }

    #[test, expected_failure(abort_code = errors::E_EMPTY_HASH)]
    fun reputation_rejects_empty_evidence_hash() {
        let empty = vector::empty<u8>();
        reputation::validate_evidence_hash(&empty);
    }

    #[test, expected_failure(abort_code = errors::E_INVALID_ARGUMENT)]
    fun dao_rejects_unknown_action() {
        sentinel_dao::validate_action_type(200);
    }

    #[test, expected_failure(abort_code = errors::E_LENGTH_MISMATCH)]
    fun treasury_rejects_mismatched_distribution_vectors() {
        treasury::validate_distribution_vectors(1, 2);
    }
}
