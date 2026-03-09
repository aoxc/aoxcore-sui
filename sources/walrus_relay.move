module aoxc::walrus_relay {
    use std::string::String;
    use std::vector;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const E_EMPTY_BLOB_ID: u64 = 1;
    const E_EMPTY_ROOT: u64 = 2;

    public struct RelayAdminCap has key, store { id: UID }

    /// Shared Walrus index for heavy cross-chain logs + AI audit traces.
    public struct WalrusArchive has key {
        id: UID,
        namespace: String,
        latest_blob_id: vector<u8>,
        blob_count: u64,
        blobs: Table<vector<u8>, BlobMeta>,
    }

    public struct BlobMeta has copy, drop, store {
        root_hash: vector<u8>,
        chunk_count: u32,
        byte_size: u64,
        source_block: u64,
        archived_at_ms: u64,
    }

    public struct BlobIndexed has copy, drop {
        blob_id: vector<u8>,
        root_hash: vector<u8>,
        source_block: u64,
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
        let archive = WalrusArchive {
            id: object::new(ctx),
            namespace,
            latest_blob_id: vector::empty<u8>(),
            blob_count: 0,
            blobs: table::new<vector<u8>, BlobMeta>(ctx),
        };

        sui::transfer::share_object(archive);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// Register a Walrus blob commitment uploaded off-chain.
    entry fun archive_blob(
        _cap: &RelayAdminCap,
        archive: &mut WalrusArchive,
        blob_id: vector<u8>,
        root_hash: vector<u8>,
        chunk_count: u32,
        byte_size: u64,
        source_block: u64,
        clock: &Clock,
    ) {
        assert!(vector::length(&blob_id) > 0, E_EMPTY_BLOB_ID);
        assert!(vector::length(&root_hash) > 0, E_EMPTY_ROOT);

        let meta = BlobMeta {
            root_hash: copy root_hash,
            chunk_count,
            byte_size,
            source_block,
            archived_at_ms: clock::timestamp_ms(clock),
        };

        table::add(&mut archive.blobs, copy blob_id, meta);
        archive.latest_blob_id = copy blob_id;
        archive.blob_count = archive.blob_count + 1;

        event::emit(BlobIndexed { blob_id, root_hash, source_block });
    }

    public fun blob_count(archive: &WalrusArchive): u64 { archive.blob_count }
    public fun namespace(archive: &WalrusArchive): String { archive.namespace }
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
