%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_lt, assert_le, assert_not_zero, assert_lt_felt, unsigned_div_rem
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.alloc import alloc

from starkware.cairo.common.bitwise import bitwise_and

from contracts.utilities.authorization import (
    _only,
    _onlyAdmin,
)

from contracts.set_erc721.token_uri import (
    tokenURI_,
    _setTokenURI,
    URI,
)

from contracts.set_erc721.balance_enumerability import (
    _owner,
    _balance,
    _setTokenByOwner,
    _unsetTokenByOwner,
)

from contracts.set_erc721.transferability import (
    _onTransfer,
)

from contracts.set_erc721.link_to_briq_token import (
    IBriqContract,
    _briq_address,
)

from contracts.types import ShapeItem, LongShapeItem

from contracts.shape.guards import _check_nfts_ok
from contracts.shape.long_guards import _check_nfts_ok_l

############
############
# Assembly/Disassembly

from contracts.types import FTSpec

func _transferFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, index: felt, fts: FTSpec*):
    if index == 0:
        return()
    end
    let (address) = _briq_address.read()
    IBriqContract.transferFT_(address, sender, recipient, fts[index - 1].token_id, fts[index - 1].qty)
    return _transferFT(sender, recipient, index - 1, fts)
end


func _transferNFT{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (sender: felt, recipient: felt, index: felt, nfts: felt*):
    if index == 0:
        return()
    end
    let (address) = _briq_address.read()
    let (uid, material) = unsigned_div_rem(nfts[index - 1], 2**64)
    IBriqContract.transferOneNFT_(address, sender, recipient, material, nfts[index - 1])
    return _transferNFT(sender, recipient, index - 1, nfts)
end

from starkware.cairo.common.hash_state import (
    hash_init, hash_finalize, hash_update, hash_update_single
)

# To prevent people from generating collisions, we need the token_id to be random.
# However, we need it to be predictable for good UI.
# The solution adopted is to hash a hint. Our security becomes the chain hash security.
# To be able to store e.g. sha-256 IPFS data in the tokenURI, we reserve a few bits
# off the end for extra-URI storage when minting.
func _hashTokenId{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, uri_len: felt, uri: felt*) -> (token_id: felt):
    let hash_ptr = pedersen_ptr
    with hash_ptr:
        let (hash_state_ptr) = hash_init()
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, owner)
        let (hash_state_ptr) = hash_update_single(hash_state_ptr, token_id_hint)
        let (token_id) = hash_finalize(hash_state_ptr)
        # The magic number is (2**251 - 1) - (2**59 - 1), which leaves the top 192 bits for the token_id.
        let (token_id) = bitwise_and(token_id, 3618502788666131106986593281521497120414687020801267626232473039494981877760)
    end
    let pedersen_ptr = hash_ptr
    let (token_id) = _maybeAddPartOfTokenUri(token_id, uri_len, uri)
    return (token_id)
end

# If the token URI is two items long, and the second item fits in the remainder 59 bits,
# then store it there instead of writing another storage variable.
# NB: this will become an integral part of the token_id, so that even if the URI changes
# in the future, it won't change. As such, it's only a minting-time optimisation.
func _maybeAddPartOfTokenUri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (token_id: felt, uri_len: felt, uri: felt*) -> (token_id: felt):
    if uri_len == 2:
        let (rem) = bitwise_and(uri[1], 2**59 - 1)
        if uri[1] == rem:
            let token_id = token_id + uri[1]
            return (token_id)
        end
        return (token_id)
    end
    return (token_id)
end

@external
func assemble_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*):
    alloc_locals

    _only(owner)
    assert_not_zero(owner)
    # This can't actually overflow because calldata of 2^252 elements would break the universe first.
    assert_not_zero(fts_len + nfts_len)

    let (local token_id: felt) = _hashTokenId(owner, token_id_hint, uri_len, uri)

    let (curr_owner) = _owner.read(token_id)
    assert curr_owner = 0
    _owner.write(token_id, owner)

    let (balance) = _balance.read(owner)
    _balance.write(owner, balance + 1)

    _transferFT(owner, token_id, fts_len, fts)
    _transferNFT(owner, token_id, nfts_len, nfts)

    _setTokenByOwner(owner, token_id, 0)

    _setTokenURI(1, token_id, uri_len, uri)

    _onTransfer(0, owner, token_id)
    URI.emit(uri_len, uri, token_id)

    return ()
end

@external
func disassemble_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*):
    alloc_locals
    _only(owner)

    assert_not_zero(token_id)
    assert_not_zero(owner)

    let (local curr_owner) = _owner.read(token_id)
    assert curr_owner = owner
    _owner.write(token_id, 0)

    _transferFT(token_id, curr_owner, fts_len, fts)
    _transferNFT(token_id, curr_owner, nfts_len, nfts)

    let (balance) = _balance.read(owner)
    _balance.write(curr_owner, balance - 1)

    _unsetTokenByOwner(curr_owner, token_id)

    _onTransfer(curr_owner, 0, token_id)

    return ()
end

# TODO
@external
func updateBriqs_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id: felt,
        add_fts_len: felt, add_fts: FTSpec*,
        add_nfts_len: felt, add_nfts: felt*,
        remove_fts_len: felt, remove_fts: FTSpec*,
        remove_nfts_len: felt, remove_nfts: felt*,
        uri_len: felt, uri: felt*):
    alloc_locals
    _onlyAdmin()

    assert_not_zero(token_id)
    assert_not_zero(owner)

    let (local curr_owner) = _owner.read(token_id)
    assert curr_owner = owner

    _transferFT(owner, token_id, add_fts_len, add_fts)
    _transferNFT(owner, token_id, add_nfts_len, add_nfts)

    _transferFT(token_id, owner, remove_fts_len, remove_fts)
    _transferNFT(token_id, owner, remove_nfts_len, remove_nfts)

    # TODO: would be nice to be able to check that the set is not empty here.

    _setTokenURI(0, token_id, uri_len, uri)

    URI.emit(uri_len, uri, token_id)

    return ()
end

########################
########################
########################
########################
########################
########################

@external
func assemble_with_shape_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*, shape_len: felt, shape: ShapeItem*, target_shape_token_id: felt):

    assemble_(owner, token_id_hint, fts_len, fts, nfts_len, nfts, uri_len, uri)

    # Check that the passed shape does match what we'd expect.
    # NB -> This expects the NFTs to be sorted according to the shape sorting (which itself is standardised).
    # We don't actually need to check the shape sorting or duplicate NFTs, because:
    # - shape sorting would fail to match the target
    # - duplicated NFTs would fail to transfer.
    _check_nfts_ok(shape_len, shape, nfts_len, nfts)
    _check_ft_numbers_ok(fts_len, fts, shape_len, shape)

    # Check that the shape matches the target.
    # target_shape_token_id

    return ()
end

func _check_ft_numbers_ok{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, shape_len: felt, shape: ShapeItem*):
    if fts_len == 0:
        return ()
    end
    # TODO: this isn't efficient in case of many materials, but a more efficient version is somewhat tricky to write.
    _check_ft_number_ok(fts[0].token_id, fts[0].qty, shape_len, shape)
    return _check_ft_numbers_ok(fts_len - 1, fts + FTSpec.SIZE, shape_len, shape)
end

func _check_ft_number_ok{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (material: felt, nb_briqs: felt, shape_len: felt, shape: ShapeItem*):
    if shape_len == 0:
        with_attr error_message("Wrong number of briqs in shape"):
            assert nb_briqs = 0
        end
        return ()
    end
    let (nft) = is_le_felt(2**250, shape[0].color_nft_material * (2**(122)))
    if nft == 1:
        return _check_ft_number_ok(material, nb_briqs, shape_len - 1, shape + ShapeItem.SIZE)
    end
    let a = shape[0].color_nft_material / (2 ** 64)
    let b = material / (2 ** 64)
    let (is_same_mat) = is_le_felt(a - b, 2**187)
    if is_same_mat == 1:
        with_attr error_message("Wrong number of briqs in shape"):
            assert_not_zero(nb_briqs)
        end
        return _check_ft_number_ok(material, nb_briqs - 1, shape_len - 1, shape + ShapeItem.SIZE)
    else:
        return _check_ft_number_ok(material, nb_briqs, shape_len - 1, shape + ShapeItem.SIZE)
    end
end


func _check_ft_number_ok2{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (material: felt, nb_briqs: felt, shape_len: felt, shape: ShapeItem*):
    if shape_len == 0:
        with_attr error_message("Wrong number of briqs in shape"):
            assert nb_briqs = 0
        end
        return ()
    end
    let (nft) = bitwise_and(shape[0].color_nft_material, 2**128)
    if nft == 1:
        return _check_ft_number_ok(material, nb_briqs, shape_len - 1, shape + ShapeItem.SIZE)
    end
    let (material_shape) = bitwise_and(shape[0].color_nft_material, 2**128 - 1)
    if material_shape == material:
        with_attr error_message("Wrong number of briqs in shape"):
            assert_not_zero(nb_briqs)
        end
        return _check_ft_number_ok(material, nb_briqs - 1, shape_len - 1, shape + ShapeItem.SIZE)
    else:
        return _check_ft_number_ok(material, nb_briqs, shape_len - 1, shape + ShapeItem.SIZE)
    end
end

########################
########################
########################
########################
########################
########################

@external
func assemble_with_shape_long_{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (owner: felt, token_id_hint: felt, fts_len: felt, fts: FTSpec*, nfts_len: felt, nfts: felt*, uri_len: felt, uri: felt*, shape_len: felt, shape: LongShapeItem*, target_shape_token_id: felt):

    assemble_(owner, token_id_hint, fts_len, fts, nfts_len, nfts, uri_len, uri)

    # Check that the passed shape does match what we'd expect.
    # NB -> This expects the NFTs to be sorted according to the shape sorting (which itself is standardised).
    # We don't actually need to check the shape sorting or duplicate NFTs, because:
    # - shape sorting would fail to match the target
    # - duplicated NFTs would fail to transfer.
    _check_nfts_ok_l(shape_len, shape, nfts_len, nfts)
    _check_ft_numbers_ok_l(fts_len, fts, shape_len, shape)

    # Check that the shape matches the target.
    # target_shape_token_id

    return ()
end

func _check_ft_numbers_ok_l{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (fts_len: felt, fts: FTSpec*, shape_len: felt, shape: LongShapeItem*):
    if fts_len == 0:
        return ()
    end
    # TODO: this isn't efficient in case of many materials, but a more efficient version is somewhat tricky to write.
    _check_ft_number_ok_l(fts[0].token_id, fts[0].qty, shape_len, shape)
    return _check_ft_numbers_ok_l(fts_len - 1, fts + FTSpec.SIZE, shape_len, shape)
end

from starkware.cairo.common.math_cmp import is_le_felt


func _check_ft_number_ok_l{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr
    } (material: felt, nb_briqs: felt, shape_len: felt, shape: LongShapeItem*):
    if shape_len == 0:
        with_attr error_message("Wrong number of briqs in shape"):
            assert nb_briqs = 0
        end
        return ()
    end
    let (nft) = is_le_felt(2**64, shape[0].nft_material)
    if nft == 1:
        return _check_ft_number_ok_l(material, nb_briqs, shape_len - 1, shape + LongShapeItem.SIZE)
    end
    if shape[0].nft_material == material:
        with_attr error_message("Wrong number of briqs in shape"):
            assert_not_zero(nb_briqs)
        end
        return _check_ft_number_ok_l(material, nb_briqs - 1, shape_len - 1, shape + LongShapeItem.SIZE)
    else:
        return _check_ft_number_ok_l(material, nb_briqs, shape_len - 1, shape + LongShapeItem.SIZE)
    end
end
