/// price: eth_btc 4078
script {
    use 0x01::Coins;

    fun test_has_price() {
        assert(Coins::has_price<Coins::ETH, Coins::BTC>(), 1);
        assert(!Coins::has_price<Coins::ETH, Coins::USDT>(), 2);
    }
}

/// price: eth_btc 4078
/// price: btc_pont 20
script {
    use 0x01::Coins;
    use 0x01::PONT;

    fun test_get_price() {
        assert(Coins::get_price<Coins::ETH, Coins::BTC>() == 4078, 1);
        assert(Coins::get_price<Coins::BTC, PONT::T>() == 20, 2);
    }
}