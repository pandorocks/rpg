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
    key "n", :new_game

    def show
      ensure_world
      render :show, world: world, help_open: help_open?, fire_mode: fire_mode?
    end

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
      dungeon_state.new_game
      show
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

    def act(dx, dy)
      ensure_world
      current = world
      if session[:fire_mode]
        current.fire_player(dx, dy)
        session[:fire_mode] = false
      else
        current.move_player(dx, dy)
      end
      save_world(current)
      show
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
  end
end
