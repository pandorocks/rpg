# frozen_string_literal: true

module Rpg
  class Scoring
    def self.score_for(world)
      breakdown = {
        souls: world.player.souls * 2,
        kills: world.kills * 10,
        depth: world.depth * 50,
        level: (world.player.level - 1) * 25
      }
      raw = breakdown.values.sum
      multiplier = difficulty_multiplier(world.difficulty)
      {
        total: (raw * multiplier).to_i,
        raw: raw,
        multiplier: multiplier,
        breakdown: breakdown
      }
    end

    def self.difficulty_multiplier(name)
      {
        "Easy" => 0.8,
        "Normal" => 1.0,
        "Hard" => 1.2
      }.fetch(name, 1.0)
    end
  end
end
