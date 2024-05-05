#[starknet::interface]
trait LegacyBriqBalance<T> {
    fn balanceOfMaterial_(self: @T, owner: felt252, material: felt252) -> felt252;
    fn transferFT_(ref self: T, sender: felt252, recipient: felt252, material: felt252, qty: felt252);
}

#[dojo::contract(allow_ref_self)]
mod migrate_assets {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::info::get_tx_info;

    use briq_protocol::world_config::{get_world_config, AdminTrait};

    use briq_protocol::erc::mint_burn::{MintBurnDispatcher, MintBurnDispatcherTrait};
    use token::erc721::interface::{IERC721CamelOnlyDispatcher, IERC721CamelOnlyDispatcherTrait};
    use super::{LegacyBriqBalanceDispatcher, LegacyBriqBalanceDispatcherTrait};

    fn get_legacy_set_address() -> ContractAddress {
        let chain_id = get_tx_info().unbox().chain_id;
        if chain_id == 'SN_MAIN' {
            return starknet::contract_address_const::<0x01435498bf393da86b4733b9264a86b58a42b31f8d8b8ba309593e5c17847672>();
        } else {
            return starknet::contract_address_const::<0x038bf557306ab58c7e2099036b00538b51b37bdad3b8abc31220001fb5139365>();
        }
    }

    fn get_legacy_briq_address() -> ContractAddress {
        let chain_id = get_tx_info().unbox().chain_id;
        if chain_id == 'SN_MAIN' {
            return starknet::contract_address_const::<0x00247444a11a98ee7896f9dec18020808249e8aad21662f2fa00402933dce402>();
        } else {
            return starknet::contract_address_const::<0x0068eb19445f96b3c3775fba757de89ee8f44fda42dc08173a501acacd97853f>();
        }
    }

    #[external(v0)]
    fn migrate_legacy_set_briqs(self: @ContractState, set_id: felt252, qty: u128) {
        assert(qty != 0, 'bad qty');
        let caller = get_caller_address();
        let legacy_set = IERC721CamelOnlyDispatcher { contract_address: get_legacy_set_address() };
        assert(legacy_set.ownerOf(set_id.into()) == caller, 'not owner');

        // Check briqs spec matches
        assert(LegacyBriqBalanceDispatcher { contract_address: get_legacy_briq_address() }.balanceOfMaterial_(set_id, 1) == qty.into(), 'bad nb of briqs');
        // Transfer to the migrate contract, as we can't actually burn the NFTs
        legacy_set.transferFrom(caller, get_contract_address(), set_id.into());
        // At this point mint new briqs
        MintBurnDispatcher { contract_address: get_world_config(self.world_dispatcher.read()).briq }.mint(caller, 1, qty.into());
    }

    #[external(v0)]
    fn migrate_legacy_briqs(self: @ContractState, qty: u128) {
        assert(qty != 0, 'bad qty');
        let caller = get_caller_address();
        let legacy_briqs = LegacyBriqBalanceDispatcher { contract_address: get_legacy_briq_address() };
        assert(legacy_briqs.balanceOfMaterial_(caller.into(), 1) == qty.into(), 'bad nb of briqs');
        // Transfer to the migrate contract, as we can't actually burn the briqs
        legacy_briqs.transferFT_(caller.into(), get_contract_address().into(), 1, qty.into());
        // At this point mint new briqs
        MintBurnDispatcher { contract_address: get_world_config(self.world_dispatcher.read()).briq }.mint(caller, 1, qty.into());
    }

    #[external(v0)]
    fn admin_migrate_legacy_set_briqs(self: @ContractState, owner: ContractAddress, set_id: felt252, qty: u128) {
        // TEMP for migration
        self.world().only_admins(@get_caller_address());

        assert(qty != 0, 'bad qty');

        let legacy_set = IERC721CamelOnlyDispatcher { contract_address: get_legacy_set_address() };
        // Check briqs spec matches
        assert(LegacyBriqBalanceDispatcher { contract_address: get_legacy_briq_address() }.balanceOfMaterial_(set_id, 1) == qty.into(), 'bad nb of briqs');
        // Transfer to the migrate contract, as we can't actually burn the NFTs
        legacy_set.transferFrom(owner, get_contract_address(), set_id.into());
        // At this point mint new briqs
        MintBurnDispatcher { contract_address: get_world_config(self.world_dispatcher.read()).briq }.mint(owner, 1, qty.into());
    }
}
