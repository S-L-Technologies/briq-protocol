# Deployment process for Sepolia

sozo -P sepolia build

sozo -P sepolia migrate plan --world $WORLD_ADDRESS  --name briq_protocol --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo -P sepolia migrate apply --world $WORLD_ADDRESS  --name briq_protocol --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# Setup the world config
sozo -P sepolia execute $SETUP_WORLD_ADDR execute --calldata $WORLD_ADDRESS,$TREASURY_ADDRESS,$BRIQ_TOKEN,$SET_NFT,$FACTORY_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo -P sepolia execute $SETUP_WORLD_ADDR set_dojo_migration_contract --calldata $WORLD_ADDRESS,$MIGRATE_ASSETS_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# Setup the briq factory
sozo -P sepolia execute $FACTORY_ADDR initialize --calldata 2100000000000000000000000,0,$FEE_TOKEN_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# Authorize my Argent sepolia wallet so I can do the next steps on frontend
# TODO: use sozo for this, not sure how just yet.
starkli invoke $WORLD_ADDRESS grant_owner 0x00f0fcC3bAD0943E01990650306343D49264b54c8041D11255427eE788E10f7F 0 --keystore-password $KEYSTORE_PWD

# The rest is done via the frontend admin page.

####################################
# Source one of the setup scripts.

sozo build

sozo migrate --name briq_protocol --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
sozo migrate --world $WORLD_ADDRESS --name briq_protocol --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
#sozo migrate --plan --world $WORLD_ADDRESS --name briq_protocol --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# testnet
sozo migrate --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# Alternative testnet wallet
starkli invoke $WORLD_ADDRESS grant_owner 0x009fa2C8FB501C57140E79fc720ab7160E9BBF41186d89eC45722A1d1Eb4D567 0 --keystore-password $KEYSTORE_PWD

####################################
## Setup World config
sozo execute $SETUP_WORLD_ADDR execute --calldata $WORLD_ADDRESS,$TREASURY_ADDRESS,$BRIQ_TOKEN,$SET_NFT,$FACTORY_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
#starkli invoke $SETUP_WORLD_ADDR execute $WORLD_ADDRESS $TREASURY_ADDRESS $BRIQ_TOKEN $SET_NFT $FACTORY_ADDR --keystore-password $KEYSTORE_PWD

## Return World config
sozo model get WorldConfig 1 --world $WORLD_ADDRESS
#starkli call $WORLD_ADDRESS entity str:WorldConfig 1 1 0 4 4 251 251 251 251

sozo execute $SETUP_WORLD_ADDR set_dojo_migration_contract --calldata $WORLD_ADDRESS,$MIGRATE_ASSETS_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

####################################
## Setup briq_factory
sozo execute $FACTORY_ADDR initialize --calldata 2100000000000000000000000,0,$FEE_TOKEN_ADDR --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
#starkli invoke $FACTORY_ADDR initialize 0 0 $FEE_TOKEN_ADDR --keystore-password $KEYSTORE_PWD

## Return briq_factory config
sozo model get BriqFactoryStore 1 --world $WORLD_ADDRESS

####################################
####################################
#### Setup authorizations
starkli invoke $WORLD_ADDRESS grant_owner 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2 0 --keystore-password $KEYSTORE_PWD
starkli invoke $WORLD_ADDRESS grant_owner 0x044Fb5366f2a8f9f8F24c4511fE86c15F39C220dcfecC730C6Ea51A335BC99CB 0 --keystore-password $KEYSTORE_PWD

# Done via frontend

# starkli invoke $WORLD_ADDRESS grant_writer str:WorldConfig $SETUP_WORLD_ADDR --keystore-password $KEYSTORE_PWD

# starkli invoke $SETUP_WORLD_ADDR register_set_contract $WORLD_ADDRESS $SET_NFT 1 --keystore-password $KEYSTORE_PWD --watch
# starkli invoke $SETUP_WORLD_ADDR register_set_contract $WORLD_ADDRESS $SET_NFT_ADDR_BRIQMAS 1 --keystore-password $KEYSTORE_PWD
# starkli invoke $SETUP_WORLD_ADDR register_box_contract $WORLD_ADDRESS $BOX_NFT_BRIQMAS 1 --keystore-password $KEYSTORE_PWD
# starkli invoke $SETUP_WORLD_ADDR register_box_contract $WORLD_ADDRESS $BOX_NFT_SP 1 --keystore-password $KEYSTORE_PWD

# starkli invoke $WORLD_ADDRESS grant_writer str:BriqFactoryStore $FACTORY_ADDR --keystore-password $KEYSTORE_PWD
# #sozo auth writer BriqFactoryStore $FACTORY_ADDR --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
# #sozo auth writer ERC1155Balance BriqFactoryMint --world $WORLD_ADDRESS --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

# starkli invoke $WORLD_ADDRESS grant_writer str:ERC1155Balance $BRIQ_TOKEN --keystore-password $KEYSTORE_PWD
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC1155Balance $BOX_ADDR --keystore-password $KEYSTORE_PWD
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC1155Balance $BOOKLET_ADDR_BRIQMAS --keystore-password $KEYSTORE_PWD
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC1155Balance $SET_NFT_ADDR_BRIQMAS --keystore-password $KEYSTORE_PWD

# starkli invoke $WORLD_ADDRESS grant_writer str:ERC721Balance $SET_NFT --keystore-password $KEYSTORE_PWD --watch
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC721Owner $SET_NFT --keystore-password $KEYSTORE_PWD --watch
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC721Balance $SET_NFT_ADDR_BRIQMAS --keystore-password $KEYSTORE_PWD --watch
# starkli invoke $WORLD_ADDRESS grant_writer str:ERC721Owner $SET_NFT_ADDR_BRIQMAS --keystore-password $KEYSTORE_PWD --watch

####################################
####################################
# Setup collections
starkli invoke $ATTR_GROUPS create_attribute_group $WORLD_ADDRESS 0x1 1 $BOOKLET_STARKNET_PLANET $SET_NFT_SP --keystore-password $KEYSTORE_PWD
starkli invoke $ATTR_GROUPS create_attribute_group $WORLD_ADDRESS 0x2 1 $BOOKLET_BRIQMAS $SET_NFT_BRIQMAS --keystore-password $KEYSTORE_PWD

starkli invoke $ATTR_GROUPS create_attribute_group $WORLD_ADDRESS 0x4 1 $BOOKLET_FRENS_DUCKS $SET_NFT_1155_FRENS_DUCKS --keystore-password $KEYSTORE_PWD

## Register briqmas shape
#starkli invoke $REGISTER_SHAPE_ADDR execute $WORLD_ADDRESS 0x2 0x1 0x65cb2a485b363d0d06ca965a55be5b171e3efb116ee2ceaf9ffc0250774e7c3 --keystore-password $KEYSTORE_PWD
starkli invoke $REGISTER_SHAPE_ADDR execute $WORLD_ADDRESS 0x1 0x4 0x02ce658601415217394890c2a35af37065c1a83c7497112ff4c40dfd113eb175 --keystore-password $KEYSTORE_PWD
starkli invoke $REGISTER_SHAPE_ADDR execute $WORLD_ADDRESS 0x4 0x1 0x8bf0f5ab7709c48d92e242737b1836b88cc06b1b604afdf816a0701607c474 --keystore-password $KEYSTORE_PWD

####################################
####################################
# Test - mint briqs

## approve EXECUTOR to spend 1eth FEE_TOKEN
starkli invoke $FEE_TOKEN_ADDR approve $FACTORY_ADDR u256:1000000000000000000 --keystore-password $KEYSTORE_PWD
starkli call $FEE_TOKEN_ADDR allowance $ACCOUNT_ADDRESS $FACTORY_ADDR

## Buy 1000 briqs with material_id=1 in briq_factory
# sozo execute BriqFactoryMint --world $WORLD_ADDRESS --calldata $ACCOUNT_ADDRESS,1,1000 --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD
starkli invoke $FACTORY_ADDR buy 1 1000 --keystore-password $KEYSTORE_PWD

## ACCOUNT_ADDRESS balance : BRIQ
starkli call $BRIQ_TOKEN balance_of $ACCOUNT_ADDRESS u256:1

starkli invoke $SET_NFT assemble $ACCOUNT_ADDRESS 341987491384 1 str:toto 1 str:desc 1 1 1 1 1 1 0 --keystore-password $KEYSTORE_PWD

sozo execute set_nft_assembly --world $WORLD_ADDRESS \
    --calldata "8904,\
$ACCOUNT_ADDRESS,\
3417423384,\
1,23423,\
1,41343,\
1,1,1,\
1,1,1,\
0"\
    --keystore $STARKNET_KEYSTORE --password $KEYSTORE_PWD

## Upgrade

starkli invoke $FACTORY_ADDR upgrade $FACTORY_HASH --keystore-password $KEYSTORE_PWD

starkli invoke $SET_NFT upgrade $SET_HASH --keystore-password $KEYSTORE_PWD

nonce=$(starkli nonce $ACCOUNT_ADDRESS)
starkli declare target/dev/briq_protocol-booklet_briqmas.json --nonce $nonce --max-fee 1  --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-booklet_ducks.json --nonce $nonce --max-fee 1  --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-booklet_frens_ducks.json --nonce $nonce --max-fee 1  --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-booklet_lil_ducks.json --nonce $nonce --max-fee 1  --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-booklet_starknet_planet.json --nonce $nonce --max-fee 1  --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-box_nft_briqmas.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-box_nft_sp.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft_1155_frens_ducks.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft_1155_lil_ducks.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft_briqmas.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft_ducks.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft_sp.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD
((nonce=$nonce+1))
starkli declare target/dev/briq_protocol-set_nft.json --nonce $nonce --max-fee 1 --keystore-password $KEYSTORE_PWD

starkli class-hash target/dev/briq_protocol-booklet_briqmas.json
starkli class-hash target/dev/briq_protocol-booklet_ducks.json
starkli class-hash target/dev/briq_protocol-booklet_frens_ducks.json
starkli class-hash target/dev/briq_protocol-booklet_lil_ducks.json
starkli class-hash target/dev/briq_protocol-booklet_starknet_planet.json
starkli class-hash target/dev/briq_protocol-box_nft_briqmas.json
starkli class-hash target/dev/briq_protocol-box_nft_sp.json
starkli class-hash target/dev/briq_protocol-set_nft_1155_frens_ducks.json
starkli class-hash target/dev/briq_protocol-set_nft_1155_lil_ducks.json
starkli class-hash target/dev/briq_protocol-set_nft_briqmas.json
starkli class-hash target/dev/briq_protocol-set_nft_ducks.json
starkli class-hash target/dev/briq_protocol-set_nft_sp.json
starkli class-hash target/dev/briq_protocol-set_nft.json

starkli invoke $BOX_ADDR upgrade $(starkli class-hash target/dev/briq_protocol-box_nft.json) --keystore-password $KEYSTORE_PWD

#######

starkli invoke $BOX_NFT_BRIQMAS mint 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2 10 1 --keystore-password $KEYSTORE_PWD
starkli invoke $BOX_NFT_BRIQMAS burn 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2 6 1 --keystore-password $KEYSTORE_PWD

starkli invoke $BOX_NFT_SP mint 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2 6 1 --keystore-password $KEYSTORE_PWD

starkli invoke $BOOKLET_FRENS_DUCKS mint 0x03eF5B02BCC5D30F3f0d35D55f365E6388fE9501ECA216cb1596940Bf41083E2 0x40000000000000001 1 --keystore-password $KEYSTORE_PWD
