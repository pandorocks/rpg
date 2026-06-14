# frozen_string_literal: true

module Rpg
  class GameOverController < ApplicationController
    key "n", :new_game
    key "q", :quit
    key "esc", :back_to_dungeon

    def show
      ensure_world
      render :show, world: world
    end

    def new_game
      navigate_to "/setup"
    end

    def back_to_dungeon
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
