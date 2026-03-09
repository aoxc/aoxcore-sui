module aoxc::aoxc {
    use std::string::{Self, String};
    use std::vector;
    use aoxc::errors;
    use aoxc::neural_bridge;
    use sui::clock::{Self, Clock};
    use std::vector;
    use sui::clock::{Self, Clock};
    use std::option;
    use std::string::String;
    use std::vector;
    use sui::coin::{Self, TreasuryCap};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    const E_SUPPLY_EXCEEDED: u64 = 2;
    const E_NOT_OWNER: u64 = 3;

    const STATUS_FRESH: u8 = 0;
    const STATUS_GUARDED: u8 = 1;
    const STATUS_RECOVERED: u8 = 2;

    public struct TreasuryAdminCap has key, store { id: UID }

    /// Coin-like supply metadata (enterprise ledger settings).
    public struct AoxcMetadata has key, store {
        id: UID,
        symbol: String,
        name: String,
        description: String,
        icon_url: String,
        project_url: String,
        decimals: u8,
    }

    /// Display template for explorers/frontends.
    public struct DisplayProfile has key, store {
        id: UID,
        title_template: String,
        subtitle_template: String,
        image_template: String,
    }

    /// Governance-controlled mint authority.
    public struct TreasuryAdminCap has key, store {
        id: UID,
    }

    /// AOXC supply controller.
    public struct Treasury has key {
        id: UID,
        max_supply: u64,
        minted_supply: u64,
    }

    /// Transferable AOXC unit with audit lineage (NFT-like visibility).
        decimals: u8,
    }

    /// Sui-native neural asset object; each unit can carry provenance and security history.
    public struct NeuralAsset has key, store {
        id: UID,
        owner: address,
        amount: u64,
        neural_status: u8,
        risk_score_bps: u16,
        repair_count: u64,
        last_audit_ms: u64,
        history_hashes: vector<vector<u8>>,
    }

    public struct AssetCheckpointed has copy, drop {
        owner: address,
        amount: u64,
        neural_status: u8,
        risk_score_bps: u16,
    }

    entry fun init(
        max_supply: u64,
        symbol: String,
        name: String,
        description: String,
        icon_url: String,
        project_url: String,
        decimals: u8,
        ctx: &mut TxContext,
    ) {
        let cap = TreasuryAdminCap { id: object::new(ctx) };
        let metadata = AoxcMetadata {
            id: object::new(ctx),
            symbol,
            name,
            description,
            icon_url,
            project_url,
            decimals,
        };
        let display = DisplayProfile {
            id: object::new(ctx),
            title_template: string::utf8(b"AOXC Neural Asset #{id}"),
            subtitle_template: string::utf8(b"status={neural_status} risk={risk_score_bps}bps"),
            image_template: string::utf8(b"{icon_url}"),
        };
        let treasury = Treasury { id: object::new(ctx), max_supply, minted_supply: 0 };

        sui::transfer::share_object(treasury);
        sui::transfer::transfer(metadata, tx_context::sender(ctx));
        sui::transfer::transfer(display, tx_context::sender(ctx));
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun mint_neural_asset(
        _cap: &TreasuryAdminCap,
        gateway: &neural_bridge::NeuralGateway,
    public struct AssetMinted has copy, drop {
        recipient: address,
        amount: u64,
        neural_status: u8,
    }

    public struct AssetTransferred has copy, drop {
        from: address,
        to: address,
        amount: u64,
    }

    public struct SecurityCheckpoint has copy, drop {
        owner: address,
        neural_status: u8,
        risk_score_bps: u16,
        checkpoint_hash: vector<u8>,
    }

    entry fun init(max_supply: u64, decimals: u8, ctx: &mut TxContext) {
        let cap = TreasuryAdminCap { id: object::new(ctx) };
        let treasury = Treasury {
            id: object::new(ctx),
            max_supply,
            minted_supply: 0,
            decimals,
        };

        sui::transfer::share_object(treasury);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    /// Mint a neural asset object carrying auditable security metadata.
    entry fun mint_neural_asset(
        _cap: &TreasuryAdminCap,
        treasury: &mut Treasury,
        recipient: address,
        amount: u64,
        initial_checkpoint_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        neural_bridge::assert_transfers_enabled(gateway);
        assert!(treasury.minted_supply + amount <= treasury.max_supply, errors::E_SUPPLY_EXCEEDED);

        treasury.minted_supply = treasury.minted_supply + amount;
        assert!(treasury.minted_supply + amount <= treasury.max_supply, E_SUPPLY_EXCEEDED);
        treasury.minted_supply = treasury.minted_supply + amount;

        let mut history = vector::empty<vector<u8>>();
        vector::push_back(&mut history, initial_checkpoint_hash);

        let asset = NeuralAsset {
            id: object::new(ctx),
            owner: recipient,
            amount,
            neural_status: STATUS_FRESH,
            risk_score_bps: 0,
            repair_count: 0,
            last_audit_ms: clock::timestamp_ms(clock),
            history_hashes: history,
        };
        sui::transfer::transfer(asset, recipient);
    }

    entry fun transfer_neural_asset(gateway: &neural_bridge::NeuralGateway, asset: NeuralAsset, to: address, ctx: &mut TxContext) {
        neural_bridge::assert_transfers_enabled(gateway);
        assert!(asset.owner == tx_context::sender(ctx), errors::E_NOT_AUTHORIZED);

        let NeuralAsset { id, owner: _, amount, neural_status, risk_score_bps, repair_count, last_audit_ms, history_hashes } = asset;
        let forwarded = NeuralAsset { id, owner: to, amount, neural_status, risk_score_bps, repair_count, last_audit_ms, history_hashes };
        sui::transfer::transfer(forwarded, to);
    }


        event::emit(AssetMinted {
            recipient,
            amount,
            neural_status: STATUS_FRESH,
        });
        sui::transfer::transfer(asset, recipient);
    }

    /// Owner-directed transfer preserving immutable security lineage.
    entry fun transfer_neural_asset(asset: NeuralAsset, to: address, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(asset.owner == sender, E_NOT_OWNER);

        let amount = asset.amount;
        let from = asset.owner;

        let NeuralAsset {
            id,
            owner: _,
            amount: amount_inner,
            neural_status,
            risk_score_bps,
            repair_count,
            last_audit_ms,
            history_hashes,
        } = asset;

        let forwarded = NeuralAsset {
            id,
            owner: to,
            amount: amount_inner,
            neural_status,
            risk_score_bps,
            repair_count,
            last_audit_ms,
            history_hashes,
        };

        event::emit(AssetTransferred { from, to, amount });
        sui::transfer::transfer(forwarded, to);
    }

    /// Governance/Sentinel checkpoint update for forensic trail.
    entry fun checkpoint_security(
        _cap: &TreasuryAdminCap,
        asset: &mut NeuralAsset,
        new_status: u8,
        new_risk_score_bps: u16,
        checkpoint_hash: vector<u8>,
        clock: &Clock,
    ) {
        asset.neural_status = new_status;
        asset.risk_score_bps = new_risk_score_bps;
        asset.last_audit_ms = clock::timestamp_ms(clock);
        vector::push_back(&mut asset.history_hashes, checkpoint_hash);

        event::emit(AssetCheckpointed {
            owner: asset.owner,
            amount: asset.amount,
            neural_status: asset.neural_status,
            risk_score_bps: asset.risk_score_bps,
        });
    }

    entry fun autonomous_repair(asset: &mut NeuralAsset, repair_checkpoint_hash: vector<u8>, clock: &Clock, ctx: &TxContext) {
        assert!(asset.owner == tx_context::sender(ctx), errors::E_NOT_AUTHORIZED);
        asset.neural_status = STATUS_RECOVERED;
        if (asset.risk_score_bps > 100) { asset.risk_score_bps = asset.risk_score_bps - 100; } else { asset.risk_score_bps = 0; };
        event::emit(SecurityCheckpoint {
            owner: asset.owner,
            neural_status: asset.neural_status,
            risk_score_bps: asset.risk_score_bps,
            checkpoint_hash,
        });
    }

    /// Autonomous repair primitive: downgrades risk and marks recovered posture.
    entry fun autonomous_repair(
        asset: &mut NeuralAsset,
        repair_checkpoint_hash: vector<u8>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(asset.owner == tx_context::sender(ctx), E_NOT_OWNER);

        asset.neural_status = STATUS_RECOVERED;
        if (asset.risk_score_bps > 100) {
            asset.risk_score_bps = asset.risk_score_bps - 100;
        } else {
            asset.risk_score_bps = 0;
        };
        asset.repair_count = asset.repair_count + 1;
        asset.last_audit_ms = clock::timestamp_ms(clock);
        vector::push_back(&mut asset.history_hashes, repair_checkpoint_hash);
    }

    public fun minted_supply(t: &Treasury): u64 { t.minted_supply }
    public fun max_supply(t: &Treasury): u64 { t.max_supply }
    public fun guarded_status_code(): u8 { STATUS_GUARDED }
    public fun minted_supply(treasury: &Treasury): u64 { treasury.minted_supply }
    public fun decimals(treasury: &Treasury): u8 { treasury.decimals }
    public fun status(asset: &NeuralAsset): u8 { asset.neural_status }
    public fun owner(asset: &NeuralAsset): address { asset.owner }
    public fun guarded_status_code(): u8 { STATUS_GUARDED }
    const EScoreRegression: u64 = 30;

    /// Canonical AOXC asset for Sui side liquidity + utility.
    public struct AOXC has drop {}

    /// Capability managed by governance/timelock for adjusting reputation.
    public struct ReputationAdminCap has key, store {
        id: UID,
    }

    /// Neural identity object carrying protocol reputation for an account.
    public struct NeuralId has key, store {
        id: UID,
        owner: address,
        alias: String,
        score: u64,
        last_sync_nonce: vector<u8>,
    }

    public struct NeuralIdUpdated has copy, drop {
        owner: address,
        score: u64,
    }

    entry fun init(
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let (treasury, metadata) = coin::create_currency<AOXC>(
            AOXC {},
            decimals,
            symbol,
            name,
            description,
            option::none(),
            ctx,
        );

        let cap = ReputationAdminCap { id: object::new(ctx) };
        sui::transfer::public_transfer(metadata, tx_context::sender(ctx));
        sui::transfer::transfer(treasury, tx_context::sender(ctx));
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun mint(
        treasury: &mut TreasuryCap<AOXC>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext,
    ) {
        let coins = coin::mint(treasury, amount, ctx);
        sui::transfer::public_transfer(coins, recipient);
    }

    entry fun create_neural_id(alias: String, ctx: &mut TxContext) {
        let owner = tx_context::sender(ctx);
        let id = NeuralId {
            id: object::new(ctx),
            owner,
            alias,
            score: 0,
            last_sync_nonce: vector::empty<u8>(),
        };
        sui::transfer::transfer(id, owner);
    }

    entry fun sync_reputation(
        _admin: &ReputationAdminCap,
        neural_id: &mut NeuralId,
        next_score: u64,
        sync_nonce: vector<u8>,
    ) {
        assert!(next_score >= neural_id.score, EScoreRegression);
        neural_id.score = next_score;
        neural_id.last_sync_nonce = sync_nonce;

        event::emit(NeuralIdUpdated {
            owner: neural_id.owner,
            score: neural_id.score,
        });
    }

    public fun score(neural_id: &NeuralId): u64 {
        neural_id.score
    }
}
