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

    def self.generate(width:, height:, depth:, seed: nil, difficulty: "Normal")
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
        hp: GameBalance.apply_player_hp(30, difficulty),
        max_hp: GameBalance.apply_player_hp(30, difficulty),
        damage: GameBalance.apply_player_damage(5, difficulty)
      )

      set_tile(tiles, width, rooms.last.center_x, rooms.last.center_y, "stairs")

      entities = []
      items = []
      next_id = 1

      rooms.each_with_index do |room, index|
        next if index.zero?
        next_id = populate_room(room, tiles, width, depth, rng, player, entities, items, next_id, difficulty)
      end

      world = World.new(
        width: width,
        height: height,
        tiles: tiles,
        player: player,
        entities: entities,
        items: items,
        depth: depth,
        next_id: next_id,
        difficulty: difficulty
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

    def self.populate_room(room, tiles, width, depth, rng, player, entities, items, next_id, difficulty)
      room.each_tile do |tx, ty|
        next unless tiles[ty * width + tx] == "floor"
        next if tx == player.x && ty == player.y

        roll = rng.rand
        if roll < 0.08
          entities << spawn_enemy(next_id, tx, ty, depth, rng, difficulty)
          next_id += 1
        elsif roll < 0.13
          items << spawn_item(next_id, tx, ty, depth, rng)
          next_id += 1
        end
      end

      next_id
    end

    def self.spawn_item(id, x, y, depth, rng)
      kind = random_item_kind(rng)
      if kind == "equipment"
        eq_kind = %w[weapon armor ring].sample(random: rng)
        template = Equipment.random_item(eq_kind, rng, depth)
        Item.new(
          id: id,
          kind: eq_kind,
          x: x,
          y: y,
          name: Equipment.item_name(eq_kind, template),
          value: template[:value],
          stats: stringify_keys(template.slice(:damage, :defense))
        )
      else
        Item.new(id: id, kind: kind, x: x, y: y)
      end
    end

    def self.stringify_keys(hash)
      hash.transform_keys(&:to_s)
    end

    def self.random_item_kind(rng)
      {
        "potion" => 0.30,
        "potion_of_strength" => 0.10,
        "potion_of_vision" => 0.10,
        "scroll_of_mapping" => 0.10,
        "chest" => 0.15,
        "equipment" => 0.25
      }.max_by { |_, weight| rng.rand**(1.0 / weight) }.first
    end

    def self.spawn_enemy(id, x, y, depth, rng, difficulty)
      kind = random_enemy_kind(depth, rng)

      stats = {
        goblin: {hp: 8, max_hp: 8, damage: 2, gold: 5},
        orc: {hp: 12, max_hp: 12, damage: 3, gold: 10},
        troll: {hp: 20, max_hp: 20, damage: 5, gold: 20},
        zombie: {hp: 18, max_hp: 18, damage: 2, gold: 8},
        robot: {hp: 22, max_hp: 22, damage: 4, gold: 18},
        ghost: {hp: 14, max_hp: 14, damage: 4, gold: 15},
        dragon: {hp: 45, max_hp: 45, damage: 9, gold: 75}
      }[kind.to_sym]

      Entity.new(
        id: id,
        kind: kind,
        x: x,
        y: y,
        hp: GameBalance.apply_enemy_hp(stats[:hp], difficulty),
        max_hp: GameBalance.apply_enemy_hp(stats[:max_hp], difficulty),
        damage: GameBalance.apply_enemy_damage(stats[:damage], difficulty),
        gold: stats[:gold]
      )
    end

    def self.random_enemy_kind(depth, rng)
      table = if depth > 5
        {goblin: 0.10, orc: 0.20, troll: 0.25, zombie: 0.15, robot: 0.15, ghost: 0.10, dragon: 0.05}
      elsif depth > 2
        {goblin: 0.30, orc: 0.25, troll: 0.15, zombie: 0.15, robot: 0.10, ghost: 0.05, dragon: 0.0}
      else
        {goblin: 0.50, orc: 0.25, troll: 0.0, zombie: 0.15, robot: 0.10, ghost: 0.0, dragon: 0.0}
      end

      roll = rng.rand
      cumulative = 0.0
      table.each do |kind, weight|
        cumulative += weight
        return kind.to_s if roll < cumulative
      end
      table.keys.first.to_s
    end
  end
end
