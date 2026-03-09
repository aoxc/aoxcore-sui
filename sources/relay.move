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

    /// Walrus report index for governance, reputation and bridge transparency feeds.
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

    entry fun init(namespace: String, ctx: &mut TxContext) {
        let cap = RelayAdminCap { id: object::new(ctx) };
        let relay = PublicReportRelay {
            id: object::new(ctx),
            namespace,
            latest_blob_id: vector::empty<u8>(),
            report_count: 0,
            reports: table::new<vector<u8>, ReportMeta>(ctx),
        };

        sui::transfer::share_object(relay);
        sui::transfer::transfer(cap, tx_context::sender(ctx));
    }

    entry fun anchor_report(
        _cap: &RelayAdminCap,
        relay: &mut PublicReportRelay,
        blob_id: vector<u8>,
        report_type: u8,
        root_hash: vector<u8>,
        source_epoch: u64,
        clock: &Clock,
    ) {
        assert!(vector::length(&blob_id) > 0, errors::E_INVALID_ARGUMENT);
        assert!(vector::length(&root_hash) > 0, errors::E_EMPTY_HASH);
        validate_report_type(report_type);
        assert!(!table::contains(&relay.reports, &blob_id), errors::E_DUPLICATE_BLOB);

        let meta = ReportMeta {
            report_type,
            root_hash,
            source_epoch,
            created_at_ms: clock::timestamp_ms(clock),
        };
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
}
