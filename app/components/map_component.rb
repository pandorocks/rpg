# frozen_string_literal: true

module Rpg
  class MapComponent < Charming::Component
    GLYPHS = {
      wall: "#",
      floor: ".",
      stairs: ">",
      goblin: "g",
      orc: "o",
      troll: "T",
      potion: "!",
      unseen: " "
    }.freeze

    DEFAULT_PLAYER_GLYPH = "🧙‍♂️"

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
          next if y >= @height || x >= @width

          unless @world.explored?(x, y)
            canvas.place(" ", top: y, left: x)
            next
          end

          char, style = glyph_and_style(x, y)
          styled = style ? style.render(char) : char
          canvas.place(styled, top: y, left: x)
        end
      end
      overlay_player(canvas)
      canvas.to_s
    end

    private

    def overlay_player(canvas)
      player = @world.player
      return unless player

      styled = @theme.player.render(@player_glyph)
      canvas.overlay(styled, top: player.y, left: player.x)
    end

    def glyph_and_style(x, y)
      player = @world.player
      return [GLYPHS[:floor], @theme.floor] if player.x == x && player.y == y

      entity = @world.entity_at(x, y)
      return [GLYPHS[entity.kind.to_sym] || entity.kind[0], @theme.enemy] if entity

      item = @world.item_at(x, y)
      return [GLYPHS[item.kind.to_sym] || item.kind[0], @theme.item] if item

      case @world.tile_at(x, y)
      when "wall" then [GLYPHS[:wall], @theme.wall]
      when "stairs" then [GLYPHS[:stairs], @theme.stairs]
      else
        visible = @world.visible?(x, y)
        floor_style = visible ? @theme.floor : @theme.muted
        [GLYPHS[:floor], floor_style]
      end
    end
  end
end
