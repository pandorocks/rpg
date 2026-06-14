# frozen_string_literal: true

module Rpg
  class HelpOverlay < Charming::Component
    def initialize(width:, height:, theme:)
      @width = width
      @height = height
      @theme = theme
    end

    def render
      lines = [
        "Controls:",
        " h/j/k/l or arrows : move",
        " g : get item",
        " > : descend stairs",
        " f : fire ranged shot",
        " r : rest",
        " ? : toggle this help",
        " q : quit",
        " n : new game (after death)"
      ]
      max_len = lines.map(&:length).max
      box_width = [max_len + 4, @width - 4].min
      box_height = [lines.size + 2, @height - 4].min
      content = lines.map { |l| "  #{l.ljust(max_len)}  " }.join("\n")
      @theme.title.border(:rounded).width(box_width).height(box_height).align(:center).render(content)
    end
  end
end
