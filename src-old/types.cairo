#[derive(Copy, Drop, Serde)]
struct FTSpec {
    token_id: felt252,
    qty: felt252,
}


#[derive(Copy, Drop, Serde)]
struct ShapeItem {
    // Material is 64 bit so this is COLOR as short string shifted 136 bits left, and material.
    // The 128th bit indicates 'This is an NFT', at which point you need to refer to the list of NFTs.
    // (I'm shifting colors by 7 more bits so that the corresponding hex is easily readable and I don't need more).
    color_nft_material: felt252,
    // Stored as reversed two's completement, shifted by 64 bits.
    // (reversed az in -> the presence of the 64th bit indicates positive number)
    // (This is done so that sorting works)
    x_y_z: felt252,
}
