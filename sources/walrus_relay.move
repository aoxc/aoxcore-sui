module aoxc::walrus_relay {
    use std::string::String;
    use std::vector;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    const EChunkCountMismatch: u64 = 10;

    public struct RelayAdminCap has key, store {
        id: UID,
    }

    /// Registry anchored on Sui for Walrus blobs containing heavy bridge logs.
    public struct WalrusRelay has key {
        id: UID,
        walrus_namespace: String,
        latest_blob_id: vector<u8>,
        archived_blob_count: u64,
    }

    /// Compact metadata for an archived bridge batch.
    public struct BlobCommitment has copy, drop, store {
        blob_id: vector<u8>,
        batch_root: vector<u8>,
        chunk_count: u32,
        byte_size: u64,
        xlayer_block: u64,
    }

    public struct BlobArchived has copy, drop {
        blob_id: vector<u8>,
        batch_root: vector<u8>,
        chunk_count: u32,
        byte_size: u64,
        xlayer_block: u64,
    }

    entry fun init(namespace: String, ctx: &mut TxContext) {
        let cap = RelayAdminCap { id: object::new(ctx) };
        let relay = WalrusRelay {
            id: object::new(ctx),
            walrus_namespace: namespace,
            latest_blob_id: vector::empty<u8>(),
            archived_blob_count: 0,
        };

        sui::transfer::share_object(relay);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// Stores verifiable metadata for a Walrus blob that was uploaded off-chain.
    /// `batch_root` should be a Merkle root for log chunk integrity checks.
    entry fun archive_blob(
        _cap: &RelayAdminCap,
        relay: &mut WalrusRelay,
        blob_id: vector<u8>,
        batch_root: vector<u8>,
        chunk_count: u32,
        byte_size: u64,
        xlayer_block: u64,
    ) {
        assert!(chunk_count > 0, EChunkCountMismatch);

        relay.latest_blob_id = blob_id;
        relay.archived_blob_count = relay.archived_blob_count + 1;

        event::emit(BlobArchived {
            blob_id,
            batch_root,
            chunk_count,
            byte_size,
            xlayer_block,
        });
    }

    public fun namespace(relay: &WalrusRelay): String {
        relay.walrus_namespace
    }

    public fun archived_count(relay: &WalrusRelay): u64 {
        relay.archived_blob_count
    }
}
