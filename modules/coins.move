address 0x1 {

/// Enum-like module to make generic type-matching possible, every coin which is
/// officially supported by blockchain (or peg-zone specifically) is added here.
/// Ideally this module should be auto-generated and rarely updated via consensus
module Coins {
    struct ETH has store {}
    struct BTC has store {}
    struct USDT has store {}

    struct Price<Curr1, Curr2> has store, key {
        value: u128
    }

    public fun get_price<Curr1: store, Curr2: store>(): u128 acquires Price {
        borrow_global<Price<Curr1, Curr2>>(0x1).value
    }

    public fun has_price<Curr1: store, Curr2: store>(): bool {
        exists<Price<Curr1, Curr2>>(0x1)
    }
}
}
