use traits::{Into, TryInto, Default};
use option::{Option, OptionTrait};
use result::ResultTrait;
use array::ArrayTrait;
use serde::Serde;
use starknet::ContractAddress;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo_erc::erc_common::utils::{system_calldata};
use dojo_erc::erc721::interface::IERC721DispatcherTrait;
use dojo_erc::erc1155::interface::IERC1155DispatcherTrait;
use dojo_erc::erc1155::systems::ERC1155MintParams;

use briq_protocol::world_config::get_world_config;
use briq_protocol::attributes::attribute_manager::RegisterAttributeManagerParams;
use briq_protocol::types::{FTSpec, ShapeItem};
use briq_protocol::tests::test_utils::{
    WORLD_ADMIN, DEFAULT_OWNER, ZERO, DefaultWorld, deploy_default_world, mint_briqs, impersonate
};
use briq_protocol::tests::test_set_nft::create_attribute_group_with_booklet;

use debug::PrintTrait;

#[test]
#[available_gas(300000000)]
fn test_mint_and_unbox() {
    let DefaultWorld{world,
    briq_token,
    ducks_set,
    planets_set,
    ducks_booklet,
    planets_booklet,
    box_nft,
    .. } =
        deploy_default_world();

    // register attribute group 1
    create_attribute_group_with_booklet(
        world, 0x1, planets_set.contract_address, planets_booklet.contract_address
    );

    // mint a box id = 1  -->  starknet planets (BoxInfos { briq_1: 434, attribute_group_id: 1, attribute_id: 1 })
    world
        .execute(
            'ERC1155Mint',
            system_calldata(
                ERC1155MintParams {
                    token: get_world_config(world).box.into(),
                    operator: WORLD_ADMIN().into(),
                    to: DEFAULT_OWNER().into(),
                    ids: array![0x1], //  booklet_id == attribute_id
                    amounts: array![1],
                    data: array![],
                }
            )
        );

    impersonate(DEFAULT_OWNER());

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 0, 'bad balance');
    assert(planets_booklet.balance_of(DEFAULT_OWNER(), 0x1) == 0, 'bad balance 1');
    assert(box_nft.balance_of(DEFAULT_OWNER(), 1) == 1, 'bad balance 2');

    world.execute('box_unboxing', (array![0x1]));

    assert(briq_token.balance_of(DEFAULT_OWNER(), 1) == 434, 'bad balance 2.5');
    assert(planets_booklet.balance_of(DEFAULT_OWNER(), 0x1) == 1, 'bad balance 3');
    assert(box_nft.balance_of(DEFAULT_OWNER(), 1) == 0, 'bad balance 4');
}
