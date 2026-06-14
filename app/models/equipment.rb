# frozen_string_literal: true

module Rpg
  class Equipment
    EQUIPMENT_TEMPLATES = {
      "weapon" => [
        {name: "Dagger", damage: 1, value: 25},
        {name: "Short Sword", damage: 2, value: 60},
        {name: "Battle Axe", damage: 4, value: 120},
        {name: "Mithril Blade", damage: 6, value: 250}
      ],
      "armor" => [
        {name: "Leather Armor", defense: 1, value: 30},
        {name: "Chain Mail", defense: 2, value: 80},
        {name: "Plate Armor", defense: 4, value: 160},
        {name: "Dragon Scale", defense: 6, value: 300}
      ],
      "ring" => [
        {name: "Ring of Might", damage: 1, defense: 0, value: 100},
        {name: "Ring of Protection", damage: 0, defense: 1, value: 100},
        {name: "Ring of Power", damage: 2, defense: 1, value: 200}
      ]
    }.freeze

    def self.random_item(kind, rng, depth)
      templates = EQUIPMENT_TEMPLATES.fetch(kind)
      budget = depth
      eligible = templates.select { |t| t[:value] <= budget * 60 + 30 }
      pool = eligible.empty? ? templates.first(1) : eligible
      pool.sample(random: rng)
    end

    def self.item_name(kind, template)
      "#{template[:name]} (#{stat_line(template)})"
    end

    def self.stat_line(template)
      parts = []
      parts << "+#{template[:damage]} dmg" if template[:damage].to_i > 0
      parts << "+#{template[:defense]} def" if template[:defense].to_i > 0
      parts.join(", ")
    end

    def self.player_damage(player, items)
      base = player.damage
      weapon = find(player.weapon_id, items)
      ring = find(player.ring_id, items)
      base += weapon.stats.fetch("damage", 0) if weapon
      base += ring.stats.fetch("damage", 0) if ring
      base
    end

    def self.player_defense(player, items)
      base = player.defense
      armor = find(player.armor_id, items)
      ring = find(player.ring_id, items)
      base += armor.stats.fetch("defense", 0) if armor
      base += ring.stats.fetch("defense", 0) if ring
      base
    end

    def self.find(id, items)
      items.find { |i| i.id == id }
    end
  end
end
