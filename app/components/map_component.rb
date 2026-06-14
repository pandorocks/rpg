# frozen_string_literal: true

module Rpg
  class MapComponent < Charming::Component
    GLYPHS = {
      goblin: "👺",
      orc: "🐗",
      troll: "🧌",
      zombie: "🧟",
      robot: "🤖",
      ghost: "👻",
      dragon: "🐲",
      potion: "🧪",
      potion_of_strength: "💪",
      potion_of_vision: "🔦",
      scroll_of_mapping: "📜",
      weapon: "⚔️",
      armor: "🛡️",
      ring: "💍",
      chest: "💰",
      bonfire: "🔥",
      bloodstain: "🩸",
      unseen: "  "
    }.freeze

    DEFAULT_PLAYER_GLYPH = "🧙"

    def initialize(world:, width:, height:, theme:, player_glyph: DEFAULT_PLAYER_GLYPH)
      @world = world
      @width = width
      @height = height
      @theme = theme
      @player_glyph = player_glyph
    end

    def render
      canvas = Charming::UI::Canvas.new(@width, @height)
      (0...@world.height).each do |y|
        (0...@world.width).each do |x|
          next if y >= @height

          left = x * 2
          next if left + 1 >= @width

          unless @world.explored?(x, y)
            canvas.place(GLYPHS[:unseen], top: y, left: left)
            next
          end

          char, style = glyph_and_style(x, y)
          styled = style ? style.render(tile_string(char)) : tile_string(char)
          canvas.place(styled, top: y, left: left)
        end
      end
      canvas.to_s
    end

    private

    def glyph_and_style(x, y)
      player = @world.player
      return [@player_glyph, @theme.player] if player && player.x == x && player.y == y

      entity = @world.entity_at(x, y)
      return [entity_glyph(entity), @theme.enemy] if entity

      item = @world.item_at(x, y)
      return [GLYPHS[item.kind.to_sym] || item.kind[0..1], @theme.item] if item

      tile = @world.tile_at(x, y)
      biome = @world.biome

      case tile
      when "wall"
        [Biome.wall_glyph(biome), Biome.tile_style(tile, biome, @theme)]
      when "stairs"
        [Biome.stairs_glyph(biome), @theme.stairs]
      when "upstairs"
        [Biome.upstairs_glyph(biome), @theme.stairs]
      when "bonfire"
        [GLYPHS[:bonfire], @theme.item]
      else
        visible = @world.visible?(x, y)
        style = Biome.tile_style("floor", biome, @theme)
        floor_style = visible ? style : @theme.muted
        [Biome.floor_glyph(biome), floor_style]
      end
    end

    def entity_glyph(entity)
      GLYPHS[entity.kind.to_sym] || entity.kind[0..1]
    end

    def tile_string(glyph)
      (glyph.bytesize > 3) ? glyph : glyph.ljust(2)
    end
  end
end
