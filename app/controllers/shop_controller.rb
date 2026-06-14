# frozen_string_literal: true

module Rpg
  class ShopController < ApplicationController
    key "esc", :back
    key "$", :back
    key "1", :buy_first
    key "2", :buy_second
    key "3", :buy_third

    def show
      ensure_world
      ensure_stock
      render :show, world: world
    end

    def back
      navigate_to "/"
    end

    def buy_first
      buy(0)
    end

    def buy_second
      buy(1)
    end

    def buy_third
      buy(2)
    end

    private

    def buy(index)
      ensure_world
      ensure_stock
      current = world
      _, message = current.buy_item(index)
      current.add_message(message)
      save_world(current)
      play_sounds(current)
      show
    end

    def ensure_stock
      current = world
      return unless current.shop_stock.empty?

      current.restock_shop(Random.new)
      save_world(current)
    end

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
