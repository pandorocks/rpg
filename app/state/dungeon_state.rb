# frozen_string_literal: true

require "json"

module Rpg
  class DungeonState < Charming::ApplicationState
    attribute :world_json, :string
    attribute :high_scores, default: -> { [] }

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

    def record_score(world)
      score = Scoring.score_for(world)
      entry = {
        score: score[:total],
        raw: score[:raw],
        multiplier: score[:multiplier],
        kills: world.kills,
        depth: world.depth,
        level: world.player.level,
        difficulty: world.difficulty,
        gold: world.player.gold
      }
      self.high_scores = (high_scores + [entry]).sort_by { |e| -e[:score] }.first(5)
      score
    end
  end
end
