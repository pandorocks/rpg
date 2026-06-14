# Plan: Real Inventory — Store and Use Items

## Problem
The inventory screen currently only lists **nearby visible floor items**. When the player presses `g`, items are consumed/equipped immediately, so:
- Potions are wasted if the player is at full health.
- New weapons/armor/rings overwrite whatever is currently equipped.
- The player can never carry spare potions or gear.

## Goal
Make `inventory` an actual inventory:
- `g` picks up the item under the player and puts it in the inventory.
- The inventory screen (`i`) lists carried items, including equipped gear and stats.
- From the inventory screen the player can select and **use** an item.
- Potions can be quaffed even at full health (no heal waste because they heal 0).
- Gear can be equipped even when a slot is full; the old piece moves back into the inventory.

## Design decisions

### 1. Pickup no longer auto-consumes
`World#pickup_item` will:
- Remove the item from the floor (`world.items`).
- Add it to `world.inventory`.
- Display "You pick up #{item.name}."
- No immediate effect for potions/scrolls/equipment.
- Chests are still opened for gold on pickup (they are not inventory objects; they are gold containers).

### 2. Inventory screen becomes interactive
`InventoryController` will gain:
- `up`/`down` / `k`/`j` to move a selection cursor.
- `enter` to use the selected item.
- `d` to drop the selected item at the player's feet.
- `esc` / `i` to return to the dungeon.

`InventoryState#selected_index` already exists for this.

`Inventory::ShowView` will render:
- A heading.
- A list of inventory items with the selected row highlighted.
- Equipped status (`[E]` or similar) and stat line for gear.
- A hint line.
- Recent message line(s) for feedback ("You quaff a potion.", etc.).

### 3. Using items from inventory
A new `World#use_inventory_item(item)` method will mirror `use_item` but:
- Accept potions at full health (heal to max, message says no additional healing).
- For scrolls/potions of strength/vision, apply effects and remove the item.
- For equipment, equip the item and **return the previously equipped piece to inventory**.
- Chests cannot be in inventory (they are opened on pickup).

`World#equip_item` currently adds the item to inventory; we need to separate:
- `equip_item(item)` just sets the slot id and reports the equip.
- A new `unequip_slot(kind)` returns the old item id so the caller can manage it.

### 4. Dropping items
`World#drop_item(item)` will:
- Remove from inventory.
- Place at player location (or nearby if occupied).
- Add a message and sound cue.

### 5. Status/equipment display
Inventory rows show:
- Name.
- Equipped marker for the current weapon/armor/ring slot.
- Stat line for gear.
- Count/descriptor for consumables.

### 6. Serialization
Inventory already serializes in `World#to_h` and `from_h`, so nothing new is needed there.

### 7. Controls / help
- `DungeonController#pickup` stays on `g`.
- `InventoryController` gets `up`/`down`/`k`/`j`/`enter`/`d` bindings.
- `HelpOverlay` legend and controls updated:
  - `g : get item` (now adds to inventory).
  - Inventory controls: move cursor, enter use, d drop, esc/i back.

## Files to create / modify

### Modified
- `app/models/world.rb`
  - `pickup_item` → add to inventory instead of consuming.
  - `use_item` becomes private/internal; rename current logic to support both floor pickup and inventory use.
  - New `use_inventory_item(item)` with slot-swap logic.
  - New `drop_item(item)`.
  - Update `equip_item` to not add to inventory; add helper to retrieve the item currently in a slot.
  - Keep `buy_item` behavior similar but move the bought item into inventory and equip it if desired (or just inventory; shop-bought gear should be usable from inventory anyway).
  - Chests: still opened immediately on floor pickup.

- `app/controllers/inventory_controller.rb`
  - Add key bindings for selection and use/drop.
  - Pass `selected_index` and `message` to view.

- `app/views/inventory/show_view.rb`
  - Render inventory list with cursor and equipped markers.
  - Show hint and recent messages.

- `app/controllers/dungeon_controller.rb`
  - `pickup` action persists the world after `pickup_item` (already does).

- `app/components/help_overlay.rb`
  - Update inventory/help legend text.

- `spec/controllers/inventory_controller_spec.rb` — new specs.
- `spec/lib/rpg/world_spec.rb` — pickup, use, drop, equip-swap specs.
- `spec/components/help_overlay_spec.rb` if it exists; else no change.
- `README.md` and `PLAN.md` — document inventory controls and behavior.

## Testing plan
- Unit specs for `World`:
  - Pickup moves item from floor to inventory.
  - Using a potion from inventory heals (or does nothing if full health) and removes the potion.
  - Using strength/vision potions applies buffs.
  - Using a scroll reveals the map.
  - Equipping a weapon/armor/ring swaps the current slot's item back into inventory.
  - Dropping an item places it on the floor.
  - Chests still award gold on pickup.
- Controller specs for inventory screen:
  - Shows inventory items.
  - Cursor moves up/down.
  - Enter uses selected item.
  - `d` drops selected item.
  - Esc/i returns to dungeon.
- Full suite: `bundle exec rspec` and `bundle exec standardrb`.

## MVP scope
- Pickup to inventory.
- Inventory list, selection, use, drop.
- Potion quaffing at full health.
- Equipment slot swap.
- Updated help and docs.

## Open questions
None — ready to implement.
