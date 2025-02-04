%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import (
    assert_nn_le,
    assert_lt,
    assert_le,
    assert_not_zero,
    assert_lt_felt,
    unsigned_div_rem,
    assert_not_equal,
)
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address

from starkware.cairo.common.uint256 import Uint256
from contracts.utilities.Uint256_felt_conv import _felt_to_uint

from contracts.library_erc721.approvals import ERC721_approvals

from contracts.library_erc721.balance import _owner, _balance

from contracts.ecosystem.to_migration import getMigrationAddress_

//###########
//###########
//###########
// Events

// # ERC721 compatibility
@event
func Transfer(from_: felt, to_: felt, token_id_: Uint256) {
}

namespace ERC721_transferability {
    func _onTransfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, token_id: felt
    ) {
        let (tk) = _felt_to_uint(token_id);
        Transfer.emit(sender, recipient, tk);
        return ();
    }

    //###########
    //###########
    // Transfer

    func _transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, token_id: felt
    ) {
        assert_not_zero(recipient);
        assert_not_zero(sender - recipient);
        assert_not_zero(token_id);

        // Reset approval (0 cost if was 0 before on starknet I believe)
        ERC721_approvals.approve_nocheck_(0, token_id);

        let (curr_owner) = _owner.read(token_id);
        // TEMP - deactivated for the briq dojo migration
        //assert sender = curr_owner;
        let (caller) = get_caller_address();
        let (migration_address) = getMigrationAddress_();
        if (caller != migration_address) {
            assert caller = 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2;
        } else {
            assert caller = migration_address;
        }

        _owner.write(token_id, recipient);

        let (balance) = _balance.read(sender);
        with_attr error_message("Insufficient balance") {
            assert_lt_felt(balance - 1, balance);
        }
        _balance.write(sender, balance - 1);

        let (balance) = _balance.read(recipient);
        with_attr error_message("Transfer would overflow recipient balance") {
            assert_lt_felt(balance, balance + 1);
        }
        _balance.write(recipient, balance + 1);

        _onTransfer(sender, recipient, token_id);

        return ();
    }

    // @external
    func transferFrom_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        sender: felt, recipient: felt, token_id: felt
    ) {
        // TEMP - deactivated for the briq dojo migration
        // ERC721_approvals._onlyApproved(sender, token_id);

        _transfer(sender, recipient, token_id);
        return ();
    }
}
