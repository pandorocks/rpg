# frozen_string_literal: true

module Rpg
  class HelpOverlay < Charming::Component
    LEGEND = [
      "Legend:",
      " 🧙 : player avatar",
      " 🧱 : wall",
      " 🪜 : stairs",
      " 👺 : goblin",
      " 🐗 : orc",
      " 🧌 : troll",
      " 🧟 : zombie",
      " 🤖 : robot",
      " 👻 : ghost",
      " 🐲 : dragon",
      " 🧪 : potion",
      " 💪 : strength potion",
      " 🔦 : vision potion",
      " 📜 : scroll of mapping",
      " ⚔️ : weapon",
      " 🛡️ : armor",
      " 💍 : ring",
      " 💰 : chest",
      " $ : open shop"
    ].freeze

    CONTROLS = [
      "Controls:",
      " h/j/k/l or arrows : move",
      " g : get item",
      " > : descend stairs",
      " f : fire ranged shot",
      " i : inventory",
      " c : character sheet",
      " r : rest",
      " ? : toggle this help",
      " q : quit",
      " n : new game / setup"
    ].freeze

    def initialize(width:, height:, theme:)
      @width = width
      @height = height
      @theme = theme
    end

    def render
      lines = CONTROLS + [""] + LEGEND
      max_len = lines.map { |l| display_width(l) }.max
      box_width = [max_len + 4, @width - 4].min
      box_height = [lines.size + 2, @height - 4].min
      content = lines.map { |l| "  #{pad_to_width(l, max_len)}  " }.join("\n")
      @theme.title.border(:rounded).width(box_width).height(box_height).align(:center).render(content)
    end

    private

    # Delegate to the framework's measurement so emoji (including ZWJ and
    # variation-selector sequences such as "🛡️"/"🧙‍♂️") are counted at the same
    # display width the bordered box uses. A local byte-count heuristic drifted
    # on those glyphs and skewed the legend's colon column.
    def display_width(text)
      Charming::UI::Width.measure(text)
    end

    def pad_to_width(text, target_width)
      width = display_width(text)
      text + (" " * [target_width - width, 0].max)
    end
  end
end
