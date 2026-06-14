# frozen_string_literal: true

module Rpg
  module Bonfire
    class ShowView < Charming::View
      def render
        column(heading, status_box, hint, gap: 1)
      end

      private

      def heading
        text "🔥 Bonfire", style: theme.title
      end

      def status_box
        player = world.player
        cost = world.soul_cost_for_next_level
        affordable = player.souls >= cost
        lines = [
          "Level:   #{player.level}",
          "Souls:   #{player.souls}",
          "Estus:   #{player.estus_charges} / #{player.max_estus_charges} (refilled)",
          "HP:      #{player.hp} / #{player.max_hp}",
          "",
          affordable ? "Next level: #{cost} souls" : "Next level: #{cost} souls  (not enough)"
        ]
        theme.text.border(:rounded).width(40).padding(1).render(lines.join("\n"))
      end

      def hint
        text "Press l to level up, esc or r to leave the bonfire.", style: theme.muted
      end
    end
  end
end
