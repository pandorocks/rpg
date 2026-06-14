# frozen_string_literal: true

module Rpg
  module Dungeon
    class ShowView < Charming::View
      def render
        canvas = Charming::UI::Canvas.new(screen.width, screen.height)
        canvas.place(map, top: 0, left: 0)
        canvas.place(status, top: screen.height - 4, left: 0)
        canvas.place(log, top: screen.height - 3, left: 0)
        canvas.overlay(help) if help_open
        canvas.overlay(fire_prompt) if fire_mode
        canvas.to_s
      end

      private

      def map
        MapComponent.new(world: world, width: screen.width, height: screen.height - 4, theme: theme, player_glyph: player_glyph).render
      end

      def status
        StatusComponent.new(world: world, width: screen.width, theme: theme).render
      end

      def log
        LogComponent.new(world: world, width: screen.width, height: 3, theme: theme).render
      end

      def help
        HelpOverlay.new(width: screen.width, height: screen.height, theme: theme).render
      end

      def fire_prompt
        FirePromptOverlay.new(width: screen.width, height: screen.height, theme: theme).render
      end
    end
  end
end
