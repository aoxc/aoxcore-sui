module aoxc::errors {
    /// Shared protocol-wide abort codes.
    public const E_NOT_AUTHORIZED: u64 = 1;
    public const E_INVALID_ARGUMENT: u64 = 2;
    public const E_ALREADY_EXISTS: u64 = 3;
    public const E_NOT_FOUND: u64 = 4;

    /// Governance and timing.
    public const E_TIMELOCK_PENDING: u64 = 5;
    public const E_TIMELOCK_EXPIRED: u64 = 6;
    public const E_VETOED: u64 = 7;

    /// Bridge security.
    public const E_REPLAY: u64 = 8;
    public const E_SIGNATURE_INVALID: u64 = 9;
    public const E_PROTOCOL_PAUSED: u64 = 10;

    /// Treasury and accounting.
    public const E_SUPPLY_EXCEEDED: u64 = 11;
    public const E_INSUFFICIENT_BALANCE: u64 = 12;
    public const E_SCORE_TOO_LOW: u64 = 13;
    public const E_LENGTH_MISMATCH: u64 = 14;

    /// Domain invariants.
    public const E_EMPTY_HASH: u64 = 15;
    public const E_AMOUNT_ZERO: u64 = 16;
    public const E_STATUS_INVALID: u64 = 17;
    public const E_DUPLICATE_BLOB: u64 = 18;
    public const E_ALREADY_FINALIZED: u64 = 19;

    /// Phase-2B/3 policy guards.
    public const E_POLICY_LIMIT: u64 = 20;
    public const E_ALREADY_CLAIMED: u64 = 21;
    public const E_SCHEMA_VERSION: u64 = 22;
    public const E_TARGET_NOT_ALLOWED: u64 = 23;
    public const E_CHECKSUM_MISMATCH: u64 = 24;
    public const E_QUORUM_NOT_MET: u64 = 25;
    public const E_CHAIN_ID_INVALID: u64 = 26;

    /// Phase-5 sovereign economy controls.
    public const E_SLASH_TOO_HIGH: u64 = 27;
    public const E_SLA_BREACH: u64 = 28;
    public const E_MARKETPLACE_LICENSE: u64 = 29;
    public const E_POOL_NOT_ENABLED: u64 = 30;
}
