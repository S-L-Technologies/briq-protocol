use serde::Serde;
use starknet::ContractAddress;
use traits::{Into, TryInto};
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use zeroable::Zeroable;
use clone::Clone;

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use briq_protocol::erc::erc1155::models::{ERC1155Balance, increase_balance, decrease_balance};

use briq_protocol::types::{FTSpec, PackedShapeItem, AttributeItem};
use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};
use briq_protocol::cumulative_balance::{CUM_BALANCE_TOKEN, CB_ATTRIBUTES};
use briq_protocol::world_config::{WorldConfig};
use briq_protocol::attributes::attribute_group::{
    AttributeGroup, AttributeGroupTrait, AttributeGroupOwner
};

use debug::PrintTrait;

#[starknet::interface]
trait IAttributeHandler<ContractState> {
    fn assign(
        ref self: ContractState,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_group_id: u64,
        attribute_id: u64,
        shape: Array<PackedShapeItem>,
        fts: Array<FTSpec>,
    );
    fn remove(
        ref self: ContractState,
        set_owner: ContractAddress,
        set_token_id: felt252,
        attribute_group_id: u64,
        attribute_id: u64
    );
}

#[derive(Drop, PartialEq, starknet::Event)]
struct AttributeAssigned {
    set_token_id: felt252,
    attribute_group_id: u64,
    attribute_id: u64
}

#[derive(Drop, PartialEq, starknet::Event)]
struct AttributeRemoved {
    set_token_id: felt252,
    attribute_group_id: u64,
    attribute_id: u64
}

#[event]
#[derive(Drop, PartialEq, starknet::Event)]
enum Event {
    AttributeAssigned: AttributeAssigned,
    AttributeRemoved: AttributeRemoved,
}

fn assign_attributes(
    world: IWorldDispatcher,
    set_owner: ContractAddress,
    set_token_id: felt252,
    attributes: @Array<AttributeItem>,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    if attributes.len() == 0 {
        return;
    }
    assert(set_owner.is_non_zero(), 'owner cannot be zero');
    assert(set_token_id.is_non_zero(), 'token_id cannot be zero');

    let mut attr_span = attributes.span();
    loop {
        match attr_span.pop_front() {
            Option::Some(attribute) => {
                inner_attribute_assign(world, set_owner, set_token_id, *attribute, shape, fts);
            },
            Option::None => {
                break;
            }
        };
    };

    // Update the cumulative balance
    increase_balance(world, CUM_BALANCE_TOKEN(), set_token_id.try_into().unwrap(), CB_ATTRIBUTES(), attributes.len().into());
}

fn inner_attribute_assign(
    world: IWorldDispatcher,
    set_owner: ContractAddress,
    set_token_id: felt252,
    attribute: AttributeItem,
    shape: @Array<PackedShapeItem>,
    fts: @Array<FTSpec>,
) {
    assert(attribute.attribute_id != 0, 'attribute_id cannot be zero');

    let attribute_group = AttributeGroupTrait::get_attribute_group(
        world, attribute.attribute_group_id
    );

    // check attribute_group exists
    assert(
        attribute_group.owner.is_non_zero(), 'unregistered attribute_group_id'
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(0, set_token_id, attribute_id, 1);
            assert(0 == 1, 'TODO assign');
        },
        AttributeGroupOwner::Contract(contract_address) => {
            IAttributeHandlerDispatcher { contract_address }.assign(
                set_owner,
                set_token_id,
                attribute.attribute_group_id,
                attribute.attribute_id,
                shape.clone(),
                fts.clone()
            )
        },
    };

    emit!(
        world,
        AttributeAssigned {
            set_token_id: set_token_id,
            attribute_group_id: attribute.attribute_group_id,
            attribute_id: attribute.attribute_id
        }
    );
}

fn remove_attributes(
    world: IWorldDispatcher,
    set_owner: ContractAddress,
    set_token_id: felt252,
    attributes: Array<AttributeItem>
) {
    if attributes.len() == 0 {
        return ();
    }

    assert(set_owner.is_non_zero(), 'owner cannot be zero');
    assert(set_token_id.is_non_zero(), 'token_id cannt be zero');

    let mut attr_span = attributes.span();
    loop {
        match attr_span.pop_front() {
            Option::Some(attribute) => {
                remove_attribute_inner(world, set_owner, set_token_id, *attribute);
            },
            Option::None => {
                break;
            }
        };
    };

    // Update the cumulative balance
    decrease_balance(world, CUM_BALANCE_TOKEN(), set_token_id.try_into().unwrap(), CB_ATTRIBUTES(), attributes.len().into());
}

fn remove_attribute_inner(
    world: IWorldDispatcher,
    set_owner: ContractAddress,
    set_token_id: felt252,
    attribute: AttributeItem,
) {
    assert(attribute.attribute_id != 0, 'attribute_id cannot be zero');

    let attribute_group = AttributeGroupTrait::get_attribute_group(
        world, attribute.attribute_group_id
    );

    match attribute_group.owner {
        AttributeGroupOwner::Admin(address) => {
            //library_erc1155::transferability::Transferability::_transfer_burnable(set_token_id, 0, attribute_id, 1);
            assert(0 == 1, 'TODO remove');
        },
        AttributeGroupOwner::Contract(contract_address) => {
            IAttributeHandlerDispatcher { contract_address }.remove(
                set_owner,
                set_token_id,
                attribute.attribute_group_id,
                attribute.attribute_id,
            );
        },
    }

    emit!(
        world,
        AttributeRemoved {
            set_token_id,
            attribute_group_id: attribute.attribute_group_id,
            attribute_id: attribute.attribute_id
        }
    );
}

