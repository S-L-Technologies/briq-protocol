%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
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

from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.Uint256_felt_conv import _felt_to_uint

//###########
//###########
//###########
// Storage variables.

// Partial enumerability.
@storage_var
func _token_by_owner(owner: felt, index: felt) -> (token_id: felt) {
}

namespace ERC721_enumerability {
    // Call this an ERC1155 extension, subset of balanceOfBatch
    // Returns the complete list of tokens.
    @view
    func balanceDetailsOf_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt
    ) -> (token_ids_len: felt, token_ids: felt*) {
        alloc_locals;
        let (local nfts: felt*) = alloc();
        let (nfts_full) = _NFTBalanceDetailsOfIdx(owner, 0, nfts);
        return (nfts_full - nfts, nfts);
    }

    func _NFTBalanceDetailsOfIdx{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, index: felt, nft_ids: felt*
    ) -> (token_ids: felt*) {
        let (token_id) = _token_by_owner.read(owner, index);
        if (token_id == 0) {
            return (nft_ids,);
        }
        nft_ids[0] = token_id;
        return _NFTBalanceDetailsOfIdx(owner, index + 1, nft_ids + 1);
    }

    // We don't implement full enumerability, just per-user
    @view
    func tokenOfOwnerByIndex_{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, index: felt
    ) -> (token_id: felt) {
        let (token_id) = _token_by_owner.read(owner, index);
        return (token_id,);
    }

    //###############
    // # Enumerability

    func _setTokenByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner, token_id, index
    ) {
        let (tok_id) = _token_by_owner.read(owner, index);
        if (tok_id == token_id) {
            return ();
        }
        if (tok_id == 0) {
            _token_by_owner.write(owner, index, token_id);
            return ();
        }
        return _setTokenByOwner(owner, token_id, index + 1);
    }

    // Unset the token id from the list. Swap and pop idiom.
    // NB: the item is asserted to be in the list.
    func _unsetTokenByOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner, token_id
    ) {
        return _unsetTokenByOwner_searchPhase(owner, token_id, 0);
    }

    // During the search phase, we check for a matching token ID.
    func _unsetTokenByOwner_searchPhase{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner, token_id, index) {
        let (tok) = _token_by_owner.read(owner, index);
        assert_not_zero(tok);
        if (tok == token_id) {
            return _unsetTokenByOwner_erasePhase(owner, 0, index + 1, index);
        }
        return _unsetTokenByOwner_searchPhase(owner, token_id, index + 1);
    }

    // During the erase phase, we pass the last known value and the slot to insert it in, and go one past the end.
    func _unsetTokenByOwner_erasePhase{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner, last_known_value, index, target_index) {
        let (tok) = _token_by_owner.read(owner, index);
        if (tok == 0) {
            assert_lt_felt(target_index, index);
            _token_by_owner.write(owner, target_index, last_known_value);
            _token_by_owner.write(owner, index - 1, 0);
            return ();
        }
        return _unsetTokenByOwner_erasePhase(owner, tok, index + 1, target_index);
    }
}
