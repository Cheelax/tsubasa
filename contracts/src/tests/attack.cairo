use dojo::world::IWorldDispatcherTrait;
use starknet::testing::set_contract_address;
use option::OptionTrait;
use debug::PrintTrait;
use array::ArrayTrait;
use tsubasa::models::{Game, Card, Player, Roles, OutcomePrint, Placement};
use tsubasa::tests::utils::{create_game, get_players, spawn_world, count_cards_in_hand};
use serde::Serde;
use starknet::ContractAddress;
use traits::Into;
use tsubasa::systems::{
    IAttackDispatcher, IAttackDispatcherTrait, ICreateCardDispatcher, ICreateCardDispatcherTrait,
    IEndTurnDispatcher, IEndTurnDispatcherTrait, IPlaceCardDispatcher, IPlaceCardDispatcherTrait,
    create_card_system, place_card_system, end_turn_system, attack_system
};
use dojo::test_utils::{deploy_contract};


#[test]
#[available_gas(3000000000)]
fn test_attack_player1_scores_against_empty_board() {
    let world = spawn_world();
    let (player1, player2, _) = get_players();
    let game_id = create_game(world, player1, player2);
    set_contract_address(player1);

    let contract_create_card = deploy_contract(
        create_card_system::TEST_CLASS_HASH, array![].span()
    );
    let contract_place_card = deploy_contract(place_card_system::TEST_CLASS_HASH, array![].span());
    let contract_end_turn = deploy_contract(end_turn_system::TEST_CLASS_HASH, array![].span());
    let contract_attack = deploy_contract(attack_system::TEST_CLASS_HASH, array![].span());

    let create_card_system = ICreateCardDispatcher { contract_address: contract_create_card };
    let place_card_system = IPlaceCardDispatcher { contract_address: contract_place_card };
    let end_turn_system = IEndTurnDispatcher { contract_address: contract_end_turn };
    let attack_system = IAttackDispatcher { contract_address: contract_attack };
    // Token_id, Dribble, Defense, Cost, Role, is captain

    create_card_system.create_card(world, 0, 22, 17, 0, Roles::Attacker, true);
    // Player 1 plays
    // Card number in the deck, Roles::Defender
    place_card_system.place_card(world, game_id, 0, Roles::Defender);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 0, 'Wrong nb of cards drawn player1');

    // Player 2 skips his turn
    set_contract_address(player2);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');
    // Player 1 attacks and should win against empty board

    set_contract_address(player1);

    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');
    let game = get!(world, game_id, Game);
    assert(game.player1_score == 1, 'Player 1 wins vs empty board');
}

#[test]
#[available_gas(3000000000)]
fn test_attack_player1_defender_passes_enemy_midfielder() {
    let world = spawn_world();
    let (player1, player2, _) = get_players();
    let game_id = create_game(world, player1, player2);
    set_contract_address(player1);

    let contract_create_card = deploy_contract(
        create_card_system::TEST_CLASS_HASH, array![].span()
    );
    let contract_place_card = deploy_contract(place_card_system::TEST_CLASS_HASH, array![].span());
    let contract_end_turn = deploy_contract(end_turn_system::TEST_CLASS_HASH, array![].span());
    let contract_attack = deploy_contract(attack_system::TEST_CLASS_HASH, array![].span());

    let create_card_system = ICreateCardDispatcher { contract_address: contract_create_card };
    let place_card_system = IPlaceCardDispatcher { contract_address: contract_place_card };
    let end_turn_system = IEndTurnDispatcher { contract_address: contract_end_turn };
    let attack_system = IAttackDispatcher { contract_address: contract_attack };

    // Card for player 1
    // Token_id, Dribble, Defense, Cost, Role, is captain
    create_card_system.create_card(world, 0, 45, 5, 1, Roles::Defender, false);

    // Card for player 2
    create_card_system.create_card(world, 1, 1, 2, 0, Roles::Midfielder, false);

    // Player 1 plays
    // Card number in the deck, Roles::Defender
    place_card_system.place_card(world, game_id, 0, Roles::Defender);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 0, 'Wrong nb of cards drawn player1');

    // Player 2 plays
    set_contract_address(player2);
    place_card_system.place_card(world, game_id, 0, Roles::Midfielder);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    // Player 1 attacks
    set_contract_address(player1);
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    let game = get!(world, game_id, Game);
    assert(game.player1_score == 0, 'Player 1 passes midfielder');
    assert(game.player2_score == 0, 'Player 2 never attacked');

    let player1_board = get!(world, (game_id, player1), Player);
    assert(player1_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper should be empty');
    assert(player1_board.defender_placement == Placement::Field, 'Defender should not be empty');
    assert(
        player1_board.midfielder_placement == Placement::Outside, 'Midfielder 1 should be empty'
    );
    assert(player1_board.attacker_placement == Placement::Outside, 'Attacker should be empty');

    let player2_board = get!(world, (game_id, player2), Player);
    assert(player2_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper should be empty');
    assert(player2_board.defender_placement == Placement::Outside, 'Defender should be empty');
    assert(player2_board.midfielder_placement == Placement::Outside, 'Midfielder should be empty');
    assert(player2_board.attacker_placement == Placement::Outside, 'Attacker should be empty');

    let card = get!(world, (0, 0), Card);

    assert(card.token_id == 0, 'Wrong token id');
    assert(card.dribble == 45, 'Wrong dribble');
    assert(card.current_dribble == 46, 'Wrong current dribble');
    assert(card.defense == 5, 'Wrong defense');
    assert(card.current_defense == 4, 'Wrong current defense');
    assert(card.cost == 1, 'Wrong cost');
    assert(card.role == Roles::Defender, 'Wrong role');
}

#[test]
#[available_gas(3000000000)]
fn test_attack_player1_goalkeeper_gets_passed_enemy_defender() {
    let world = spawn_world();
    let (player1, player2, _) = get_players();
    let game_id = create_game(world, player1, player2);
    set_contract_address(player1);

    let contract_create_card = deploy_contract(
        create_card_system::TEST_CLASS_HASH, array![].span()
    );
    let contract_place_card = deploy_contract(place_card_system::TEST_CLASS_HASH, array![].span());
    let contract_end_turn = deploy_contract(end_turn_system::TEST_CLASS_HASH, array![].span());
    let contract_attack = deploy_contract(attack_system::TEST_CLASS_HASH, array![].span());

    let create_card_system = ICreateCardDispatcher { contract_address: contract_create_card };
    let place_card_system = IPlaceCardDispatcher { contract_address: contract_place_card };
    let end_turn_system = IEndTurnDispatcher { contract_address: contract_end_turn };
    let attack_system = IAttackDispatcher { contract_address: contract_attack };

    // Card for player 1
    // Token_id, Dribble, Defense, Cost, Role, is captain
    create_card_system.create_card(world, 0, 2, 1, 1, Roles::Defender, false);
    // Card for player 2
    create_card_system.create_card(world, 1, 45, 5, 1, Roles::Midfielder, false);

    // Player 1 plays
    // Card number in the deck, Roles::Goalkeeper
    place_card_system.place_card(world, game_id, 0, Roles::Goalkeeper);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 0, 'Wrong nb of cards drawn player1');

    // Player 2 plays
    set_contract_address(player2);
    place_card_system.place_card(world, game_id, 0, Roles::Defender);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    // Player 1 attacks
    set_contract_address(player1);
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    let game = get!(world, game_id, Game);
    assert(game.player1_score == 0, 'Player 1 passes midfielder');
    assert(game.player2_score == 0, 'Player 2 never attacked');

    let player1_board = get!(world, (game_id, player1), Player);

    let mut attacker_card = get!(world, (u256 { low: 0, high: 0 }), Card);
    assert(
        player1_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 1 should be empty'
    );
    assert(player1_board.defender_placement == Placement::Outside, 'Defender 1 should be empty');
    assert(
        player1_board.midfielder_placement == Placement::Outside, 'Midfielder 1 should be empty'
    );
    assert(player1_board.attacker_placement == Placement::Outside, 'Attacker 1 should be empty');

    set_contract_address(player2);
    let player2_board = get!(world, (game_id, player2), Player);
    assert(
        player2_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 2 should be empty'
    );
    assert(player2_board.defender_placement == Placement::Field, 'Defender 2 shouldnt be empty');
    assert(
        player2_board.midfielder_placement == Placement::Outside, 'Midfielder 2 should be empty'
    );
    assert(player2_board.attacker_placement == Placement::Outside, 'Attacker 2 should be empty');

    let card = get!(world, (1, 0), Card);
    assert(card.token_id == 1, 'Wrong token id');
    assert(card.dribble == 45, 'Wrong dribble');
    assert(card.current_dribble == 45, 'Wrong current dribble');
    assert(card.defense == 5, 'Wrong defense');
    assert(card.current_defense == 3, 'Wrong current defense');
    assert(card.cost == 1, 'Wrong cost');
    assert(card.role == Roles::Midfielder, 'Wrong role');
}

#[test]
#[available_gas(3000000000)]
fn test_attack_player1_goalkeeper_vs_goalkeeper_both_survive_then_both_get_passed() {
    let world = spawn_world();
    let (player1, player2, _) = get_players();
    let game_id = create_game(world, player1, player2);
    set_contract_address(player1);

    let contract_create_card = deploy_contract(
        create_card_system::TEST_CLASS_HASH, array![].span()
    );
    let contract_place_card = deploy_contract(place_card_system::TEST_CLASS_HASH, array![].span());
    let contract_end_turn = deploy_contract(end_turn_system::TEST_CLASS_HASH, array![].span());
    let contract_attack = deploy_contract(attack_system::TEST_CLASS_HASH, array![].span());

    let create_card_system = ICreateCardDispatcher { contract_address: contract_create_card };
    let place_card_system = IPlaceCardDispatcher { contract_address: contract_place_card };
    let end_turn_system = IEndTurnDispatcher { contract_address: contract_end_turn };
    let attack_system = IAttackDispatcher { contract_address: contract_attack };

    // Card for player 1
    // Token_id, Dribble, Defense, Cost, Role, is captain
    create_card_system.create_card(world, 1, 0, 1, 1, Roles::Goalkeeper, false);
    // Card for player 2
    create_card_system.create_card(world, 0, 0, 1, 1, Roles::Goalkeeper, false);

    // Player 1 plays
    // Card number in the deck, Roles::Goalkeeper
    place_card_system.place_card(world, game_id, 0, Roles::Goalkeeper);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 0, 'Wrong nb of cards drawn player1');

    // Player 2 plays
    set_contract_address(player2);
    place_card_system.place_card(world, game_id, 0, Roles::Goalkeeper);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    // Player 1 attacks
    set_contract_address(player1);
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    let player1_board = get!(world, (game_id, player1), Player);
    assert(
        player1_board.goalkeeper_placement == Placement::Field, 'Goalkeeper 1 shouldnt be empty'
    );
    assert(player1_board.defender_placement == Placement::Outside, 'Defender 1 should be empty');
    assert(
        player1_board.midfielder_placement == Placement::Outside, 'Midfielder 1 should be empty'
    );
    assert(player1_board.attacker_placement == Placement::Outside, 'Attacker 1 should be empty');
    let player2_board = get!(world, (game_id, player2), Player);
    assert(
        player2_board.goalkeeper_placement == Placement::Field, 'Goalkeeper 2 shouldnt be empty'
    );
    assert(player2_board.defender_placement == Placement::Outside, 'Defender 2 should be empty');
    assert(
        player2_board.midfielder_placement == Placement::Outside, 'Midfielder 2 should be empty'
    );
    assert(player2_board.attacker_placement == Placement::Outside, 'Attacker 2 should be empty');
    let card = get!(world, (0, 0), Card);
    assert(card.current_dribble == 1, 'Wrong current dribble 1');
    assert(card.current_defense == 1, 'Wrong current defense 1');
    let card = get!(world, (1, 0), Card);
    assert(card.current_dribble == 1, 'Wrong current dribble 2');
    assert(card.current_defense == 1, 'Wrong current defense 2');
    // Player 2 attacks
    set_contract_address(player2);
    let attack_calldata = array![game_id];
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 2, 'Wrong nb of cards drawn player1');
    let player1_board = get!(world, (game_id, player1), Player);
    assert(
        player1_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 1 should be empty'
    );
    assert(player1_board.defender_placement == Placement::Outside, 'Defender 1 should be empty');
    assert(
        player1_board.midfielder_placement == Placement::Outside, 'Midfielder 1 should be empty'
    );
    assert(player1_board.attacker_placement == Placement::Outside, 'Attacker 1 should be empty');

    let player2_board = get!(world, (game_id, player2), Player);
    assert(
        player2_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 2 should be empty'
    );
    assert(player2_board.defender_placement == Placement::Outside, 'Defender 2 should be empty');
    assert(
        player2_board.midfielder_placement == Placement::Outside, 'Midfielder 2 should be empty'
    );
    assert(player2_board.attacker_placement == Placement::Outside, 'Attacker 2 should be empty');

    let game = get!(world, game_id, Game);
    assert(game.player1_score == 0, 'Player 1 passes midfielder');
    assert(game.player2_score == 0, 'Player 2 never attacked');
}

#[test]
#[available_gas(3000000000)]
fn test_attack_player2_full_board_all_die_in_2_turns() {
    let world = spawn_world();
    let (player1, player2, _) = get_players();
    let game_id = create_game(world, player1, player2);
    set_contract_address(player1);

    let contract_create_card = deploy_contract(
        create_card_system::TEST_CLASS_HASH, array![].span()
    );
    let contract_place_card = deploy_contract(place_card_system::TEST_CLASS_HASH, array![].span());
    let contract_end_turn = deploy_contract(end_turn_system::TEST_CLASS_HASH, array![].span());
    let contract_attack = deploy_contract(attack_system::TEST_CLASS_HASH, array![].span());

    let create_card_system = ICreateCardDispatcher { contract_address: contract_create_card };
    let place_card_system = IPlaceCardDispatcher { contract_address: contract_place_card };
    let end_turn_system = IEndTurnDispatcher { contract_address: contract_end_turn };
    let attack_system = IAttackDispatcher { contract_address: contract_attack };

    // Card for player 1
    // Token_id, Dribble, Defense, Cost, Role, is captain
    create_card_system.create_card(world, 1, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 3, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 5, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 7, 1, 2, 0, Roles::Goalkeeper, false);

    // Card for player 2
    create_card_system.create_card(world, 0, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 2, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 4, 1, 2, 0, Roles::Goalkeeper, false);
    create_card_system.create_card(world, 6, 1, 2, 0, Roles::Goalkeeper, false);

    // Player 1 plays
    // Card number in the deck, Roles::Goalkeeper
    place_card_system.place_card(world, game_id, 0, Roles::Goalkeeper);
    place_card_system.place_card(world, game_id, 1, Roles::Defender);
    place_card_system.place_card(world, game_id, 2, Roles::Midfielder);
    place_card_system.place_card(world, game_id, 3, Roles::Attacker);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 0, 'Wrong nb of cards drawn player1');

    // Player 2 plays
    set_contract_address(player2);
    place_card_system.place_card(world, game_id, 0, Roles::Goalkeeper);
    place_card_system.place_card(world, game_id, 1, Roles::Defender);
    place_card_system.place_card(world, game_id, 2, Roles::Midfielder);
    place_card_system.place_card(world, game_id, 3, Roles::Attacker);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 1, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    // Player 1 attacks
    set_contract_address(player1);
    let attack_calldata = array![game_id];
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 1, 'Wrong nb of cards drawn player1');

    let player1_board = get!(world, (game_id, player1), Player);
    assert(
        player1_board.goalkeeper_placement == Placement::Field, 'Goalkeeper 1 shouldnt be empty'
    );
    assert(player1_board.defender_placement == Placement::Field, 'Defender 1 shouldnt be empty');
    assert(
        player1_board.midfielder_placement == Placement::Field, 'Midfielder 1 shouldnt be empty'
    );
    assert(player1_board.attacker_placement == Placement::Field, 'Attacker 1 shouldnt be empty');
    let player2_board = get!(world, (game_id, player2), Player);
    assert(
        player2_board.goalkeeper_placement == Placement::Field, 'Goalkeeper 2 shouldnt be empty'
    );
    assert(player2_board.defender_placement == Placement::Field, 'Defender 2 shouldnt be empty');
    assert(
        player2_board.midfielder_placement == Placement::Field, 'Midfielder 2 shouldnt be empty'
    );
    assert(player2_board.attacker_placement == Placement::Field, 'Attacker 2 shouldnt be empty');
    // Player 2 attacks
    set_contract_address(player2);
    attack_system.attack(world, game_id);
    end_turn_system.end_turn(world, game_id);
    assert(count_cards_in_hand(world, player2) == 2, 'Wrong nb of cards drawn player2');
    assert(count_cards_in_hand(world, player1) == 2, 'Wrong nb of cards drawn player1');

    let player1_board = get!(world, (game_id, player1), Player);
    assert(
        player1_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 1 should be empty'
    );

    assert(player1_board.defender_placement == Placement::Outside, 'Defender 1 should be empty');
    assert(
        player1_board.midfielder_placement == Placement::Outside, 'Midfielder 1 should be empty'
    );
    assert(player1_board.attacker_placement == Placement::Outside, 'Attacker 1 should be empty');

    let player2_board = get!(world, (game_id, player2), Player);

    assert(
        player2_board.goalkeeper_placement == Placement::Outside, 'Goalkeeper 2 should be empty'
    );
    assert(player2_board.defender_placement == Placement::Outside, 'Defender 2 should be empty');
    assert(
        player2_board.midfielder_placement == Placement::Outside, 'Midfielder 2 should be empty'
    );
    assert(player2_board.attacker_placement == Placement::Outside, 'Attacker 2 should be empty');

    let game = get!(world, game_id, Game);
    assert(game.player1_score == 0, 'Player 1 passes midfielder');
    assert(game.player2_score == 0, 'Player 2 never attacked');
}

