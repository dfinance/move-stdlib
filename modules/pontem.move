address 0x1 {

/// Pontem is a governance module which handles balances merging. It's basically
/// a mediator or wrapper around money-related operations. It holds knowledge about
/// registered coins and rules of their usage. Also it lessens load from 0x1::Account
module Pontem {

    use 0x1::Event;
    use 0x1::Signer;

    const ERR_NON_ZERO_DEPOSIT: u64 = 105;
    const ERR_CANT_WITHDRAW: u64 = 106;

    resource struct T<Coin> {
        value: u128
    }

    resource struct Info<Coin> {
        denom: vector<u8>,
        decimals: u8,

        // for tokens
        is_token: bool,
        owner: address,
        total_supply: u128
    }

    public fun mint<Coin>(value: u128): T<Coin> {
        T<Coin> { value }
    }

    public fun destroy_zero<Coin>(coin: T<Coin>) {
        let T { value } = coin;
        assert(value == 0, ERR_NON_ZERO_DEPOSIT)
    }

    public fun value<Coin>(coin: &T<Coin>): u128 {
        coin.value
    }

    public fun zero<Coin>(): T<Coin> {
        T<Coin> { value: 0 }
    }

    public fun split<Coin>(coin: T<Coin>, amount: u128): (T<Coin>, T<Coin>) {
        let other = withdraw(&mut coin, amount);
        (coin, other)
    }

    public fun join<Coin>(coin1: T<Coin>, coin2: T<Coin>): T<Coin> {
        deposit(&mut coin1, coin2);
        coin1
    }

    public fun deposit<Coin>(coin: &mut T<Coin>, check: T<Coin>) {
        let T { value } = check; // destroy check
        coin.value = coin.value + value;
    }

    public fun withdraw<Coin>(coin: &mut T<Coin>, amount: u128): T<Coin> {
        assert(coin.value >= amount, ERR_CANT_WITHDRAW);
        coin.value = coin.value - amount;
        T { value: amount }
    }

    /// getter for denom. reads denom information from 0x1 resource
    public fun denom<Coin>(): vector<u8> acquires Info {
        *&borrow_global<Info<Coin>>(0x1).denom
    }

    /// getter for currency decimals
    public fun decimals<Coin>(): u8 acquires Info {
        borrow_global<Info<Coin>>(0x1).decimals
    }

    /// getter for is_token property of Info
    public fun is_token<Coin>(): bool acquires Info {
        borrow_global<Info<Coin>>(0x1).is_token
    }

    /// getter for total_supply property of Info
    public fun total_supply<Coin>(): u128 acquires Info {
        borrow_global<Info<Coin>>(0x1).total_supply
    }

    /// getter for owner property of Info
    public fun owner<Coin>(): address acquires Info {
        borrow_global<Info<Coin>>(0x1).owner
    }

    /// only 0x1 address and add denom descriptions, 0x1 holds information resource
    // TODO: disable register coin for everyone, allow to register PONT coin at genesis block.
    public fun register_coin<Coin: copyable>(denom: vector<u8>, decimals: u8) {
        let sig = create_signer(0x1);

        if (!exists<Info<Coin>>(0x1)) {
            move_to<Info<Coin>>(&sig, Info {
                denom,
                decimals,
                owner: 0x1,
                total_supply: 0,
                is_token: false
            });
        };

        destroy_signer(sig);
    }

    /// check whether sender is 0x1, helper method
    //fun assert_can_register_coin(account: &signer) {
    //    assert(Signer::address_of(account) == 0x1, 1);
    //}

    // ..... TOKEN .....
    // - Everyone can register his own token
    // - Owner has control over minting of his token, total supply and optional destruction
    // - Token can be destroyed only if total supply is returned

    const DECIMALS_MIN : u8 = 0;
    const DECIMALS_MAX : u8 = 18;

    /// Currently can't say we need another resource here.
    /// Token resource. Must be used with custom token type. Which means
    /// that first token creator must deploy a token module which will have
    /// empty type in it which should be then passed as type argument
    /// into Token::initialize() method.
    /// resource struct Token<Tok: copyable> {}

    /// This is the event data for TokenCreated event which can only be fired
    /// from this module, from Token::initialize() method.
    struct TokenCreatedEvent<Tok> {
        creator: address,
        total_supply: u128,
        denom: vector<u8>,
        decimals: u8
    }

    /// Initialize token. For this method to work user must provide custom
    /// resource type which he had previously created within his own module.
    public fun create_token<Tok: copyable>(
        account: &signer,
        total_supply: u128,
        decimals: u8,
        denom: vector<u8>
    ): T<Tok> {

        // check if this token type has never been registered
        assert(!exists<Info<Tok>>(0x1), 1);

        // no more than DECIMALS MAX is allowed
        assert(decimals >= DECIMALS_MIN && decimals <= DECIMALS_MAX, 20);

        let owner = Signer::address_of(account);

        register_token_info<Tok>(Info {
            denom: copy denom,
            decimals,
            owner,
            total_supply,
            is_token: true
        });

        // finally fire the TokenEmitted event
        Event::emit<TokenCreatedEvent<Tok>>(
            account,
            TokenCreatedEvent {
                creator: owner,
                total_supply,
                decimals,
                denom
            }
        );

        T<Tok> { value: total_supply }
    }

    /// Created Info resource must be attached to 0x1 address.
    fun register_token_info<Coin: copyable>(info: Info<Coin>) {
        let sig = create_signer(0x1);
        move_to<Info<Coin>>(&sig, info);
        destroy_signer(sig);
    }

    native fun create_signer(addr: address): signer;
    native fun destroy_signer(sig: signer);
}
}
