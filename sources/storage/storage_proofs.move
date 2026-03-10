module aoxc::storage_proofs {
    use std::vector;
    use aoxc::errors;

    public struct ProofSeal has copy, drop, store {
        payload_hash: vector<u8>,
        walrus_certified_id: vector<u8>,
    }

    public fun seal(payload_hash: vector<u8>, walrus_certified_id: vector<u8>): ProofSeal {
        assert!(vector::length(&payload_hash) > 0, errors::E_EMPTY_HASH);
        assert!(vector::length(&walrus_certified_id) > 0, errors::E_EMPTY_HASH);
        ProofSeal { payload_hash, walrus_certified_id }
    }
}
