# frozen_string_literal: true

module Rpg
  class InventoryController < ApplicationController
    key "esc", :back
    key "i", :back
    key "up", :prev_item
    key "down", :next_item
    key "k", :prev_item
    key "j", :next_item
    key "enter", :use_item
    key "d", :drop_item

    def show
      ensure_world
      render :show, world: world, selected_index: selected_index
    end

    def back
      navigate_to "/"
    end

    def prev_item
      inv_state.selected_index = [selected_index - 1, 0].max
      show
    end

    def next_item
      inv_state.selected_index = [selected_index + 1, world.inventory.size - 1].max
      show
    end

    def use_item
      ensure_world
      current = world
      item = current.inventory[selected_index]
      if item
        _, message = current.use_inventory_item(item)
        current.add_message(message) if message
        save_world(current)
      end
      play_sounds(current)
      show
    end

    def drop_item
      ensure_world
      current = world
      item = current.inventory[selected_index]
      if item
        current.drop_item(item)
        # Adjust cursor so it does not point past the last item.
        inv_state.selected_index = [selected_index, current.inventory.size - 1].min
        save_world(current)
      end
      play_sounds(current)
      show
    end

    private

    def ensure_world
      dungeon_state.new_game unless dungeon_state.world
    end

    def world
      dungeon_state.world
    end

    def save_world(w)
      dungeon_state.world = w
    end

    def selected_index
      inv_state.selected_index.to_i
    end

    def inv_state
      state(:inventory, InventoryState)
    end

    def dungeon_state
      state(:dungeon, DungeonState)
    end
  end
end
