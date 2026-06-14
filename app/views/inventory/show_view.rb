# frozen_string_literal: true

module Rpg
  module Inventory
    class ShowView < Charming::View
      def render
        column(heading, equipment_status, item_list, hint, gap: 1)
      end

      private

      def heading
        text "Inventory", style: theme.title
      end

      def equipment_status
        lines = []
        lines << "Weapon: #{equipment_line(world.equipped_weapon)}"
        lines << "Armor:  #{equipment_line(world.equipped_armor)}"
        lines << "Ring:   #{equipment_line(world.equipped_ring)}"
        lines << "Souls:  #{world.player.souls}"
        theme.text.border(:rounded).width(40).padding(1).render(lines.join("\n"))
      end

      def equipment_line(item)
        return "nothing" if item.nil?

        stat = Equipment.stat_line(item.stats.symbolize_keys)
        "#{item.name} #{stat}".strip
      end

      def item_list
        return text "Your inventory is empty.", style: theme.muted if world.inventory.empty?

        rows = world.inventory.each_with_index.map do |item, index|
          cursor = (index == selected_index) ? ">" : " "
          marker = equipped_marker(item)
          text "#{cursor} #{marker}#{item_name(item)}", style: row_style(item, index)
        end
        column(*rows)
      end

      def item_name(item)
        case item.kind
        when "potion" then "potion of healing"
        when "potion_of_strength" then "potion of strength"
        when "potion_of_vision" then "potion of vision"
        when "scroll_of_mapping" then "scroll of mapping"
        when "chest" then "chest (#{item.value}g)"
        else
          stat = Equipment.stat_line(item.stats.symbolize_keys)
          stat.empty? ? item.name : "#{item.name} — #{stat}"
        end
      end

      def equipped_marker(item)
        return "[E] " if item && world.player && [
          world.player.weapon_id,
          world.player.armor_id,
          world.player.ring_id
        ].include?(item.id)

        "    "
      end

      def row_style(_item, index)
        return theme.selected if index == selected_index

        theme.text
      end

      def hint
        text "↑/↓ or j/k to select, enter to use, d to drop, esc/i to return.", style: theme.muted
      end
    end
  end
end
