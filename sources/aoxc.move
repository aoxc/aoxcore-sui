module aoxc::aoxc {
    use std::option;
    use std::string::String;
    use std::vector;
    use sui::coin::{Self, TreasuryCap};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

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
