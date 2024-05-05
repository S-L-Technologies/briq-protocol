#[starknet::interface]
trait IUselessContract<TState> {
    fn i_request_additional_tps(self: @TState) -> felt252;
}

#[dojo::contract(allow_ref_self)]
mod ContractUpgrade {
    use super::IUselessContract;

    #[external(v0)]
    impl UselessContract of IUselessContract<ContractState> {
        fn i_request_additional_tps(self: @ContractState) -> felt252 {
            'father'
        }
    }
}
