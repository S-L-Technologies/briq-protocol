import os
import pytest

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/briq.cairo")

SET_CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/set.cairo")

@pytest.mark.asyncio
@pytest.fixture
async def starknet():
    # Create a new Starknet class that simulates the StarkNet
    return await Starknet.empty()

@pytest.mark.asyncio
@pytest.fixture
async def briq_contract(starknet):
    # Deploy the contract.
    return await starknet.deploy(CONTRACT_FILE)

@pytest.mark.asyncio
@pytest.fixture
async def set_contract(starknet):
    # Deploy the contract.
    return await starknet.deploy(SET_CONTRACT_FILE)


@pytest.mark.asyncio
async def test_micro(briq_contract, set_contract):
    await briq_contract.mint(owner=0x11, token_id=0x123, material=1).invoke()
    await briq_contract.mint(owner=0x11, token_id=0x124, material=2).invoke()
    await briq_contract.mint_multiple(owner=0x11, token_start=0x200, material=2, nb=3).invoke()
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x123, 1, 0,
        0x124, 2, 0,
        0x202, 2, 0,
        0x201, 2, 0,
        0x200, 2, 0
    ]

    await set_contract.initialize().invoke()
    await set_contract.set_briq_contract(briq_contract.contract_address).invoke()
    await set_contract.mint(owner=0x11, token_id=0x100, bricks=[0x123, 0x124, 0x200, 0x202]).invoke()

    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x123, 1, 0x100,
        0x124, 2, 0x100,
        0x202, 2, 0x100,
        0x201, 2, 0,
        0x200, 2, 0x100
    ]

    with pytest.raises(StarkException):
        await set_contract.disassemble(user=0x11, token_id=0xDeaD, bricks=[0x123, 0x201]).invoke()
    with pytest.raises(StarkException):
        await set_contract.disassemble(user=0x11, token_id=0x100, bricks=[0x123, 0x201]).invoke()
    await set_contract.disassemble(user=0x11, token_id=0x100, bricks=[0x123, 0x124, 0x200, 0x202]).invoke()
    assert (await briq_contract.get_all_tokens_for_owner(owner=0x11).call()).result[0] == [
        0x123, 1, 0,
        0x124, 2, 0,
        0x202, 2, 0,
        0x201, 2, 0,
        0x200, 2, 0
    ]

    with pytest.raises(StarkException):
        await set_contract.mint(owner=0x11, token_id=0x100, bricks=[0x123, 0x124, 0x123, 0x124]).invoke()

