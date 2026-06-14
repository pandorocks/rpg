# Plan: Emoji & Difficulty Setup Screen

## Goal
Add a `/setup` screen that appears at the start of every new game. The player chooses:
1. An emoji avatar from a curated list.
2. A difficulty: Easy, Normal, Hard.

The chosen emoji is used as the player glyph. Difficulty modifies player and enemy stats during dungeon generation.

## Design decisions

### 1. Flow
When the player starts the app, presses `n` from the dungeon, or selects "New game" from the command palette, the app navigates to `/setup`. After the player confirms their choices with `enter`, the game generates a dungeon with those settings and navigates to `/`.

### 2. State storage
A new `SetupState < ApplicationState` stores:
- `emoji_index` — index into the curated emoji list
- `difficulty_index` — index into difficulties

The actual generation settings (emoji string, difficulty name, multipliers) are computed at runtime from these indices.

### 3. Emoji list
Curated avatars:
- `🧙‍♂️` Wizard
- `🥷` Ninja
- `🦸` Superhero
- `🧟` Zombie
- `🐱` Cat
- `🤖` Robot
- `👻` Ghost
- `🐲` Dragon

The chosen emoji is passed to `MapComponent` and used as the player overlay.

### 4. Difficulty modifiers
| Difficulty | Player HP | Player Damage | XP Gain | Enemy HP | Enemy Damage |
|------------|-----------|---------------|---------|----------|--------------|
| Easy       | ×1.5      | ×1.5          | ×1.5    | ×0.7     | ×0.5         |
| Normal     | ×1.0      | ×1.0          | ×1.0    | ×1.0     | ×1.0         |
| Hard       | ×0.7      | ×0.7          | ×0.7    | ×1.5     | ×1.5         |

These multipliers are applied during dungeon generation and when awarding XP.

### 5. Where modifiers are applied
- `DungeonGenerator.generate` accepts `difficulty:` keyword.
- A new `GameBalance` module under `app/models/` computes adjusted stats.
- `World#gain_xp` (via `Combat.gain_xp`) applies the XP multiplier.

### 6. Files to create / modify

#### New files
- `app/controllers/setup_controller.rb`
- `app/state/setup_state.rb`
- `app/views/setup/show_view.rb`
- `app/models/game_balance.rb`

#### Modified files
- `config/routes.rb` — add `/setup` route.
- `app/controllers/application_controller.rb` — "New game" navigates to `/setup` instead of immediately creating a world.
- `app/controllers/dungeon_controller.rb` — `new_game` navigates to `/setup`; pass `player_glyph` to view.
- `app/controllers/game_over_controller.rb` — `new_game` navigates to `/setup`.
- `app/views/dungeon/show_view.rb` — pass `player_glyph` from controller to `MapComponent`.
- `app/components/map_component.rb` — already supports `player_glyph:` assign.
- `app/models/dungeon_generator.rb` — accept `difficulty:` and apply stat modifiers to player and enemies.
- `app/models/world.rb` — store `difficulty` so XP awards can apply the multiplier after deserialization.
- `app/models/combat.rb` — apply difficulty XP multiplier.
- `app/components/help_overlay.rb` — note that `n` goes to setup first.
- `README.md` — document setup screen and difficulties.

### 7. Controller behavior
- `setup#show` renders two lists side by side: emojis on the left, difficulties on the right.
- `tab` switches between the two lists.
- Arrow keys / `j`/`k` navigate within the active list.
- `enter` confirms and starts the game.
- `escape` or `q` cancels and returns to the dungeon (or quits if no world exists yet).

### 8. Testing plan
- `GameBalance` unit specs for each difficulty.
- `SetupController` specs: renders lists, switches tabs, confirms with enter.
- `DungeonGenerator` specs: verify adjusted stats for easy/hard.
- `Combat` specs: verify XP multiplier.
- Integration: new game flow goes `/setup` → `/` with chosen settings.

### 9. MVP scope
- Single setup screen with emoji + difficulty lists.
- Modifiers applied to player and enemy generation.
- XP multiplier on kills.
- Settings reset per new game.

## Open questions
None — ready to implement.
