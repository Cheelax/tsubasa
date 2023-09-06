/* Autogenerated file. Do not edit manually. */

import { defineComponent, Type as RecsType } from "@latticexyz/recs";
import type { World } from "@latticexyz/recs";

export function defineContractComponents(world: World) {
  return {
    Card: (() => {
      const name = "Card";
      return defineComponent(
        world,
        {
          token_id: RecsType.NumberArray,
          dribble: RecsType.Number,
          current_dribble: RecsType.Number,
          defense: RecsType.Number,
          current_defense: RecsType.Number,
          cost: RecsType.Number,
          role: RecsType.Number,
        },
        {
          metadata: {
            name: name,
          },
        }
      );
    })(),
    Game: (() => {
      const name = "Game";
      return defineComponent(
        world,
        {
          game_id: RecsType.Number,
          player1: RecsType.Number,
          player2: RecsType.Number,
          player1_score: RecsType.Number,
          player2_score: RecsType.Number,
          turn: RecsType.Number,
          outcome: RecsType.Number,
        },
        {
          metadata: {
            name: name,
          },
        }
      );
    })(),
    DeckCard: (() => {
      const name = "DeckCard";
      return defineComponent(
        world,
        {
          player: RecsType.Number,
          card_index: RecsType.Number,
          token_id: RecsType.Number,
          card_state: RecsType.Number, // VOIR ENUM?
          is_captain: RecsType.Boolean,
        },
        {}
      );
    })(),
    Player: (() => {
      const name = "Player";
      return defineComponent(
        world,
        {
          game_id: RecsType.Number,
          player: RecsType.Number,
          goalkeeper: RecsType.OptionalEntity,
          defender: RecsType.OptionalEntity,
          midfielder: RecsType.OptionalEntity,
          attacker: RecsType.OptionalEntity,
          remaining_energy: RecsType.Number,
        },
        {
          metadata: {
            name: name,
          },
        }
      );
    })(),
  };
}
