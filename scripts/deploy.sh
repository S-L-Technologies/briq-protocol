# Source one of the setup scripts.

sozo build

sozo migrate --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

export WORLD_ADDRESS=0x4ccc29ef7f190f202e5947c0458bb1699a2406599e559a6b1626096f3820da1
export EXECUTOR_ADDRESS=0x1c24cd47ab41ad1140f624ed133db38411bfa44d7f34e41551af819da9a78eb
  
echo "\nDeclaring class hashes ...\n"

export BRIQ_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-BriqToken.json --keystore-password $KEYSTORE_PWD)
export SET_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-SetNft.json --keystore-password $KEYSTORE_PWD)
export ERC1155_HASH=$(starkli declare --compiler-version 2.1.0 target/dev/briq_protocol-GenericERC1155.json --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo BRIQ_HASH=$BRIQ_HASH
echo SET_HASH=$SET_HASH
echo ERC1155_HASH=$ERC1155_HASH
echo "*************************************"

echo "\nDeploying contracts ...\n"

export BRIQ_ADDR=$(starkli deploy $BRIQ_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export SET_ADDR=$(starkli deploy $SET_HASH $WORLD_ADDRESS 'str:briq sets' 'str:B7' --keystore-password $KEYSTORE_PWD)
export DUCKS_ADDR=$(starkli deploy $SET_HASH $WORLD_ADDRESS 'str:ducks everywhere' 'str:DUCKS' --keystore-password $KEYSTORE_PWD)
export DUCK_BOOKLET_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)
export BOX_ADDR=$(starkli deploy $ERC1155_HASH $WORLD_ADDRESS --keystore-password $KEYSTORE_PWD)

echo "\n*************************************"
echo FEE_TOKEN_ADDR=$FEE_TOKEN_ADDR
echo BRIQ_ADDR=$BRIQ_ADDR
echo SET_ADDR=$SET_ADDR
echo DUCKS_ADDR=$DUCKS_ADDR
echo DUCK_BOOKLET_ADDR=$DUCK_BOOKLET_ADDR
echo BOX_ADDR=$BOX_ADDR
echo "*************************************"


## Setup World config
sozo execute SetupWorld --world $WORLD_ADDRESS --calldata $TREASURY_ADDRESS,$BRIQ_ADDR,$SET_ADDR,$BOOKLET_ADDR,$BOX_ADDR 

## Return World config
sozo component entity WorldConfig 1 --world $WORLD_ADDRESS 

## Setup briq_factory
sozo execute BriqFactoryInitialize --world $WORLD_ADDRESS --calldata 0,0,$FEE_TOKEN_ADDR

## Return briq_factory config
sozo component entity BriqFactoryStore 1 --world $WORLD_ADDRESS 

## approve EXECUTOR to spend 1eth FEE_TOKEN
starkli invoke $FEE_TOKEN_ADDR approve $EXECUTOR_ADDRESS u256:1000000000000000000 --keystore-password $KEYSTORE_PWD --watch
starkli call $FEE_TOKEN_ADDR allowance $ACCOUNT_ADDRESS $EXECUTOR_ADDRESS

## Buy 10000 briqs with material_id=1 in briq_factory
sozo execute BriqFactoryMint --world $WORLD_ADDRESS --calldata 1,10000

return


## ACCOUNT_ADDRESS balance : BRIQ
starkli call $BRIQ_ADDR balance_of $ACCOUNT_ADDRESS u256:1

## ACCOUNT_ADDRESS balance : ETH
# starkli balance $ACCOUNT_ADDRESS