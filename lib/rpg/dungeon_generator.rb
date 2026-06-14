# frozen_string_literal: true

module Rpg
  class GenerationError < StandardError; end

  class DungeonGenerator
    Room = Data.define(:x, :y, :w, :h) do
      def center_x
        x + (w / 2)
      end

      def center_y
        y + (h / 2)
      end

      def overlaps?(other, padding:)
        x1 = x - padding
        y1 = y - padding
        x2 = x + w + padding
        y2 = y + h + padding
        ox1 = other.x - padding
        oy1 = other.y - padding
        ox2 = other.x + other.w + padding
        oy2 = other.y + other.h + padding
        x1 < ox2 && x2 > ox1 && y1 < oy2 && y2 > oy1
      end

      def each_tile
        (x...(x + w)).each do |tx|
          (y...(y + h)).each do |ty|
            yield tx, ty
          end
        end
      end
    end

    def self.generate(width:, height:, depth:, seed: nil)
      rng = seed ? Random.new(seed) : Random.new
      tiles = Array.new(width * height, "wall")
      rooms = []
      room_count = [4 + depth, 9].min
      attempts = 0

      while rooms.size < room_count && attempts < 200
        w = rng.rand(4..10)
        h = rng.rand(4..8)
        x = rng.rand(1..(width - w - 2))
        y = rng.rand(1..(height - h - 2))
        candidate = Room.new(x, y, w, h)
        rooms << candidate if rooms.none? { |r| r.overlaps?(candidate, padding: 1) }
        attempts += 1
      end

      rooms.each { |r| carve_room(tiles, width, r) }
      rooms.each_cons(2) { |a, b| carve_corridor(tiles, width, a.center_x, a.center_y, b.center_x, b.center_y) }

      raise GenerationError, "Could not place any rooms" if rooms.empty?

      start_room = rooms.first
      player = Player.new(
        x: start_room.center_x,
        y: start_room.center_y,
        hp: 30,
        max_hp: 30,
        damage: 5
      )

      set_tile(tiles, width, rooms.last.center_x, rooms.last.center_y, "stairs")

      entities = []
      items = []
      next_id = 1

      rooms.each_with_index do |room, index|
        next if index.zero?
        next_id = populate_room(room, tiles, width, depth, rng, player, entities, items, next_id)
      end

      world = World.new(
        width: width,
        height: height,
        tiles: tiles,
        player: player,
        entities: entities,
        items: items,
        depth: depth,
        next_id: next_id
      )
      world.compute_fov
      world
    end

    def self.carve_room(tiles, width, room)
      room.each_tile { |tx, ty| set_tile(tiles, width, tx, ty, "floor") }
    end

    def self.carve_corridor(tiles, width, x1, y1, x2, y2)
      x = x1
      y = y1
      while x != x2
        set_tile(tiles, width, x, y, "floor")
        x += (x < x2) ? 1 : -1
      end
      while y != y2
        set_tile(tiles, width, x, y, "floor")
        y += (y < y2) ? 1 : -1
      end
      set_tile(tiles, width, x, y, "floor")
    end

    def self.set_tile(tiles, width, x, y, kind)
      return unless x.between?(0, width - 1) && y.between?(0, (tiles.size / width) - 1)

      tiles[y * width + x] = kind
    end

    def self.populate_room(room, tiles, width, depth, rng, player, entities, items, next_id)
      room.each_tile do |tx, ty|
        next unless tiles[ty * width + tx] == "floor"
        next if tx == player.x && ty == player.y

        roll = rng.rand
        if roll < 0.08
          entities << spawn_enemy(next_id, tx, ty, depth, rng)
          next_id += 1
        elsif roll < 0.13
          items << Item.new(id: next_id, kind: "potion", x: tx, y: ty)
          next_id += 1
        end
      end

      next_id
    end

    def self.spawn_enemy(id, x, y, depth, rng)
      table = if depth > 2
        {goblin: 0.5, orc: 0.35, troll: 0.15}
      else
        {goblin: 0.8, orc: 0.2, troll: 0.0}
      end

      roll = rng.rand
      kind = if roll < table[:goblin]
        "goblin"
      elsif roll < table[:goblin] + table[:orc]
        "orc"
      else
        "troll"
      end

      stats = {
        goblin: {hp: 8, max_hp: 8, damage: 2},
        orc: {hp: 12, max_hp: 12, damage: 3},
        troll: {hp: 20, max_hp: 20, damage: 5}
      }[kind.to_sym]

      Entity.new(id: id, kind: kind, x: x, y: y, **stats)
    end
  end
end
