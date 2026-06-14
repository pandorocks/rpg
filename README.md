# RPG

A small turn-based terminal roguelike built with [Charming](https://github.com/pandorocks/charming), the Rails-inspired Ruby TUI framework. The map renders every tile as two terminal columns and uses emoji for walls, monsters, items, and the player.

## Play

```bash
bundle install
bundle exec exe/rpg
```

## Controls

| Key | Action |
|-----|--------|
| `h` / `←` | move west |
| `j` / `↓` | move south |
| `k` / `↑` | move north |
| `l` / `→` | move east |
| `g` | pick up item |
| `>` | descend stairs |
| `f` | fire ranged shot |
| `i` | inventory screen |
| `c` | character sheet |
| `$` | shop |
| `r` | rest a turn |
| `?` | toggle help overlay |
| `ctrl+p` | command palette |
| `q` | quit |
| `n` | new game / setup |

### Setup screen

On every new game you choose an avatar and difficulty:

| Difficulty | Effect |
|------------|--------|
| Easy       | More HP/damage/XP; weaker enemies |
| Normal     | Balanced |
| Hard       | Less HP/damage/XP; stronger enemies |

Avatars: 🧙 Wizard, 🥷 Ninja, 🦸 Superhero, 🐱 Cat.

Enemies include goblins, orcs, trolls, zombies, robots, ghosts, and dragons.

## Test

```bash
bundle exec rspec
bundle exec standardrb
```

## Project structure

- `app/models/` — game domain: `World`, `Player`, `Entity`, `Item`, `DungeonGenerator`, `Fov`, `Ai`, `Combat`.
- `app/controllers/`, `app/state/`, `app/views/`, `app/components/` — Charming framework code.
- `lib/rpg/` — application boot and version.
- `spec/` — RSpec unit and integration tests using Charming's `MemoryBackend`.

## What works

- Procedural room-and-corridor dungeons.
- Player movement, bump combat, and ranged fire (`f` then direction).
- Inventory, character sheet, game over, and setup screens.
- Avatar and difficulty selection on every new game.
- XP, leveling up, kill count, and per-level monster scaling.
- Goblins, orcs, and trolls that chase the player when they can see them.
- Potions, stairs, and a message log.
- Multiple item types: healing potions, potions of strength, potions of vision, scrolls of mapping, chests, weapons, armor, and rings.
- Gold economy: enemies drop gold and chests contain gold.
- Shop screen (`$`) to buy weapons, armor, and rings that boost damage and defense.
- Equipment persists across dungeon levels.
- Game over summary with final score breakdown and top 5 high scores.
- Field of view and exploration memory.
- Help overlay and command palette.
- Full keyboard control with a testable in-memory backend.

## Notes

- The dungeon is sized to fill your terminal: each tile is two columns wide, so make the terminal window wide enough to avoid clipping (a 14-inch screen at a comfortable font size is usually plenty).
- The status bar shows HP, XP, level, gold, depth, turn, and your current `(x,y)` coordinates.
