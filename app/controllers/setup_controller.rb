# frozen_string_literal: true

module Rpg
  class SetupController < ApplicationController
    key "up", :prev_emoji
    key "down", :next_emoji
    key "left", :prev_difficulty
    key "right", :next_difficulty
    key "m", :toggle_mode
    key "enter", :confirm
    key "esc", :back

    def show
      render :show, setup: setup_state, emoji_options: GameBalance.emoji_options, difficulty_options: GameBalance.difficulty_options
    end

    def next_emoji
      setup_state.emoji_index = (setup_state.emoji_index + 1) % GameBalance.emoji_options.size
      show
    end

    def prev_emoji
      setup_state.emoji_index = (setup_state.emoji_index - 1) % GameBalance.emoji_options.size
      show
    end

    def next_difficulty
      setup_state.difficulty_index = (setup_state.difficulty_index + 1) % GameBalance.difficulty_options.size
      show
    end

    def prev_difficulty
      setup_state.difficulty_index = (setup_state.difficulty_index - 1) % GameBalance.difficulty_options.size
      show
    end

    def toggle_mode
      setup_state.hardcore = !setup_state.hardcore
      show
    end

    def confirm
      difficulty = GameBalance.difficulty_for(setup_state.difficulty_index).fetch(:name)
      mode = setup_state.hardcore ? "hardcore" : "respawn"
      dungeon_state.new_game(difficulty: difficulty, width: screen.width / 2, height: screen.height - 4, mode: mode)
      session[:player_glyph] = GameBalance.emoji_for(setup_state.emoji_index)
      navigate_to "/"
    end

    def back
      if dungeon_state.world
        navigate_to "/"
      else
        quit
      end
    end

    private

    def setup_state
      state(:setup, SetupState)
    end

    def dungeon_state
      state(:dungeon, DungeonState)
    end
  end
end
