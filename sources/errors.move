module aoxc::errors {
    /// Common protocol abort codes shared by all AOXC-Sui modules.
    public const E_NOT_AUTHORIZED: u64 = 1;
    public const E_INVALID_ARGUMENT: u64 = 2;
    public const E_ALREADY_EXISTS: u64 = 3;
    public const E_NOT_FOUND: u64 = 4;
    public const E_TIMELOCK_PENDING: u64 = 5;
    public const E_TIMELOCK_EXPIRED: u64 = 6;
    public const E_VETOED: u64 = 7;
    public const E_REPLAY: u64 = 8;
    public const E_SIGNATURE_INVALID: u64 = 9;
    public const E_PROTOCOL_PAUSED: u64 = 10;
    public const E_SUPPLY_EXCEEDED: u64 = 11;
    public const E_INSUFFICIENT_BALANCE: u64 = 12;
    public const E_SCORE_TOO_LOW: u64 = 13;
    public const E_LENGTH_MISMATCH: u64 = 14;
}
