# frozen_string_literal: true

module Rpg
  module GameOver
    class ShowView < Charming::View
      def render
        column(heading, score_box, stats_box, high_scores_box, hint, gap: 1)
      end

      private

      def heading
        if new_high_score
          text "🏆 New high score!", style: theme.title
        else
          text "☠ You died!", style: theme.title
        end
      end

      def score_box
        lines = [
          "Final score: #{score[:total]}",
          "  Souls collected:  #{score[:breakdown][:souls]} (x2)",
          "  Kills:            #{score[:breakdown][:kills]} (#{world.kills} x 10)",
          "  Depth reached:    #{score[:breakdown][:depth]} (depth #{world.depth} x 50)",
          "  Level bonus:      #{score[:breakdown][:level]} (level #{world.player.level})",
          "  Difficulty:       #{score[:multiplier]}x (#{world.difficulty})"
        ]
        content = lines.join("\n")
        theme.hud.border(:rounded).width(44).padding(1).render(content)
      end

      def stats_box
        player = world.player
        lines = [
          "Level:     #{player.level}",
          "Souls:     #{player.souls}",
          "Depth:     #{world.depth}",
          "Turns:     #{world.turn}",
          "Kills:     #{world.kills}"
        ]
        content = lines.join("\n")
        theme.text.border(:rounded).width(44).padding(1).render(content)
      end

      def high_scores_box
        return column if high_scores.empty?

        header = text "High scores", style: theme.title
        rows = high_scores.each_with_index.map do |entry, index|
          prefix = (entry == high_scores.first) ? "🏆" : "  #{index + 1}."
          text "#{prefix} #{entry[:score]} — depth #{entry[:depth]}, kills #{entry[:kills]} (#{entry[:difficulty]})", style: theme.text
        end
        content = column(header, *rows)
        theme.text.border(:rounded).width(44).padding(1).render(content.to_s)
      end

      def hint
        text "Press n for a new game, q to quit, esc to return to the dungeon.", style: theme.muted
      end
    end
  end
end
