# frozen_string_literal: true

module Rpg
  class World
    attr_reader :width, :height, :tiles, :explored, :player, :entities, :items, :turn, :depth, :state, :next_id
    attr_accessor :messages, :visible

    def self.new_game(seed: nil)
      DungeonGenerator.generate(width: 60, height: 20, depth: 1, seed: seed)
    end

    def initialize(width:, height:, tiles:, player:, entities:, items:, explored: nil, messages: nil, turn: 0, depth: 1, state: "playing", next_id: 1)
      @width = width
      @height = height
      @tiles = tiles
      @explored = explored || Array.new(width * height, false)
      @player = player
      @entities = entities
      @items = items
      @messages = messages || []
      @turn = turn
      @depth = depth
      @state = state
      @next_id = next_id
      @visible = Set.new
    end

    def tile_at(x, y)
      return "wall" unless in_bounds?(x, y)

      @tiles[y * @width + x]
    end

    def set_tile(x, y, kind)
      return unless in_bounds?(x, y)

      @tiles[y * @width + x] = kind
    end

    def in_bounds?(x, y)
      x >= 0 && x < @width && y >= 0 && y < @height
    end

    def solid?(x, y)
      !in_bounds?(x, y) || tile_at(x, y) == "wall"
    end

    def entity_at(x, y)
      @entities.find { |e| e.x == x && e.y == y && e.alive? }
    end

    def item_at(x, y)
      @items.find { |i| i.x == x && i.y == y }
    end

    def alive_enemies
      @entities.select(&:alive?)
    end

    def move_player(dx, dy)
      return false unless @state == "playing"

      tx = @player.x + dx
      ty = @player.y + dy
      enemy = entity_at(tx, ty)

      if enemy
        Combat.attack(@player, enemy, self)
      elsif !solid?(tx, ty)
        @player.x = tx
        @player.y = ty
      end

      advance_turn
      true
    end

    def rest_player
      return false unless @state == "playing"

      add_message("You wait a moment.")
      advance_turn
      true
    end

    def fire_player(dx, dy)
      return false unless @state == "playing"

      tx = @player.x + dx
      ty = @player.y + dy
      hit = false

      while in_bounds?(tx, ty) && !solid?(tx, ty)
        enemy = entity_at(tx, ty)
        if enemy
          Combat.shoot(@player, enemy, self)
          hit = true
          break
        end
        tx += dx
        ty += dy
      end

      add_message("Your shot flies into the darkness.") unless hit
      advance_turn
      true
    end

    def move_entity(entity, dx, dy)
      return false if entity.dead?

      tx = entity.x + dx
      ty = entity.y + dy
      return false if solid?(tx, ty)

      if tx == @player.x && ty == @player.y
        Combat.attack(entity, @player, self)
        return true
      end

      return false if entity_at(tx, ty)

      entity.x = tx
      entity.y = ty
      true
    end

    def pickup_item
      item = item_at(@player.x, @player.y)
      if item
        use_item(item)
      else
        add_message("There is nothing here to pick up.")
      end
    end

    def use_item(item)
      case item.kind
      when "potion"
        heal = 10
        @player.hp = [@player.hp + heal, @player.max_hp].min
        add_message("You drink a potion and recover #{heal} HP.")
      end
      @items.delete(item)
    end

    def descend
      return unless @state == "playing"
      return unless tile_at(@player.x, @player.y) == "stairs"

      if alive_enemies.any?
        add_message("Enemies block the stairs!")
        return
      end

      new_world = DungeonGenerator.generate(width: @width, height: @height, depth: @depth + 1)
      new_world.messages = @messages.last(20)
      new_world.add_message("You descend deeper into the dungeon...")
      new_world
    end

    def compute_fov(radius: 8)
      @visible = Fov.compute(self, radius: radius)
      @visible.each { |x, y| @explored[y * @width + x] = true if in_bounds?(x, y) }
    end

    def visible?(x, y)
      @visible.include?([x, y])
    end

    def explored?(x, y)
      return false unless in_bounds?(x, y)

      @explored[y * @width + x]
    end

    def add_message(text)
      @messages << text
      @messages.shift while @messages.size > 100
    end

    def to_h
      {
        width: @width,
        height: @height,
        tiles: @tiles,
        explored: @explored,
        player: @player.to_h,
        entities: @entities.map(&:to_h),
        items: @items.map(&:to_h),
        messages: @messages,
        turn: @turn,
        depth: @depth,
        state: @state,
        next_id: @next_id
      }
    end

    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym)
      new(
        width: hash[:width],
        height: hash[:height],
        tiles: hash[:tiles],
        explored: hash[:explored],
        player: Player.from_h(hash[:player]),
        entities: (hash[:entities] || []).map { |e| Entity.from_h(e) },
        items: (hash[:items] || []).map { |i| Item.from_h(i) },
        messages: hash[:messages] || [],
        turn: hash[:turn] || 0,
        depth: hash[:depth] || 1,
        state: hash[:state] || "playing",
        next_id: hash[:next_id] || 1
      )
    end

    private

    def advance_turn
      @turn += 1
      compute_fov
      enemy_turns
      cleanup
      compute_fov
      check_game_over
    end

    def enemy_turns
      alive_enemies.each do |enemy|
        Ai.take_turn(enemy, self)
        break if @state == "dead"
      end
    end

    def cleanup
      @entities.reject!(&:dead?)
    end

    def check_game_over
      return if @player.hp > 0

      @player.hp = 0
      @state = "dead"
      add_message("You died! Press 'n' for a new game.")
    end
  end
end
