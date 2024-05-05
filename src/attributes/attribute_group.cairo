use starknet::ContractAddress;

use dojo::database::introspect::{
    Enum, Member, Ty, Struct, Introspect, serialize_member, serialize_member_type
};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use debug::PrintTrait;

impl SerdeLenAttributeGroupOwner of Introspect<AttributeGroupOwner> {
    #[inline(always)]
    fn size() -> usize {
        2
    }

    fn layout(ref layout: Array<u8>) {
        layout.append(8);
        layout.append(251);
    }

    #[inline(always)]
    fn ty() -> Ty {
        Ty::Enum(
            Enum {
                name: 'AttributeGroupOwner',
                attrs: array![].span(),
                children: array![
                    ('Admin', serialize_member_type(@Ty::Primitive('felt252'))),
                    ('Contract', serialize_member_type(@Ty::Primitive('felt252'))),
                ]
                    .span()
            }
        )
    }
}

impl PrintTraitAttributeGroupOwner of PrintTrait<AttributeGroupOwner> {
    fn print(self: AttributeGroupOwner) {
        match self {
            AttributeGroupOwner::Admin(addr) => addr.print(),
            AttributeGroupOwner::Contract(contract) => contract.print(),
        };
    }
}

// Implemented for 'is_non_zero'
impl AttributeGroupOwnerZeroable of Zeroable<AttributeGroupOwner> {
    fn zero() -> AttributeGroupOwner {
        AttributeGroupOwner::Admin(Zeroable::zero())
    }
    #[inline(always)]
    fn is_zero(self: AttributeGroupOwner) -> bool {
        match self {
            AttributeGroupOwner::Admin(addr) => addr.is_zero(),
            AttributeGroupOwner::Contract(contract) => contract.is_zero(),
        }
    }
    #[inline(always)]
    fn is_non_zero(self: AttributeGroupOwner) -> bool {
        !self.is_zero()
    }
}


#[derive(Copy, Drop, Serde)]
enum AttributeGroupOwner {
    Admin: ContractAddress,
    Contract: ContractAddress,
}

#[derive(Model, Copy, Drop, Serde)]
struct AttributeGroup {
    #[key]
    attribute_group_id: u64,
    owner: AttributeGroupOwner,
    target_set_contract_address: ContractAddress,
}


trait AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup;
    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup);
    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool;

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    ) -> AttributeGroup;
}

// #[generate_trait]
impl AttributeGroupImpl of AttributeGroupTrait {
    fn get_attribute_group(world: IWorldDispatcher, attribute_group_id: u64) -> AttributeGroup {
        get!(world, (attribute_group_id), AttributeGroup)
    }

    fn set_attribute_group(world: IWorldDispatcher, attribute_group: AttributeGroup) {
        set!(world, (attribute_group));
    }

    fn exists(world: IWorldDispatcher, attribute_group_id: u64) -> bool {
        let attribute_group = AttributeGroupTrait::get_attribute_group(world, attribute_group_id);
        attribute_group.target_set_contract_address.is_non_zero()
    }

    fn new_attribute_group(
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    ) -> AttributeGroup {
        assert(attribute_group_id > 0, 'invalid attribute_group_id');
        assert(
            !AttributeGroupTrait::exists(world, attribute_group_id),
            'attribute_group already exists'
        );
        assert(owner.is_non_zero(), 'Must have admin');
        AttributeGroup {
            attribute_group_id: attribute_group_id,
            owner: owner,
            target_set_contract_address,
        }
    }
}

#[starknet::interface]
trait IAttributeGroups<ContractState> {
    fn create_attribute_group(
        ref self: ContractState,
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    );
    fn update_attribute_group(
        ref self: ContractState,
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    );
}

#[dojo::contract(allow_ref_self)]
mod attribute_groups {
    use starknet::ContractAddress;
    use starknet::get_caller_address;

    use briq_protocol::erc::erc1155::models::ERC1155Balance;

    use briq_protocol::world_config::AdminTrait;
    use briq_protocol::types::{FTSpec, ShapeItem};
    use briq_protocol::felt_math::{FeltBitAnd, FeltOrd};

    use super::{AttributeGroupTrait, AttributeGroupOwner, AttributeGroup};

    #[derive(Drop, PartialEq, starknet::Event)]
    struct AttributeGroupCreated {
        attribute_group_id: u64,
        owner_admin: ContractAddress,
        owner_contract: ContractAddress,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct AttributeGroupUpdated {
        attribute_group_id: u64,
        owner_admin: ContractAddress,
        owner_contract: ContractAddress,
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        AttributeGroupCreated: AttributeGroupCreated,
        AttributeGroupUpdated: AttributeGroupUpdated,
    }

    #[external(v0)]
    fn create_attribute_group(
        ref self: ContractState,
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    ) {
        world.only_admins(@get_caller_address());

        let attribute_group = AttributeGroupTrait::new_attribute_group(
            world, attribute_group_id, owner, target_set_contract_address
        );

        AttributeGroupTrait::set_attribute_group(world, attribute_group);

        match owner {
            AttributeGroupOwner::Admin(address) => {
                emit!(
                    world,
                    AttributeGroupCreated {
                        attribute_group_id, owner_admin: address, owner_contract: Zeroable::zero()
                    }
                );
            },
            AttributeGroupOwner::Contract(contract) => {
                emit!(
                    world,
                    AttributeGroupCreated {
                        attribute_group_id, owner_admin: Zeroable::zero(), owner_contract: contract
                    }
                );
            },
        };
    }

    #[external(v0)]
    fn update_attribute_group(
        ref self: ContractState,
        world: IWorldDispatcher,
        attribute_group_id: u64,
        owner: AttributeGroupOwner,
        target_set_contract_address: ContractAddress,
    ) {
        world.only_admins(@get_caller_address());

        // check that attribute group already exists
        assert(
            AttributeGroupTrait::exists(world, attribute_group_id), 'unexisting attribute_group_id'
        );

        // update attribute_group
        AttributeGroupTrait::set_attribute_group(
            world,
            AttributeGroup {
                attribute_group_id, owner, target_set_contract_address
            }
        );

        match owner {
            AttributeGroupOwner::Admin(address) => {
                emit!(
                    world,
                    AttributeGroupUpdated {
                        attribute_group_id, owner_admin: address, owner_contract: Zeroable::zero()
                    }
                );
            },
            AttributeGroupOwner::Contract(contract) => {
                emit!(
                    world,
                    AttributeGroupUpdated {
                        attribute_group_id, owner_admin: Zeroable::zero(), owner_contract: contract
                    }
                );
            },
        };
    }
}
