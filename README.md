# RPG

A small turn-based ASCII roguelike built with [Charming](https://github.com/pandorocks/charming), the Rails-inspired Ruby TUI framework.

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
| `r` | rest a turn |
| `?` | toggle help overlay |
| `ctrl+p` | command palette |
| `q` | quit |
| `n` | new game (after death) |

## Test

```bash
bundle exec rspec
bundle exec standardrb
```

## Project structure

- `lib/rpg/` — world model, procedural dungeon generator, field of view, AI, combat.
- `app/` — Charming controllers, state, views, and components.
- `spec/` — RSpec unit and integration tests using Charming's `MemoryBackend`.

## What works

- Procedural room-and-corridor dungeons.
- Player movement, bump combat, and ranged fire (`f` then direction).
- Goblins, orcs, and trolls that chase the player when they can see them.
- Potions, stairs, XP, and per-level monster scaling.
- Field of view, exploration memory, and a message log.
- Help overlay and command palette.
- Full keyboard control with a testable in-memory backend.
