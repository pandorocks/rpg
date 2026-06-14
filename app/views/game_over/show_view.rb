# frozen_string_literal: true

module Rpg
  module GameOver
    class ShowView < Charming::View
      def render
        column(heading, stats_box, hint, gap: 1)
      end

      private

      def heading
        text "☠ You died!", style: theme.title
      end

      def stats_box
        player = world.player
        lines = [
          "Level:     #{player.level}",
          "XP:        #{player.xp}",
          "Depth:     #{world.depth}",
          "Turns:     #{world.turn}",
          "Kills:     #{world.kills}"
        ]
        content = lines.join("\n")
        theme.text.border(:rounded).width(40).padding(1).render(content)
      end

      def hint
        text "Press n for a new game, q to quit, esc to return to the dungeon.", style: theme.muted
      end
    end
  end
end
