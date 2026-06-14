# frozen_string_literal: true

require "json"

module Rpg
  class DungeonState < Charming::ApplicationState
    attribute :run_json, :string
    attribute :high_scores, default: -> { [] }

    def run
      return nil unless run_json

      Run.from_h(JSON.parse(run_json))
    end

    def run=(value)
      self.run_json = JSON.generate(value.to_h)
    end

    # The current floor as a live World (player injected). Returns nil before a run exists.
    def world
      run&.current_world
    end

    # Persists a played floor back into the run (and captures the player), keeping the old
    # `dungeon_state.world = w` call sites working unchanged.
    def world=(world)
      current = run
      return unless current

      # In respawn mode, a death is not the end: the run drops a bloodstain and wakes the player
      # at their last bonfire. In hardcore mode the "dead" state is left for the game-over screen.
      if world.state == "dead" && current.mode == "respawn"
        current.respawn!(world)
      else
        current.save_world(world)
      end
      self.run = current
    end

    # Floor transitions: mutate the run, persist, and return the new current world (or nil when
    # blocked) so the caller can play its sound cues off the in-memory object.
    def descend
      current = run
      world = current.descend
      self.run = current
      world
    end

    def ascend
      current = run
      world = current.ascend
      self.run = current
      world
    end

    def new_game(difficulty: "Normal", width: 60, height: 20, mode: "respawn")
      self.run = Run.new_game(difficulty: difficulty, width: width, height: height, mode: mode)
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
        souls: world.player.souls
      }
      self.high_scores = (high_scores + [entry]).sort_by { |e| -e[:score] }.first(5)
      score
    end
  end
end
