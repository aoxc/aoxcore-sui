module aoxc::walrus_connector {
    use std::bcs;
    use std::vector;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    public struct WalrusAdminCap has key, store { id: UID }

    public struct WalrusArchive has key {
        id: UID,
        next_seq: u64,
        payload_blobs: Table<u64, BlobPointer>,
        hash_to_certified_id: Table<vector<u8>, vector<u8>>,
    }

    public struct BlobPointer has copy, drop, store {
        certified_id: vector<u8>,
        payload_hash: vector<u8>,
        tag: vector<u8>,
    }

    public struct BlobAnchored has copy, drop {
        seq: u64,
        certified_id: vector<u8>,
        tag: vector<u8>,
    }

    /// Minimal VC-like envelope for standardized long-term archival claims.
    public struct VerifiableCredential has copy, drop, store {
        version: u16,
        issuer: vector<u8>,
        subject: vector<u8>,
        claim_hash: vector<u8>,
        certified_id: vector<u8>,
    }

    public struct CredentialAnchored has copy, drop {
        claim_hash: vector<u8>,
        certified_id: vector<u8>,
    }

    struct ReputationCredentialClaim has copy, drop, store {
        user: address,
        score: u64,
        honesty_epoch: u64,
        evidence_hash: vector<u8>,
    }

    public struct ReputationCredentialAnchored has copy, drop {
        user: address,
        score: u64,
        certified_id: vector<u8>,
    }


    entry fun init(ctx: &mut TxContext) {
        let cap = WalrusAdminCap { id: object::new(ctx) };
        let archive = WalrusArchive {
            id: object::new(ctx),
            next_seq: 1,
            payload_blobs: table::new<u64, BlobPointer>(ctx),
            hash_to_certified_id: table::new<vector<u8>, vector<u8>>(ctx),
        };
        sui::transfer::share_object(archive);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    public fun validate_blob_inputs(payload_hash: &vector<u8>, certified_id: &vector<u8>, tag: &vector<u8>) {
        assert!(vector::length(payload_hash) > 0, errors::E_EMPTY_HASH);
        assert!(vector::length(certified_id) > 0, errors::E_EMPTY_HASH);
        assert!(vector::length(tag) > 0, errors::E_INVALID_ARGUMENT);
    }

    entry fun anchor_blob(
        _cap: &WalrusAdminCap,
        archive: &mut WalrusArchive,
        payload_hash: vector<u8>,
        certified_id: vector<u8>,
        tag: vector<u8>,
    ) {
        validate_blob_inputs(&payload_hash, &certified_id, &tag);
        assert!(!table::contains(&archive.hash_to_certified_id, &payload_hash), errors::E_ALREADY_EXISTS);
        let seq = archive.next_seq;
        archive.next_seq = seq + 1;
        let pointer = BlobPointer { certified_id: copy certified_id, payload_hash: copy payload_hash, tag: copy tag };
        table::add(&mut archive.payload_blobs, seq, pointer);
        table::add(&mut archive.hash_to_certified_id, payload_hash, certified_id);
        event::emit(BlobAnchored { seq, certified_id, tag });
    }

    public fun validate_credential_inputs(issuer: &vector<u8>, subject: &vector<u8>, claim_hash: &vector<u8>, certified_id: &vector<u8>) {
        assert!(vector::length(issuer) > 0, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(subject) > 0, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(claim_hash) > 0, errors::E_EMPTY_HASH);
        assert!(vector::length(certified_id) > 0, errors::E_EMPTY_HASH);
    }

    entry fun anchor_credential(
        _cap: &WalrusAdminCap,
        archive: &mut WalrusArchive,
        issuer: vector<u8>,
        subject: vector<u8>,
        claim_hash: vector<u8>,
        certified_id: vector<u8>,
    ) {
        validate_credential_inputs(&issuer, &subject, &claim_hash, &certified_id);
        assert!(!table::contains(&archive.hash_to_certified_id, &claim_hash), errors::E_ALREADY_EXISTS);
        let _vc = VerifiableCredential { version: 1, issuer, subject, claim_hash: copy claim_hash, certified_id: copy certified_id };
        table::add(&mut archive.hash_to_certified_id, copy claim_hash, copy certified_id);
        event::emit(CredentialAnchored { claim_hash, certified_id });
    }



    entry fun anchor_reputation_credential(
        _cap: &WalrusAdminCap,
        archive: &mut WalrusArchive,
        issuer: vector<u8>,
        user: address,
        score: u64,
        honesty_epoch: u64,
        evidence_hash: vector<u8>,
        certified_id: vector<u8>,
    ) {
        assert!(vector::length(&evidence_hash) > 0, errors::E_EMPTY_HASH);
        let claim = ReputationCredentialClaim { user, score, honesty_epoch, evidence_hash };
        let claim_hash = sui::hash::keccak256(&bcs::to_bytes(&claim));
        validate_credential_inputs(&issuer, &vector[114,101,112,117,116,97,116,105,111,110], &claim_hash, &certified_id);
        assert!(!table::contains(&archive.hash_to_certified_id, &claim_hash), errors::E_ALREADY_EXISTS);
        table::add(&mut archive.hash_to_certified_id, claim_hash, copy certified_id);
        event::emit(ReputationCredentialAnchored { user, score, certified_id });
    }

    public fun certified_id_for(archive: &WalrusArchive, payload_hash: vector<u8>): vector<u8> {
        assert!(table::contains(&archive.hash_to_certified_id, &payload_hash), errors::E_NOT_FOUND);
        *table::borrow(&archive.hash_to_certified_id, payload_hash)
    }
}
