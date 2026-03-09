module aoxc::relay {
    use std::string::String;
    use std::vector;
    use aoxc::errors;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};

    const REPORT_GOVERNANCE: u8 = 1;
    const REPORT_REPUTATION: u8 = 2;
    const REPORT_BRIDGE: u8 = 3;

    public struct RelayAdminCap has key, store { id: UID }

    /// N-of-M attestor set to decentralize bridge/report trust.
    public struct AttestorQuorum has key {
        id: UID,
        attestor_pubkeys: vector<vector<u8>>,
        disabled_attestors: vector<vector<u8>>,
        threshold: u16,
        epoch: u64,
    }

    public struct PublicReportRelay has key {
        id: UID,
        namespace: String,
        latest_blob_id: vector<u8>,
        report_count: u64,
        reports: Table<vector<u8>, ReportMeta>,
    }

    public struct ReportMeta has copy, drop, store {
        report_type: u8,
        root_hash: vector<u8>,
        source_epoch: u64,
        created_at_ms: u64,
    }

    public struct ReportAnchored has copy, drop {
        blob_id: vector<u8>,
        report_type: u8,
        source_epoch: u64,
    }

    public fun reputation_report_type(): u8 { REPORT_REPUTATION }

    public fun validate_report_type(report_type: u8) {
        let valid = report_type == REPORT_GOVERNANCE || report_type == REPORT_REPUTATION || report_type == REPORT_BRIDGE;
        assert!(valid, errors::E_INVALID_ARGUMENT);
    }

    public fun assert_quorum_met(signers: u16, threshold: u16) {
        assert!(signers >= threshold, errors::E_QUORUM_NOT_MET);
    }

    fun contains_pk(list: &vector<vector<u8>>, pk: &vector<u8>): bool {
        let len = vector::length(list);
        let mut i = 0;
        while (i < len) {
            if (*vector::borrow(list, i) == *pk) return true;
            i = i + 1;
        };
        false
    }

    public fun assert_threshold_valid(attestor_count: u64, threshold: u16) {
        assert!(threshold > 0, errors::E_INVALID_ARGUMENT);
        assert!(attestor_count > 0, errors::E_INVALID_ARGUMENT);
        assert!((threshold as u64) <= attestor_count, errors::E_INVALID_ARGUMENT);
    }

    entry fun init(namespace: String, attestor_pubkeys: vector<vector<u8>>, threshold: u16, ctx: &mut TxContext) {
        assert_threshold_valid(vector::length(&attestor_pubkeys), threshold);

        let cap = RelayAdminCap { id: object::new(ctx) };
        let relay = PublicReportRelay {
            id: object::new(ctx),
            namespace,
            latest_blob_id: vector::empty<u8>(),
            report_count: 0,
            reports: table::new<vector<u8>, ReportMeta>(ctx),
        };
        let quorum = AttestorQuorum {
            id: object::new(ctx),
            attestor_pubkeys,
            disabled_attestors: vector::empty<vector<u8>>(),
            threshold,
            epoch: 1,
        };

        sui::transfer::share_object(relay);
        sui::transfer::share_object(quorum);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun update_quorum(_cap: &RelayAdminCap, quorum: &mut AttestorQuorum, next_threshold: u16) {
        assert_threshold_valid(vector::length(&quorum.attestor_pubkeys), next_threshold);
        quorum.threshold = next_threshold;
        quorum.epoch = quorum.epoch + 1;
    }

    entry fun add_attestor(_cap: &RelayAdminCap, quorum: &mut AttestorQuorum, pubkey: vector<u8>) {
        assert!(vector::length(&pubkey) > 0, errors::E_EMPTY_HASH);
        assert!(!contains_pk(&quorum.attestor_pubkeys, &pubkey), errors::E_ALREADY_EXISTS);
        vector::push_back(&mut quorum.attestor_pubkeys, pubkey);
        assert_threshold_valid(vector::length(&quorum.attestor_pubkeys), quorum.threshold);
        quorum.epoch = quorum.epoch + 1;
    }

    entry fun remove_attestor(_cap: &RelayAdminCap, quorum: &mut AttestorQuorum, pubkey: vector<u8>) {
        let len = vector::length(&quorum.attestor_pubkeys);
        let mut i = 0;
        let mut found = false;
        while (i < len) {
            if (*vector::borrow(&quorum.attestor_pubkeys, i) == pubkey) {
                vector::remove(&mut quorum.attestor_pubkeys, i);
                found = true;
                break
            };
            i = i + 1;
        };
        assert!(found, errors::E_NOT_FOUND);
        assert_threshold_valid(vector::length(&quorum.attestor_pubkeys), quorum.threshold);
        quorum.epoch = quorum.epoch + 1;
    }

    entry fun disable_attestor(_cap: &RelayAdminCap, quorum: &mut AttestorQuorum, pubkey: vector<u8>) {
        assert!(contains_pk(&quorum.attestor_pubkeys, &pubkey), errors::E_NOT_FOUND);
        assert!(!contains_pk(&quorum.disabled_attestors, &pubkey), errors::E_ALREADY_EXISTS);
        vector::push_back(&mut quorum.disabled_attestors, pubkey);
        quorum.epoch = quorum.epoch + 1;
    }

    public fun is_attestor_active(quorum: &AttestorQuorum, pubkey: &vector<u8>): bool {
        contains_pk(&quorum.attestor_pubkeys, pubkey) && !contains_pk(&quorum.disabled_attestors, pubkey)
    }

    entry fun anchor_report(
        _cap: &RelayAdminCap,
        quorum: &AttestorQuorum,
        signer_count: u16,
        relay: &mut PublicReportRelay,
        blob_id: vector<u8>,
        report_type: u8,
        root_hash: vector<u8>,
        source_epoch: u64,
        clock: &Clock,
    ) {
        assert_quorum_met(signer_count, quorum.threshold);
        assert!(vector::length(&blob_id) > 0, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(&root_hash) > 0, errors::E_EMPTY_HASH);
        validate_report_type(report_type);
        assert!(!table::contains(&relay.reports, &blob_id), errors::E_DUPLICATE_BLOB);

        let meta = ReportMeta { report_type, root_hash, source_epoch, created_at_ms: clock::timestamp_ms(clock) };
        table::add(&mut relay.reports, copy blob_id, meta);
        relay.latest_blob_id = copy blob_id;
        relay.report_count = relay.report_count + 1;

        event::emit(ReportAnchored { blob_id, report_type, source_epoch });
    }

    public fun assert_attested(
        relay: &PublicReportRelay,
        blob_id: vector<u8>,
        expected_report_type: u8,
        expected_root_hash: vector<u8>,
    ) {
        assert!(table::contains(&relay.reports, &blob_id), errors::E_NOT_FOUND);
        let meta = table::borrow(&relay.reports, blob_id);
        assert!(meta.report_type == expected_report_type, errors::E_INVALID_ARGUMENT);
        assert!(meta.root_hash == expected_root_hash, errors::E_INVALID_ARGUMENT);
    }

    public fun threshold(quorum: &AttestorQuorum): u16 { quorum.threshold }
    public fun epoch(quorum: &AttestorQuorum): u64 { quorum.epoch }
    public fun attestor_count(quorum: &AttestorQuorum): u64 { vector::length(&quorum.attestor_pubkeys) }
}
