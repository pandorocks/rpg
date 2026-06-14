# frozen_string_literal: true

module Rpg
  class LogComponent < Charming::Component
    def initialize(world:, width:, height:, theme:)
      @world = world
      @width = width
      @height = height
      @theme = theme
    end

    def render
      lines = @world.messages.last(@height)
      pad = @height - lines.size
      text = ([""] * pad + lines).join("\n")
      @theme.log.width(@width).render(text)
    end
  end
end
