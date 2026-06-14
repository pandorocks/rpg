# frozen_string_literal: true

module Rpg
  class GameOverController < ApplicationController
    key "n", :new_game
    key "q", :quit
    key "esc", :back_to_dungeon

    def show
      ensure_world
      score = dungeon_state.record_score(world)
      render :show, world: world, score: score, high_scores: dungeon_state.high_scores, new_high_score: new_high_score?(score)
    end

    def new_game
      navigate_to "/setup"
    end

    def back_to_dungeon
      navigate_to "/"
    end

    private

    def new_high_score?(score)
      return false if dungeon_state.high_scores.empty?

      score[:total] >= dungeon_state.high_scores.first[:score]
    end

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
