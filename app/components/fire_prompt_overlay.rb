# frozen_string_literal: true

module Rpg
  class FirePromptOverlay < Charming::Component
    def initialize(width:, height:, theme:)
      @width = width
      @height = height
      @theme = theme
    end

    def render
      text = "Choose direction to fire (h/j/k/l or arrows). Esc to cancel."
      box_width = [text.length + 4, @width - 4].min
      box_height = 3
      content = "  #{text}  "
      @theme.title.border(:rounded).width(box_width).height(box_height).align(:center).render(content)
    end
  end
end
