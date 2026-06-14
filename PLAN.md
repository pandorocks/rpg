# Plan: Terminal Roguelike with Charming

## Goal
Build a turn-based ASCII roguelike named **RPG** (working title) in `/Users/pando/software/rpg`, using the local Charming framework at `/Users/pando/software/charming`. The game runs in the terminal with full keyboard control, procedural dungeons, combat, items, and a message log.

## Architecture decisions

### 1. Manual Charming scaffold (not `charming new`)
The built-in generator creates a sidebar/content app with a database. A roguelike is simpler as a full-screen game, so we’ll scaffold the minimum structure by hand:
- `Gemfile` → references `charming` via local path `../charming`.
- `lib/rpg.rb` → Zeitwerk loader for `app/` and `lib/rpg/`.
- `lib/rpg/application.rb` → registers a custom dungeon theme.
- `config/routes.rb` → single route `root "dungeon#show"`.
- `exe/rpg` → boots `Charming.run(Rpg::Application.new)`.

### 2. Controllers
- `ApplicationController` < `Charming::Controller`
  - `layout false` (full-screen game view, no sidebar wrapper).
  - Global keys: `q` quit, `?` help, `ctrl+p` command palette (Charming default), `r` rest one turn.
- `DungeonController` < `ApplicationController`
  - Movement keys: `h/j/k/l` and arrow keys.
  - Action keys: `g` get item, `>` descend stairs, `n` new game after death/win.
  - `show` action renders the dungeon view from `DungeonState`.
  - `move(dx, dy)` loads world, moves/attacks, runs enemy AI, saves world, renders.

### 3. State
- `DungeonState` < `Charming::ApplicationState`
  - Single attribute: `world_json` (`:string`).
  - Provides `world` (deserialize hash) and `world=(hash)` (serialize).
  - Because Charming controllers are ephemeral and session is the only persistent store, the entire game world lives in this JSON string. It is rebuilt on every key press, which is fine for a small dungeon.

### 4. World model (plain Ruby under `lib/rpg/`)
- `Rpg::World` — holds map grid, entities, player stats, messages, depth, turn.
- `Rpg::Tile` / `Rpg::Entity` — small value objects, serializable to JSON.
- `Rpg::DungeonGenerator` — room-and-corridor procedural generation.
- `Rpg::Fov` — simple shadowcasting/radius field-of-view; tracks `visible` and `explored` tiles.
- `Rpg::Ai` — enemy turn logic: move toward player if visible, wander otherwise.
- `Rpg::Combat` — bump-to-attack damage resolution.

### 5. Views & components
- `app/views/layouts/application_layout.rb` — full-screen wrapper with a bottom status/message area.
- `app/views/dungeon/show_view.rb` — composes map, status, and log components.
- `app/components/map_component.rb` — draws the dungeon with `Charming::UI::Canvas` and colored tiles.
- `app/components/status_component.rb` — HP/XP/depth/turn line.
- `app/components/log_component.rb` — last N message lines.
- `app/components/help_overlay.rb` — key cheat sheet (rendered as an overlay).

### 6. Theme
Extend the built-in `phosphor` theme with dungeon-specific tokens: `wall`, `floor`, `player`, `enemy`, `item`, `stairs`, `blood`, `text_accent`. Keeps the classic green-phosphor terminal look.

### 7. Gameplay loop
1. Player presses a movement key.
2. Controller loads world from `DungeonState`.
3. Player acts (move, attack, pick up item, rest).
4. If stairs used and enemies dead, descend → new dungeon level.
5. Enemies act one at a time.
6. World saved back to `DungeonState`.
7. `show` renders the new frame.
8. If player dies, show death screen; `n` starts a new run.

### 8. Controls
| Key | Action |
|-----|--------|
| `h` / `←` | move west |
| `j` / `↓` | move south |
| `k` / `↑` | move north |
| `l` / `→` | move east |
| `g` | get item on current tile |
| `>` | descend stairs |
| `r` | rest / wait one turn |
| `?` | toggle help overlay |
| `q` | quit |
| `n` | new game (on death/win screen) |

### 9. Testing
- RSpec + Charming::TestHelper.
- `spec/lib/rpg/dungeon_generator_spec.rb` — generation invariants (rooms connected, player start walkable).
- `spec/lib/rpg/fov_spec.rb` — visibility around player.
- `spec/controllers/dungeon_controller_spec.rb` — movement, combat, pickup, death, new game.
- `spec/components/map_component_spec.rb` — rendered map contains expected glyphs.
- `spec/integration/runtime_spec.rb` — boot with `MemoryBackend`, walk around, quit.

### 10. First milestone (MVP)
- Single dungeon level.
- Player, walls, floors, 3–5 enemies, 1–2 potions.
- Bump combat, HP, death screen.
- FOV + message log.
- Fully playable and testable.

### 11. Optional follow-ups (after MVP)
- Multiple dungeon depths.
- Inventory / equipable items.
- XP and leveling.
- Different enemy types.
- Persist high score across sessions.

## Open questions for you
1. **Turn-based vs. real-time?** I’m planning classic turn-based (player moves, then enemies move). If you want an arcade-style real-time roguelike, we’d use a Charming `timer` instead.
2. **Setting/theme?** Default is fantasy dungeon (`@` hero, `g` goblins, `!` potions, `>` stairs). Happy to swap to sci-fi, zombies, etc.
3. **Scope?** The plan above is a solid MVP. Should I trim anything (e.g., skip FOV for the first version) or add anything (e.g., inventory screen)?

If this plan looks good, I’ll start with the scaffold and the first specs.
