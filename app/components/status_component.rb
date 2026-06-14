# frozen_string_literal: true

module Rpg
  class StatusComponent < Charming::Component
    def initialize(world:, width:, theme:)
      @world = world
      @width = width
      @theme = theme
    end

    def render
      left = "HP: #{@world.player.hp}/#{@world.player.max_hp}  XP: #{@world.player.xp}  Lvl: #{@world.player.level}"
      right = "Depth: #{@world.depth}  Turn: #{@world.turn}  Pos: (#{@world.player.x},#{@world.player.y})"
      pad = [@width - left.length - right.length, 1].max
      text = left + (" " * pad) + right
      @theme.hud.width(@width).render(text)
    end
  end
end
