# frozen_string_literal: true

module Rpg
  class InventoryController < ApplicationController
    key "esc", :back
    key "i", :back

    def show
      ensure_world
      render :show, world: world
    end

    def back
      navigate_to "/"
    end

    private

    def ensure_world
      dungeon_state.new_game unless dungeon_state.world
    end

    def world
      dungeon_state.world
    end

    def dungeon_state
      state(:dungeon, DungeonState)
    end
  end
end
