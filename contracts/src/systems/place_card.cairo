use dojo::world::IWorldDispatcher;
use starknet::ContractAddress;
use tsubasa::models::Roles;

trait IPlaceCard<TContractState> {
    fn place_card(self: @TContractState, world: IWorldDispatcher, game_id: felt252, card_id: u8, position: Roles) -> ();
}

#[system]
mod place_card_system {
    use super::IPlaceCard;
    use array::ArrayTrait;
    use traits::Into;
    use starknet::info::{get_block_timestamp, get_block_number};
    use starknet::ContractAddress;

    use tsubasa::models::{Card, CardState, DeckCard, Game, Roles, Placement, Player};
    use tsubasa::systems::check_turn;
    use debug::PrintTrait;

    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    enum Event {
        CardPlaced: CardPlaced
    }

    #[derive(Copy, Drop, starknet::Event)]
    struct CardPlaced {
        game_id: felt252,
        player: ContractAddress,
        card_id: u8,
        position: Roles
    }

    impl PlaceCardImpl of IPlaceCard<ContractState> {
        fn place_card(self: @ContractState, world: IWorldDispatcher, game_id: felt252, card_id: u8, position: Roles) {
            let game = get!(world, game_id, Game);
            check_turn(@game, @starknet::get_caller_address());
            let game_player_key: (felt252, felt252) = (game_id, starknet::get_caller_address().into());
            let mut player = get!(world, (starknet::get_caller_address(), game_player_key), Player);
            let deck_card = get!(
                world, (Into::<ContractAddress, felt252>::into(starknet::get_caller_address()), card_id), DeckCard
            );
            let mut card = get!(world, (deck_card.token_id), Card);
            assert(player.remaining_energy >= card.cost.into(), 'Not enough energy');

            let is_on_its_role = match position {
                Roles::Goalkeeper => {
                    assert(player.goalkeeper.is_none(), 'Goalkeeper already placed');
                    player.goalkeeper = Option::Some((deck_card.token_id, Placement::Side));
                    card.role == Roles::Goalkeeper
                },
                Roles::Defender => {
                    assert(player.defender.is_none(), 'Defender already placed');
                    player.defender = Option::Some((deck_card.token_id, Placement::Side));
                    card.role == Roles::Defender
                },
                Roles::Midfielder => {
                    assert(player.midfielder.is_none(), 'Midfielder already placed');
                    player.midfielder = Option::Some((deck_card.token_id, Placement::Side));
                    card.role == Roles::Midfielder
                },
                Roles::Attacker => {
                    assert(player.attacker.is_none(), 'Attacker already placed');
                    player.attacker = Option::Some((deck_card.token_id, Placement::Side));
                    card.role == Roles::Attacker
                }
            };

            if is_on_its_role {
                card.current_dribble += 1;
                card.current_defense += 1;
            }
            if deck_card.is_captain {
                card.current_dribble += 1;
                card.current_defense += 1;
            }

            player.remaining_energy -= card.cost.into();
            set!(world, (card));
            set!(world, (player));
            emit!(
                world,
                CardPlaced { game_id, player: starknet::get_caller_address(), card_id: deck_card.card_index, position }
            )
        }
    }
}
