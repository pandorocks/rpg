# frozen_string_literal: true

module Rpg
  class DungeonController < ApplicationController
    key "h", :move_west
    key "j", :move_south
    key "k", :move_north
    key "l", :move_east
    key "left", :move_west
    key "down", :move_south
    key "up", :move_north
    key "right", :move_east
    key "g", :pickup
    key ">", :descend
    key "r", :rest
    key "f", :enter_fire_mode
    key "esc", :cancel_fire_mode
    key "i", :inventory
    key "c", :character_sheet
    key "$", :shop
    key "n", :new_game

    def show
      ensure_world
      return navigate_to "/game_over" if world.state == "dead"

      render :show, world: world, help_open: help_open?, fire_mode: fire_mode?, player_glyph: player_glyph
    end

    MOVE_COOLDOWN = 0.12

    def move_west
      act(-1, 0)
    end

    def move_east
      act(1, 0)
    end

    def move_north
      act(0, -1)
    end

    def move_south
      act(0, 1)
    end

    def pickup
      ensure_world
      current = world
      current.pickup_item
      save_world(current)
      show
    end

    def descend
      ensure_world
      current = world
      new_world = current.descend
      save_world(new_world || current)
      show
    end

    def rest
      ensure_world
      current = world
      current.rest_player
      save_world(current)
      show
    end

    def new_game
      navigate_to "/setup"
    end

    def enter_fire_mode
      ensure_world
      session[:fire_mode] = true
      current = world
      current.add_message("Fire in which direction? (h/j/k/l or arrows)")
      save_world(current)
      show
    end

    def cancel_fire_mode
      if session[:fire_mode]
        session[:fire_mode] = false
        current = world
        current.add_message("Cancelled.")
        save_world(current)
      end
      show
    end

    def inventory
      navigate_to "/inventory"
    end

    def character_sheet
      navigate_to "/character"
    end

    def shop
      navigate_to "/shop"
    end

    private

    def ensure_world
      dungeon_state.new_game(difficulty: "Normal", width: screen.width / 2, height: screen.height - 4) unless dungeon_state.world
    end

    def world
      dungeon_state.world
    end

    def save_world(w)
      dungeon_state.world = w
    end

    def act(dx, dy)
      ensure_world
      return show if throttled?

      current = world
      if session[:fire_mode]
        current.fire_player(dx, dy)
        session[:fire_mode] = false
      else
        current.move_player(dx, dy)
      end
      session[:last_move_at] = Time.now.to_f
      save_world(current)
      show
    end

    def throttled?
      return false unless session[:last_move_at]
      return false if test?

      Time.now.to_f - session[:last_move_at] < MOVE_COOLDOWN
    end

    def test?
      defined?(RSpec)
    end

    def dungeon_state
      state(:dungeon, DungeonState)
    end

    def help_open?
      !!session[:help_open]
    end

    def fire_mode?
      !!session[:fire_mode]
    end

    def player_glyph
      session[:player_glyph] || GameBalance.emoji_for(0)
    end
  end
end
