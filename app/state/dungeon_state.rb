# frozen_string_literal: true

require "json"

module Rpg
  class DungeonState < Charming::ApplicationState
    attribute :world_json, :string

    def world
      return nil unless world_json

      World.from_h(JSON.parse(world_json))
    end

    def world=(world)
      self.world_json = JSON.generate(world.to_h)
    end

    def new_game(difficulty: "Normal", width: 60, height: 20)
      self.world = World.new_game(difficulty: difficulty, width: width, height: height)
    end
  end
end
