# frozen_string_literal: true

require "active_model"

module Rpg
  class World
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :width, :integer
    attribute :height, :integer
    attribute :tiles, default: -> { [] }
    attribute :explored, default: -> { [] }
    attribute :messages, default: -> { [] }
    attribute :turn, :integer, default: 0
    attribute :depth, :integer, default: 1
    attribute :state, :string, default: "playing"
    attribute :next_id, :integer, default: 1
    attribute :kills, :integer, default: 0
    attribute :difficulty, :string, default: "Normal"

    attr_accessor :player, :entities, :items, :visible

    def self.new_game(seed: nil, difficulty: "Normal", width: 60, height: 20)
      DungeonGenerator.generate(width: width, height: height, depth: 1, seed: seed, difficulty: difficulty)
    end

    def initialize(attributes = {})
      super
      self.visible = Set.new
      self.explored = Array.new(width * height, false) if explored.empty? && width && height
    end

    def tile_at(x, y)
      return "wall" unless in_bounds?(x, y)

      tiles[y * width + x]
    end

    def set_tile(x, y, kind)
      return unless in_bounds?(x, y)

      tiles[y * width + x] = kind
    end

    def in_bounds?(x, y)
      x >= 0 && x < width && y >= 0 && y < height
    end

    def solid?(x, y)
      !in_bounds?(x, y) || tile_at(x, y) == "wall"
    end

    def entity_at(x, y)
      entities.find { |e| e.x == x && e.y == y && e.alive? }
    end

    def item_at(x, y)
      items.find { |i| i.x == x && i.y == y }
    end

    def alive_enemies
      entities.select(&:alive?)
    end

    def move_player(dx, dy)
      return false unless state == "playing"

      tx = player.x + dx
      ty = player.y + dy
      enemy = entity_at(tx, ty)

      if enemy
        Combat.attack(player, enemy, self)
      elsif !solid?(tx, ty)
        player.x = tx
        player.y = ty
      end

      advance_turn
      true
    end

    def rest_player
      return false unless state == "playing"

      add_message("You wait a moment.")
      advance_turn
      true
    end

    def fire_player(dx, dy)
      return false unless state == "playing"

      tx = player.x + dx
      ty = player.y + dy
      hit = false

      while in_bounds?(tx, ty) && !solid?(tx, ty)
        enemy = entity_at(tx, ty)
        if enemy
          Combat.shoot(player, enemy, self)
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

      if tx == player.x && ty == player.y
        Combat.attack(entity, player, self)
        return true
      end

      return false if entity_at(tx, ty)

      entity.x = tx
      entity.y = ty
      true
    end

    def pickup_item
      item = item_at(player.x, player.y)
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
        player.hp = [player.hp + heal, player.max_hp].min
        add_message("You drink a potion and recover #{heal} HP.")
      when "potion_of_strength"
        player.strength_turns = 20
        add_message("You feel stronger! Melee damage is boosted for 20 turns.")
      when "potion_of_vision"
        player.vision_turns = 30
        add_message("Your sight sharpens! Vision range is extended for 30 turns.")
      when "scroll_of_mapping"
        (0...height).each do |y|
          (0...width).each do |x|
            explored[y * width + x] = true
          end
        end
        add_message("The scroll reveals the entire dungeon level.")
      end
      items.delete(item)
      compute_fov
    end

    def descend
      return unless state == "playing"
      return unless tile_at(player.x, player.y) == "stairs"

      if alive_enemies.any?
        add_message("Enemies block the stairs!")
        return
      end

      new_world = DungeonGenerator.generate(width: width, height: height, depth: depth + 1, difficulty: difficulty)
      new_world.messages = messages.last(20)
      new_world.add_message("You descend deeper into the dungeon...")
      new_world
    end

    def compute_fov(radius: effective_vision_radius)
      self.visible = Fov.compute(self, radius: radius)
      visible.each { |x, y| explored[y * width + x] = true if in_bounds?(x, y) }
    end

    def effective_vision_radius
      base = 8
      return base unless player.vision_turns.to_i > 0

      base + 4
    end

    def visible?(x, y)
      visible.include?([x, y])
    end

    def explored?(x, y)
      return false unless in_bounds?(x, y)

      explored[y * width + x]
    end

    def add_message(text)
      messages << text
      messages.shift while messages.size > 100
    end

    def xp_to_next_level
      player.level * 100
    end

    def check_level_up
      while player.xp >= xp_to_next_level
        player.level += 1
        player.max_hp += 5
        player.hp = player.max_hp
        player.damage += 1
        add_message("You reach level #{player.level}!")
      end
    end

    def to_h
      attributes.symbolize_keys.merge(
        player: player.to_h,
        entities: entities.map(&:to_h),
        items: items.map(&:to_h)
      )
    end

    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym)
      new(
        hash.slice(:width, :height, :tiles, :explored, :messages, :turn, :depth, :state, :next_id, :difficulty).merge(
          player: Player.from_h(hash[:player]),
          entities: (hash[:entities] || []).map { |e| Entity.from_h(e) },
          items: (hash[:items] || []).map { |i| Item.from_h(i) }
        )
      )
    end

    private

    def advance_turn
      self.turn += 1
      player.vision_turns -= 1 if player.vision_turns.to_i > 0
      player.strength_turns -= 1 if player.strength_turns.to_i > 0
      compute_fov
      enemy_turns
      cleanup
      compute_fov
      check_game_over
    end

    def enemy_turns
      alive_enemies.each do |enemy|
        Ai.take_turn(enemy, self)
        break if state == "dead"
      end
    end

    def cleanup
      entities.reject!(&:dead?)
    end

    def check_game_over
      return if player.hp > 0

      player.hp = 0
      self.state = "dead"
      add_message("You died! Press 'n' for a new game.")
    end
  end
end
