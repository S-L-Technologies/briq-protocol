PROFILE=sepolia

export WORLD_ADDRESS=$(cat manifests/sepolia/manifest.json | jq ".world.address" -r)
export DOJO_WORLD_ADDRESS=$WORLD_ADDRESS

get_contract_address() {
    cat manifests/$PROFILE/manifest.json | jq ".contracts[] | select(.name == \"briq_protocol::$1\") | .address" -r
}

export SETUP_WORLD_ADDR=$(get_contract_address world_config::setup_world)
export ATTR_GROUPS=$(get_contract_address attributes::attribute_group::attribute_groups)
export REGISTER_SHAPE_ADDR=$(get_contract_address booklet::attribute::register_shape_validator)
export MIGRATE_ASSETS_ADDR=$(get_contract_address migrate::migrate_assets)
export FACTORY_ADDR=$(get_contract_address briq_factory::briq_factory)

export BOX_NFT_SP=$(get_contract_address tokens::box_nft_sp::box_nft_sp)
export BOX_NFT_BRIQMAS=$(get_contract_address tokens::box_nft_briqmas::box_nft_briqmas)
export BOOKLET_DUCKS=$(get_contract_address tokens::booklet_ducks::booklet_ducks)
export BOOKLET_STARKNET_PLANET=$(get_contract_address tokens::booklet_starknet_planet::booklet_starknet_planet)
export BOOKLET_BRIQMAS=$(get_contract_address tokens::booklet_briqmas::booklet_briqmas)
export BOOKLET_DUCKS_FRENS=$(get_contract_address tokens::booklet_ducks_frens::booklet_ducks_frens)
export BRIQ_TOKEN=$(get_contract_address tokens::briq_token::briq_token)
export SET_NFT=$(get_contract_address tokens::set_nft::set_nft)
export SET_NFT_DUCKS=$(get_contract_address tokens::set_nft_ducks::set_nft_ducks)
export SET_NFT_SP=$(get_contract_address tokens::set_nft_sp::set_nft_sp)
export SET_NFT_BRIQMAS=$(get_contract_address tokens::set_nft_briqmas::set_nft_briqmas)
export SET_NFT_1155_DUCKS_FRENS=$(get_contract_address tokens::set_nft_1155_ducks_frens::set_nft_1155_ducks_frens)

# For setup in JS / Python
echo "WORLD_ADDRESS=$WORLD_ADDRESS"
echo "SETUP_WORLD_ADDR=$SETUP_WORLD_ADDR"
echo "ATTR_GROUPS=$ATTR_GROUPS"
echo "REGISTER_SHAPE_ADDR=$REGISTER_SHAPE_ADDR"
echo "MIGRATE_ASSETS_ADDR=$MIGRATE_ASSETS_ADDR"
echo "FACTORY_ADDR=$FACTORY_ADDR"

echo "BOX_NFT_SP=$BOX_NFT_SP"
echo "BOX_NFT_BRIQMAS=$BOX_NFT_BRIQMAS"
echo "BOOKLET_DUCKS=$BOOKLET_DUCKS"
echo "BOOKLET_STARKNET_PLANET=$BOOKLET_STARKNET_PLANET"
echo "BOOKLET_BRIQMAS=$BOOKLET_BRIQMAS"
echo "BOOKLET_DUCKS_FRENS=$BOOKLET_DUCKS_FRENS"
echo "BRIQ_TOKEN=$BRIQ_TOKEN"
echo "SET_NFT=$SET_NFT"
echo "SET_NFT_DUCKS=$SET_NFT_DUCKS"
echo "SET_NFT_SP=$SET_NFT_SP"
echo "SET_NFT_BRIQMAS=$SET_NFT_BRIQMAS"
echo "SET_NFT_1155_DUCKS_FRENS=$SET_NFT_1155_DUCKS_FRENS"