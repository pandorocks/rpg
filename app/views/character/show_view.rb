# frozen_string_literal: true

module Rpg
  module Character
    class ShowView < Charming::View
      def render
        column(heading, stats_box, gap: 1)
      end

      private

      def heading
        text "Character Sheet", style: theme.title
      end

      def stats_box
        player = world.player
        lines = [
          "HP:        #{player.hp} / #{player.max_hp}",
          "XP:        #{player.xp} / #{world.xp_to_next_level} (level #{player.level})",
          "Damage:    #{player.damage}",
          "Depth:     #{world.depth}",
          "Turns:     #{world.turn}",
          "Kills:     #{world.kills}",
          "State:     #{world.state}"
        ]
        content = lines.join("\n")
        theme.text.border(:rounded).width(40).padding(1).render(content)
      end
    end
  end
end
