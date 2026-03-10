module aoxc::liquidity_manager {
    use std::string::{Self, String};
    use std::vector;
    use aoxc::circuit_breaker;
    use aoxc::errors;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    const DEX_CETUS: vector<u8> = b"cetus";
    const DEX_HOP: vector<u8> = b"hop";

    public struct LiquidityAdminCap has key, store { id: UID }

    public struct LiquidityHub has key {
        id: UID,
        cetus_enabled: bool,
        hop_enabled: bool,
        max_slippage_bps: u16,
        swaps_count: u64,
        lp_ops_count: u64,
        tracked_liquidity_total: u64,
    }

    public struct SwapRouted has copy, drop { dex: String, amount_in: u64, min_out: u64 }
    public struct LiquidityRouted has copy, drop { dex: String, amount_a: u64, amount_b: u64 }


    public fun validate_slippage_bps(max_slippage_bps: u16) {
        assert!((max_slippage_bps as u64) <= 2_000, errors::E_POLICY_LIMIT);
    }

    public fun validate_dex(dex: &String) {
        let b = string::bytes(dex);
        let ok = b == DEX_CETUS || b == DEX_HOP;
        assert!(ok, errors::E_INVALID_ARGUMENT);
    }

    entry fun init(ctx: &mut TxContext) {
        let cap = LiquidityAdminCap { id: object::new(ctx) };
        let hub = LiquidityHub {
            id: object::new(ctx),
            cetus_enabled: true,
            hop_enabled: true,
            max_slippage_bps: 500,
            swaps_count: 0,
            lp_ops_count: 0,
            tracked_liquidity_total: 0,
        };

        sui::transfer::share_object(hub);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun set_dex_status(
        _cap: &LiquidityAdminCap,
        hub: &mut LiquidityHub,
        cetus_enabled: bool,
        hop_enabled: bool,
    ) {
        hub.cetus_enabled = cetus_enabled;
        hub.hop_enabled = hop_enabled;
    }

    entry fun set_max_slippage_bps(_cap: &LiquidityAdminCap, hub: &mut LiquidityHub, max_slippage_bps: u16) {
        validate_slippage_bps(max_slippage_bps);
        hub.max_slippage_bps = max_slippage_bps;
    }

    fun assert_dex_enabled(hub: &LiquidityHub, dex: &String) {
        let d = string::bytes(dex);
        if (d == DEX_CETUS) {
            assert!(hub.cetus_enabled, errors::E_POOL_NOT_ENABLED);
            return
        };
        if (d == DEX_HOP) {
            assert!(hub.hop_enabled, errors::E_POOL_NOT_ENABLED);
            return
        };
        assert!(false, errors::E_INVALID_ARGUMENT);
    }

    entry fun route_swap(
        breaker: &circuit_breaker::CircuitBreaker,
        hub: &mut LiquidityHub,
        dex: String,
        amount_in: u64,
        min_out: u64,
        slippage_bps: u16,
    ) {
        circuit_breaker::assert_live(breaker);
        validate_dex(&dex);
        assert_dex_enabled(hub, &dex);
        assert!(amount_in > 0 && min_out > 0, errors::E_AMOUNT_ZERO);
        assert!((slippage_bps as u64) <= (hub.max_slippage_bps as u64), errors::E_POLICY_LIMIT);

        hub.swaps_count = hub.swaps_count + 1;
        event::emit(SwapRouted { dex, amount_in, min_out });
    }

    entry fun route_add_liquidity(
        breaker: &circuit_breaker::CircuitBreaker,
        hub: &mut LiquidityHub,
        dex: String,
        amount_a: u64,
        amount_b: u64,
    ) {
        circuit_breaker::assert_live(breaker);
        validate_dex(&dex);
        assert_dex_enabled(hub, &dex);
        assert!(amount_a > 0 && amount_b > 0, errors::E_AMOUNT_ZERO);

        hub.lp_ops_count = hub.lp_ops_count + 1;
        hub.tracked_liquidity_total = hub.tracked_liquidity_total + amount_a + amount_b;
        event::emit(LiquidityRouted { dex, amount_a, amount_b });
    }

    public fun tracked_liquidity_total(hub: &LiquidityHub): u64 { hub.tracked_liquidity_total }
}

spec module {
    invariant forall h: LiquidityHub :: h.tracked_liquidity_total >= 0;
}
