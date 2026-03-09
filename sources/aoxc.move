module aoxc::aoxc {
    use std::string::{Self, String};
    use std::vector;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    const STATUS_FRESH: u8 = 0;
    const STATUS_GUARDED: u8 = 1;
    const STATUS_RECOVERED: u8 = 2;

    public struct TreasuryAdminCap has key, store { id: UID }

    /// Human-readable protocol metadata managed by governance.
    public struct AoxcMetadata has key, store {
        id: UID,
        symbol: String,
        name: String,
        description: String,
        icon_url: String,
        project_url: String,
        decimals: u8,
    }

    /// Explorer/UI display templates for NeuralAsset rendering.
    public struct DisplayProfile has key, store {
        id: UID,
        title_template: String,
        subtitle_template: String,
        image_template: String,
    }

    public struct Treasury has key {
        id: UID,
        max_supply: u64,
        minted_supply: u64,
    }

    /// Transferable asset object with immutable security lineage trail.
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

    public fun validate_status(status: u8) {
        let valid = status == STATUS_FRESH || status == STATUS_GUARDED || status == STATUS_RECOVERED;
        assert!(valid, errors::E_STATUS_INVALID);
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
        assert!(max_supply > 0, errors::E_INVALID_ARGUMENT);

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
        breaker: &circuit_breaker::CircuitBreaker,
        treasury: &mut Treasury,
        recipient: address,
        amount: u64,
        initial_checkpoint_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        assert!(amount > 0, errors::E_AMOUNT_ZERO);
        assert!(vector::length(&initial_checkpoint_hash) > 0, errors::E_EMPTY_HASH);
        assert!(treasury.minted_supply + amount <= treasury.max_supply, errors::E_SUPPLY_EXCEEDED);

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

    entry fun transfer_neural_asset(
        breaker: &circuit_breaker::CircuitBreaker,
        asset: NeuralAsset,
        to: address,
        ctx: &mut TxContext,
    ) {
        circuit_breaker::assert_live(breaker);
        assert!(asset.owner == tx_context::sender(ctx), errors::E_NOT_AUTHORIZED);

        let NeuralAsset {
            id,
            owner: _,
            amount,
            neural_status,
            risk_score_bps,
            repair_count,
            last_audit_ms,
            history_hashes,
        } = asset;

        let forwarded = NeuralAsset {
            id,
            owner: to,
            amount,
            neural_status,
            risk_score_bps,
            repair_count,
            last_audit_ms,
            history_hashes,
        };
        sui::transfer::transfer(forwarded, to);
    }

    entry fun checkpoint_security(
        _cap: &TreasuryAdminCap,
        asset: &mut NeuralAsset,
        new_status: u8,
        new_risk_score_bps: u16,
        checkpoint_hash: vector<u8>,
        clock: &Clock,
    ) {
        validate_status(new_status);
        assert!(vector::length(&checkpoint_hash) > 0, errors::E_EMPTY_HASH);

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

    entry fun autonomous_repair(
        asset: &mut NeuralAsset,
        repair_checkpoint_hash: vector<u8>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        assert!(asset.owner == tx_context::sender(ctx), errors::E_NOT_AUTHORIZED);
        assert!(vector::length(&repair_checkpoint_hash) > 0, errors::E_EMPTY_HASH);

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
}
