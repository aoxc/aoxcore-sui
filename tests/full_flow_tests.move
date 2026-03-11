#[test_only]
module aoxc::full_flow_tests {
    use std::string;
    use std::vector;
    use aoxc::aoxc;
    use aoxc::bridge_payload;
    use aoxc::liquidity_manager;
    use aoxc::marketplace;
    use aoxc::relay;
    use aoxc::sentinel_dao;
    use aoxc::staking;
    use aoxc::treasury;

    fun xsender(): vector<u8> { b"12345678901234567890" }

    #[test]
    fun typed_flow_smoke() {
        let payload = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            42,
            string::utf8(b"Bridge halt request"),
            b"proof-root-1",
        );

        let pause_raw = bridge_payload::encode_pause_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_breaker(),
            44,
            string::utf8(b"decoded halt"),
            b"proof-root-3",
        );

        let decoded_pause = bridge_payload::decode_pause_payload(pause_raw);
        let pause_target = bridge_payload::target_module_bytes(&decoded_pause);
        let action = bridge_payload::new_governance_action(
            bridge_payload::schema_v1(),
            bridge_payload::kind_system_resume(),
            bridge_payload::target_breaker(),
            43,
            string::utf8(b"DAO resume after review"),
            b"proof-root-2",
        );

        relay::validate_report_type(relay::reputation_report_type());
        sentinel_dao::validate_action_type(bridge_payload::action_type(&action));
        treasury::validate_distribution_vectors(1, 1);
        aoxc::validate_status(aoxc::guarded_status_code());
        staking::validate_slash_bps(1000);
        staking::validate_reward_bps(1000);
        liquidity_manager::validate_dex(&string::utf8(b"cetus"));
        liquidity_manager::validate_slippage_bps(500);
        marketplace::validate_listing_inputs(&b"walrus-blob", &b"license-hash", 100);
        treasury::validate_yield_policy(true, false, 4000, 0, 4, 0);

        let _ = payload;
        let _ = decoded_pause;
        let _ = pause_target;
        let _ = action;
    }

    #[test]
    fun xlayer_asset_routes_decode() {
        let mint_raw = bridge_payload::encode_asset_mint_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_testnet_chain_id(),
            xsender(),
            bridge_payload::target_aoxc(),
            501,
            10,
            @0xA0,
            b"mint-proof",
        );
        let burn_raw = bridge_payload::encode_asset_burn_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_aoxc(),
            502,
            5,
            @0xB0,
            b"burn-proof",
        );

        let mint = bridge_payload::decode_asset_mint_payload(mint_raw);
        let burn = bridge_payload::decode_asset_burn_payload(burn_raw);
        assert!(bridge_payload::kind(&mint) == bridge_payload::kind_x_mint(), 2);
        assert!(bridge_payload::kind(&burn) == bridge_payload::kind_x_burn(), 2);
    }

    #[test]
    fun supports_evm_cardano_web_domains() {
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::ethereum_chain_id()), 10);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::base_chain_id()), 11);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::arbitrum_chain_id()), 12);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::cardano_mainnet_network_magic()), 13);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::cardano_preprod_network_magic()), 14);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::web_relay_prod_domain_id()), 15);
        assert!(bridge_payload::is_supported_chain_id(bridge_payload::web_relay_stage_domain_id()), 16);
    }


    #[test]
    fun can_build_payload_for_all_supported_domains() {
        let eth = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::ethereum_chain_id(),
            xsender(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            701,
            string::utf8(b"eth-halt"),
            b"eth-proof",
        );
        let cardano = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::cardano_mainnet_network_magic(),
            999_999,
            xsender(),
            bridge_payload::kind_system_resume(),
            bridge_payload::target_breaker(),
            702,
            string::utf8(b"cardano-resume"),
            b"cardano-proof",
        );
        let web = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::web_relay_prod_domain_id(),
            xsender(),
            bridge_payload::kind_fund_update(),
            bridge_payload::target_treasury(),
            703,
            string::utf8(b"web-fund-update"),
            b"web-proof",
        );

        let _ = eth;
        let _ = cardano;
        let _ = web;
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun typed_payload_rejects_zero_sender() {
        let _ = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            vector[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            9,
            string::utf8(b"invalid sender"),
            b"proof",
        );
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun typed_payload_rejects_empty_note() {
        let _ = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            12,
            string::utf8(b""),
            b"proof",
        );
    }

    #[test]
    #[expected_failure(abort_code = 16)]
    fun xlayer_asset_routes_reject_zero_amount() {
        let mint_raw = bridge_payload::encode_asset_mint_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_testnet_chain_id(),
            xsender(),
            bridge_payload::target_aoxc(),
            601,
            0,
            @0xA0,
            b"mint-proof",
        );

        let _ = bridge_payload::decode_asset_mint_payload(mint_raw);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun xlayer_asset_routes_reject_zero_recipient() {
        let burn_raw = bridge_payload::encode_asset_burn_payload(
            bridge_payload::schema_v1(),
            bridge_payload::xlayer_chain_id(),
            xsender(),
            bridge_payload::target_aoxc(),
            602,
            7,
            @0x0,
            b"burn-proof",
        );

        let _ = bridge_payload::decode_asset_burn_payload(burn_raw);
    }

    #[test]
    #[expected_failure(abort_code = 26)]
    fun typed_payload_rejects_unsupported_chain() {
        let _ = bridge_payload::new_bridge_payload(
            bridge_payload::schema_v1(),
            999_999,
            xsender(),
            bridge_payload::kind_system_halt(),
            bridge_payload::target_breaker(),
            91,
            string::utf8(b"invalid chain"),
            b"proof",
        );
    }
}
