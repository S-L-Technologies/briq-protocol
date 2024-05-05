mod models;
mod constants;

use starknet::ContractAddress;

#[dojo::interface]
trait IBriqFactory {
    fn initialize(t: felt252, surge_t: felt252, buy_token: ContractAddress);
    fn buy(
        material: u64,
        amount_u32: u32
    );
}

#[dojo::contract(allow_ref_self)]
mod briq_factory {
    use starknet::{get_caller_address, ContractAddress, ClassHash};
    use starknet::get_block_timestamp;
    
    use briq_protocol::world_config::{get_world_config, AdminTrait};
    use briq_protocol::felt_math::FeltOrd;

    use briq_protocol::briq_factory::constants::{
        DECIMALS, INFLECTION_POINT, SLOPE, RAW_FLOOR, LOWER_FLOOR, LOWER_SLOPE, DECAY_PER_SECOND,
        SURGE_SLOPE, MINIMAL_SURGE, SURGE_DECAY_PER_SECOND, MIN_PURCHASE, BRIQ_MATERIAL
    };

    use briq_protocol::briq_factory::models::{BriqFactoryStore, BriqFactoryTrait};
    use briq_protocol::erc::mint_burn::{MintBurnDispatcher, MintBurnDispatcherTrait};

    #[derive(Drop, PartialEq, starknet::Event)]
    struct BriqsBought {
        buyer: ContractAddress,
        amount: u32,
        price: u128
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BriqsBought: BriqsBought,
    }

    #[starknet::interface]
    trait IERC20<TState> {
        fn transferFrom(
            ref self: TState, spender: ContractAddress, recipient: ContractAddress, amount: u256
        );
    }

    #[external(v0)]
    impl BriqFactory of super::IBriqFactory<ContractState> {
        fn initialize(self: @ContractState, world: IWorldDispatcher, t: felt252, surge_t: felt252, buy_token: ContractAddress) {
            world.only_admins(@get_caller_address());

            let mut briq_factory = BriqFactoryTrait::get_briq_factory(world);

            briq_factory.last_stored_t = t;
            briq_factory.surge_t = surge_t;
            briq_factory.buy_token = buy_token;
            briq_factory.last_purchase_time = starknet::info::get_block_timestamp();

            BriqFactoryTrait::set_briq_factory(world, briq_factory);
        }

        fn buy(
            self: @ContractState,
            world: IWorldDispatcher,
            material: u64,
            amount_u32: u32
        ) {
            let amount: felt252 = amount_u32.into();
            assert(amount >= MIN_PURCHASE(), 'amount too low !');

            let mut briq_factory = BriqFactoryTrait::get_briq_factory(world);

            let price = briq_factory.get_price(amount);
            //let t = briq_factory.get_current_t();
            //let surge_t = briq_factory.get_surge_t();

            // Transfer funds to receiver wallet
            // TODO: use something other than the super-admin address for this.
            let world_config = get_world_config(world);
            let buyer = get_caller_address();
            IERC20Dispatcher { contract_address: briq_factory.buy_token }
                .transferFrom(buyer, world_config.treasury, price.into());

            // update store (currently disabled)
            // briq_factory.last_purchase_time = get_block_timestamp();
            // briq_factory.last_stored_t = t + amount * DECIMALS();
            // briq_factory.surge_t = surge_t + amount * DECIMALS();
            // BriqFactoryTrait::set_briq_factory(world, briq_factory);

            //  mint briqs to buyer
            let amount_u128: u128 = amount.try_into().unwrap();

            MintBurnDispatcher { contract_address: world_config.briq }.mint(
                buyer,
                BRIQ_MATERIAL(),
                amount_u128,
            );

            emit!(
                world, BriqsBought { buyer, amount: amount_u32, price: price.try_into().unwrap() }
            );
        }
    }

    #[external(v0)]
    fn get_current_t(self: @ContractState) -> felt252 {
        let briq_factory = BriqFactoryTrait::get_briq_factory(self.world_dispatcher.read());
        briq_factory.get_current_t()
    }

    #[external(v0)]
    fn get_surge_t(self: @ContractState) -> felt252 {
        let briq_factory = BriqFactoryTrait::get_briq_factory(self.world_dispatcher.read());
        briq_factory.get_surge_t()
    }
}
