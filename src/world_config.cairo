use core::option::OptionTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use debug::PrintTrait;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const SYSTEM_CONFIG_ID: u32 = 1;

#[derive(Model, Copy, Drop, Serde)]
struct WorldConfig {
    #[key]
    config_id: u32,
    treasury: ContractAddress,
    
    briq: ContractAddress,
    generic_sets: ContractAddress,
    factory: ContractAddress,
    dojo_migration: ContractAddress,
}

#[derive(Model, Copy, Drop, Serde)]
struct SetContracts {
    #[key]
    contract: ContractAddress,
    is_active: bool
}

#[derive(Model, Copy, Drop, Serde)]
struct BoxContracts {
    #[key]
    contract: ContractAddress,
    is_active: bool
}

fn get_world_config(world: IWorldDispatcher) -> WorldConfig {
    get!(world, (SYSTEM_CONFIG_ID), WorldConfig)
}


trait AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool;
    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress);

    fn is_set_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool;
    fn is_box_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool;
}


impl AdminTraitImpl of AdminTrait {
    fn is_admin(self: IWorldDispatcher, addr: @ContractAddress) -> bool {
        if self.is_owner(*addr, 0) { // 0 == world
            return true;
        }
        false
    }

    fn only_admins(self: IWorldDispatcher, caller: @ContractAddress) {
        assert(self.is_admin(caller), 'Not authorized');
    }

    fn is_set_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool {
        get!(self, (caller), SetContracts).is_active
    }
    fn is_box_contract(self: IWorldDispatcher, caller: ContractAddress) -> bool {
        get!(self, (caller), BoxContracts).is_active
    }
}

#[starknet::interface]
trait ISetupWorld<ContractState> {
    fn execute(
        ref self: ContractState,
        world: IWorldDispatcher,
        treasury: ContractAddress,
        briq: ContractAddress,
        generic_sets: ContractAddress,
        factory: ContractAddress,
    );
    fn register_set_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_contract: ContractAddress,
        active: bool,
    );
    fn register_box_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        box_contract: ContractAddress,
        active: bool,
    );
}

#[dojo::contract(allow_ref_self)]
mod setup_world {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use super::{WorldConfig, AdminTrait, SetContracts, BoxContracts};
    use super::SYSTEM_CONFIG_ID;

    #[external(v0)]
    fn execute(
        ref self: ContractState,
        world: IWorldDispatcher,
        treasury: ContractAddress,
        briq: ContractAddress,
        generic_sets: ContractAddress,
        factory: ContractAddress,
    ) {
        world.only_admins(@get_caller_address());

        set!(
            world,
            (WorldConfig {
                config_id: SYSTEM_CONFIG_ID,
                treasury,
                briq,
                generic_sets,
                factory,
                dojo_migration: get!(world, (SYSTEM_CONFIG_ID), WorldConfig).dojo_migration,
            })
        );
        return ();
    }

    #[external(v0)]
    fn set_dojo_migration_contract(ref self: ContractState, world: IWorldDispatcher, dojo_migration: ContractAddress) {
        world.only_admins(@get_caller_address());
        let mut wc = get!(world, (SYSTEM_CONFIG_ID), WorldConfig);
        wc.dojo_migration = dojo_migration;
        set!(world, (wc));
    }

    #[external(v0)]
    fn register_set_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        set_contract: ContractAddress,
        active: bool,
    ) {
        world.only_admins(@get_caller_address());
        set!(
            world,
            SetContracts {
                contract: set_contract,
                is_active: active,
            }
        );
    }

    #[external(v0)]
    fn register_box_contract(
        ref self: ContractState,
        world: IWorldDispatcher,
        box_contract: ContractAddress,
        active: bool,
    ) {
        world.only_admins(@get_caller_address());
        set!(
            world,
            BoxContracts {
                contract: box_contract,
                is_active: active,
            }
        );
    }
}
