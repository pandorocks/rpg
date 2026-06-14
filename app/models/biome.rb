# frozen_string_literal: true

module Rpg
  # Biomes give each dungeon floor a distinct visual identity and enemy mix.
  # Tiles stay simple strings ("wall", "floor", "stairs") everywhere else; this
  # module decides how a given biome renders those tiles and what lives on them.
  module Biome
    BiomeDef = Data.define(
      :name,
      :wall_glyph,
      :floor_glyph,
      :stairs_glyph,
      :upstairs_glyph,
      :wall_style,
      :floor_style,
      :room_shape,
      :enemy_table
    )

    BIOMES = {
      dungeon: BiomeDef.new(
        name: "Dungeon",
        wall_glyph: "🧱",
        floor_glyph: "··",
        stairs_glyph: "🪜",
        upstairs_glyph: "🔼",
        wall_style: :wall,
        floor_style: :floor,
        room_shape: ->(rng) { [rng.rand(4..10), rng.rand(4..8)] },
        enemy_table: {
          goblin: 0.50, orc: 0.25, troll: 0.0, zombie: 0.15,
          robot: 0.10, ghost: 0.0, dragon: 0.0
        }
      ),
      cave: BiomeDef.new(
        name: "Cave",
        wall_glyph: "🪨",
        floor_glyph: "░░",
        stairs_glyph: "🪜",
        upstairs_glyph: "🔼",
        wall_style: :wall_cave,
        floor_style: :floor_cave,
        room_shape: ->(rng) { [rng.rand(5..12), rng.rand(4..7)] },
        enemy_table: {
          goblin: 0.35, orc: 0.25, troll: 0.15, zombie: 0.10,
          robot: 0.05, ghost: 0.10, dragon: 0.0
        }
      ),
      ice: BiomeDef.new(
        name: "Ice Cavern",
        wall_glyph: "🧊",
        floor_glyph: "❄·",
        stairs_glyph: "🪜",
        upstairs_glyph: "🔼",
        wall_style: :wall_ice,
        floor_style: :floor_ice,
        room_shape: ->(rng) { [rng.rand(4..9), rng.rand(4..7)] },
        enemy_table: {
          goblin: 0.20, orc: 0.20, troll: 0.20, zombie: 0.15,
          robot: 0.05, ghost: 0.15, dragon: 0.05
        }
      ),
      volcano: BiomeDef.new(
        name: "Volcano",
        wall_glyph: "🌋",
        floor_glyph: "░░",
        stairs_glyph: "🪜",
        upstairs_glyph: "🔼",
        wall_style: :wall_volcano,
        floor_style: :floor_volcano,
        room_shape: ->(rng) { [rng.rand(4..10), rng.rand(3..7)] },
        enemy_table: {
          goblin: 0.10, orc: 0.20, troll: 0.25, zombie: 0.10,
          robot: 0.10, ghost: 0.05, dragon: 0.20
        }
      ),
      abyss: BiomeDef.new(
        name: "Abyss",
        wall_glyph: "🗿",
        floor_glyph: "▒▒",
        stairs_glyph: "🪜",
        upstairs_glyph: "🔼",
        wall_style: :wall_abyss,
        floor_style: :floor_abyss,
        room_shape: ->(rng) { [rng.rand(4..11), rng.rand(4..8)] },
        enemy_table: {
          goblin: 0.05, orc: 0.10, troll: 0.20, zombie: 0.15,
          robot: 0.10, ghost: 0.20, dragon: 0.20
        }
      )
    }.freeze

    DEPTH_RANGES = [
      (1..2),
      (3..4),
      (5..6),
      (7..8),
      (9..)
    ].freeze

    BIOME_ORDER = %i[dungeon cave ice volcano abyss].freeze

    def self.for_depth(depth)
      index = DEPTH_RANGES.index { |range| range.cover?(depth) }
      BIOME_ORDER[index || 0]
    end

    def self.name(biome)
      BIOMES.fetch(resolve(biome)).name
    end

    def self.wall_glyph(biome)
      BIOMES.fetch(resolve(biome)).wall_glyph
    end

    def self.floor_glyph(biome)
      BIOMES.fetch(resolve(biome)).floor_glyph
    end

    def self.stairs_glyph(biome)
      BIOMES.fetch(resolve(biome)).stairs_glyph
    end

    def self.upstairs_glyph(biome)
      BIOMES.fetch(resolve(biome)).upstairs_glyph
    end

    # Looks up a biome-tinted style on the theme; falls back to the base tile
    # style so missing palettes do not break rendering.
    def self.tile_style(tile, biome, theme)
      biome_key = BIOMES.fetch(resolve(biome))
      style_key = case tile
      when "wall" then biome_key.wall_style
      when "floor" then biome_key.floor_style
      else tile.to_sym
      end

      return theme.public_send(style_key) if theme.respond_to?(style_key)
      return theme.public_send(tile.to_sym) if theme.respond_to?(tile.to_sym)

      nil
    end

    def self.room_dimensions(biome, rng)
      BIOMES.fetch(resolve(biome)).room_shape.call(rng)
    end

    # Returns a spawn table appropriate for the biome, scaled by depth so deeper
    # floors gradually unlock tougher monsters and dragons.
    def self.enemy_weights(biome, depth)
      base = BIOMES.fetch(resolve(biome)).enemy_table
      scale_table(base, depth)
    end

    def self.random_enemy_kind(biome, depth, rng)
      table = enemy_weights(biome, depth)
      roll = rng.rand
      cumulative = 0.0
      table.each do |kind, weight|
        cumulative += weight
        return kind.to_s if roll < cumulative
      end
      table.keys.first.to_s
    end

    def self.resolve(biome)
      key = biome.to_s.to_sym
      BIOMES.key?(key) ? key : :dungeon
    end

    def self.scale_table(base, depth)
      table = base.dup

      if depth <= 2
        table[:dragon] = 0.0
      elsif depth > 5 && table[:dragon].to_f < 0.05
        # Deeper floors guarantee at least a small chance of dragons while
        # preserving the biome's existing flavor.
        bump = 0.05 - table[:dragon].to_f
        table[:dragon] = 0.05
        table[:goblin] = [table[:goblin].to_f - bump, 0.0].max
      end

      normalize(table)
    end

    def self.normalize(table)
      total = table.values.sum.to_f
      return table if total.zero?

      table.transform_values { |weight| weight / total }
    end
  end
end
