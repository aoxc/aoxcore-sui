module aoxc::walrus_connector {
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

    public fun certified_id_for(archive: &WalrusArchive, payload_hash: vector<u8>): vector<u8> {
        assert!(table::contains(&archive.hash_to_certified_id, &payload_hash), errors::E_NOT_FOUND);
        *table::borrow(&archive.hash_to_certified_id, payload_hash)
    }
}
