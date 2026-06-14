# frozen_string_literal: true

module Rpg
  module Setup
    class ShowView < Charming::View
      def render
        column(heading, selection_row, mode_line, hint, gap: 1)
      end

      private

      def heading
        text "Create your hero", style: theme.title
      end

      def mode_line
        label = setup.hardcore ? "Hardcore (permadeath + high scores)" : "Respawn (soulslike: die, lose souls, run back)"
        text "Mode [m to toggle]: #{label}", style: theme.text
      end

      def selection_row
        row(emoji_box, difficulty_box, gap: 4)
      end

      def emoji_box
        title = "Avatar"
        lines = emoji_options.each_with_index.map do |option, index|
          cursor = (index == setup.emoji_index) ? ">" : " "
          "#{cursor} #{option[:emoji]} #{option[:name]}"
        end
        bordered_box(title, lines.join("\n"))
      end

      def difficulty_box
        title = "Difficulty"
        lines = difficulty_options.each_with_index.map do |option, index|
          cursor = (index == setup.difficulty_index) ? ">" : " "
          "#{cursor} #{option[:name]}"
        end
        bordered_box(title, lines.join("\n"))
      end

      def bordered_box(title, content)
        theme.text.border(:rounded).width(30).padding(1).render("#{title}\n#{content}")
      end

      def hint
        text "Up/Down to choose avatar. Left/Right to choose difficulty. Enter to start. Esc to quit.", style: theme.muted
      end
    end
  end
end
