# frozen_string_literal: true

module Rpg
  # The bonfire menu: spend souls to level up, see your estus, then head back into the dungeon.
  # Resting (which heals, refills estus, and respawns the floor's enemies) already happened in
  # DungeonController#rest before navigating here.
  class BonfireController < ApplicationController
    key "l", :level_up
    key "esc", :leave
    key "r", :leave

    def show
      ensure_world
      render :show, world: world
    end

    def level_up
      ensure_world
      current = world
      current.level_up!
      save_world(current)
      play_sounds(current)
      show
    end

    def leave
      navigate_to "/"
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

    def dungeon_state
      state(:dungeon, DungeonState)
    end
  end
end
