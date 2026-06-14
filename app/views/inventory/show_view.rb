# frozen_string_literal: true

module Rpg
  module Inventory
    class ShowView < Charming::View
      def render
        column(heading, nearby_items, hint, gap: 1)
      end

      private

      def heading
        text "Inventory", style: theme.title
      end

      def nearby_items
        visible_items = world.items.select { |item| world.visible?(item.x, item.y) }
        return text "No items are visible nearby.", style: theme.muted if visible_items.empty?

        rows = visible_items.map do |item|
          text "- #{item_name(item)} at (#{item.x}, #{item.y})", style: theme.text
        end
        column(*rows)
      end

      def hint
        text "Items are consumed or equipped automatically when you press g on them. Press esc or i to return.", style: theme.muted
      end

      def item_name(item)
        {
          "potion" => "potion of healing",
          "potion_of_strength" => "potion of strength",
          "potion_of_vision" => "potion of vision",
          "scroll_of_mapping" => "scroll of mapping",
          "chest" => "chest (#{item.value}g)"
        }.fetch(item.kind, item.name)
      end
    end
  end
end
