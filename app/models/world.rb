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
    attribute :shop_stock, default: -> { [] }
    # Snapshot of this level's entities at generation time, used to respawn enemies when the
    # player rests at a bonfire (Phase 2). Captured by DungeonGenerator; round-trips as data.
    attribute :spawn_snapshot, default: -> { [] }

    attr_accessor :player, :entities, :items, :inventory, :visible, :sounds

    def self.new_game(seed: nil, difficulty: "Normal", width: 60, height: 20)
      DungeonGenerator.generate(width: width, height: height, depth: 1, seed: seed, difficulty: difficulty)
    end

    def initialize(attributes = {})
      super
      self.visible = Set.new
      self.inventory ||= []
      self.sounds = []
      self.explored = Array.new(width * height, false) if explored.empty? && width && height
    end

    # Records a transient sound cue for an event that just occurred. Cues accumulate on the
    # in-memory world and are drained by the controller after the action, before the next
    # render re-deserializes a fresh world. They are intentionally not part of to_h/from_h.
    def cue(name)
      sounds << name
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

    # A living, attackable enemy at the tile — excludes inert bloodstains (which share the
    # entities list but must not be attacked, block movement, or gate the stairs).
    def enemy_at(x, y)
      entities.find { |e| e.x == x && e.y == y && e.alive? && e.kind != "bloodstain" }
    end

    def item_at(x, y)
      items.find { |i| i.x == x && i.y == y }
    end

    def bloodstain_at(x, y)
      entities.find { |e| e.kind == "bloodstain" && e.x == x && e.y == y }
    end

    def alive_enemies
      entities.select { |e| e.alive? && e.kind != "bloodstain" }
    end

    def on_stairs?
      tile_at(player.x, player.y) == "stairs"
    end

    def on_upstairs?
      tile_at(player.x, player.y) == "upstairs"
    end

    def on_bonfire?
      tile_at(player.x, player.y) == "bonfire"
    end

    # Returns the [x, y] of the first tile of the given kind, or nil if none exists.
    def find_tile(kind)
      index = tiles.index(kind)
      return nil unless index

      [index % width, index / width]
    end

    def player_damage
      Equipment.player_damage(player, inventory)
    end

    def player_defense
      Equipment.player_defense(player, inventory)
    end

    def equipped_weapon
      Equipment.find(player.weapon_id, inventory)
    end

    def equipped_armor
      Equipment.find(player.armor_id, inventory)
    end

    def move_player(dx, dy)
      return false unless state == "playing"

      tx = player.x + dx
      ty = player.y + dy
      enemy = enemy_at(tx, ty)

      if enemy
        Combat.attack(player, enemy, self)
      elsif !solid?(tx, ty)
        player.x = tx
        player.y = ty
        recover_bloodstain
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

    # Full heal, refill estus, respawn this floor's enemies, and set this bonfire as the
    # respawn anchor. The signature soulslike trade-off: safety now, a fresh fight next push.
    def rest_at_bonfire
      return false unless on_bonfire?

      player.hp = player.max_hp
      player.estus_charges = player.max_estus_charges
      respawn_enemies!
      player.respawn_depth = depth
      player.respawn_x = player.x
      player.respawn_y = player.y
      add_message("You rest at the bonfire. The way ahead stirs again.")
      cue(:bonfire)
      true
    end

    # Drink one estus charge to recover a chunk of HP. Costs a turn. Refilled only at bonfires.
    def quaff_estus
      return false unless state == "playing"

      if player.estus_charges.to_i <= 0
        add_message("Your estus flask is empty.")
        return false
      end

      heal = (player.max_hp * 0.4).ceil
      player.hp = [player.hp + heal, player.max_hp].min
      player.estus_charges -= 1
      add_message("You drink estus and recover #{heal} HP.")
      cue(:pickup)
      advance_turn
      true
    end

    # Restore this floor's enemies from the generation snapshot, preserving any bloodstain.
    def respawn_enemies!
      stains = entities.select { |e| e.kind == "bloodstain" }
      self.entities = spawn_snapshot.map { |e| Entity.from_h(e) } + stains
    end

    def fire_player(dx, dy)
      return false unless state == "playing"

      tx = player.x + dx
      ty = player.y + dy
      hit = false

      while in_bounds?(tx, ty) && !solid?(tx, ty)
        enemy = enemy_at(tx, ty)
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

      return false if enemy_at(tx, ty)

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
        cue(:pickup)
      when "potion_of_strength"
        player.strength_turns = 20
        add_message("You feel stronger! Melee damage is boosted for 20 turns.")
        cue(:pickup)
      when "potion_of_vision"
        player.vision_turns = 30
        add_message("Your sight sharpens! Vision range is extended for 30 turns.")
        cue(:pickup)
      when "scroll_of_mapping"
        (0...height).each do |y|
          (0...width).each do |x|
            explored[y * width + x] = true
          end
        end
        add_message("The scroll reveals the entire dungeon level.")
        cue(:pickup)
      when "chest"
        amount = [item.value, 1].max
        player.souls += amount
        add_message("You open a chest and find #{amount} souls.")
        cue(:gold)
      when "weapon", "armor", "ring"
        equip_item(item)
      end
      items.delete(item)
      compute_fov
    end

    def buy_item(shop_index)
      item = shop_stock[shop_index.to_i]
      return nil, "There is nothing for sale there." unless item
      return nil, "You cannot afford #{item.name}." if player.souls < item.value

      player.souls -= item.value
      equip_item(item)
      shop_stock.delete_at(shop_index.to_i)
      cue(:buy)
      [item, "You buy #{item.name} for #{item.value} gold."]
    end

    def equip_item(item)
      case item.kind
      when "weapon"
        player.weapon_id = item.id
      when "armor"
        player.armor_id = item.id
      when "ring"
        player.ring_id = item.id
      end
      inventory << item unless inventory.include?(item)
      add_message("You equip #{item.name}.")
      cue(:equip)
    end

    def restock_shop(rng)
      self.shop_stock = 3.times.map do
        kind = %w[weapon armor ring].sample(random: rng)
        template = Equipment.random_item(kind, rng, depth)
        item = Item.new(
          id: next_id,
          kind: kind,
          name: Equipment.item_name(kind, template),
          value: template[:value],
          stats: stringify_keys(template.slice(:damage, :defense))
        )
        self.next_id += 1
        item
      end
    end

    # Level/run transitions (descend, ascend, level caching) are owned by Rpg::Run, which keeps
    # the player separate from per-level state so the run's floors can persist.

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

    # Souls required to buy the next level. Leveling is no longer automatic — the player spends
    # souls at a bonfire via {level_up!}.
    def soul_cost_for_next_level
      player.level * 100
    end

    # Spends souls to gain a level (called from the bonfire screen). Returns true on success,
    # false when the player can't afford it.
    def level_up!
      cost = soul_cost_for_next_level
      return false if player.souls < cost

      player.souls -= cost
      player.level += 1
      player.max_hp += 5
      player.hp = player.max_hp
      player.damage += 1
      add_message("You level up to level #{player.level}!")
      cue(:level_up)
      true
    end

    def to_h
      attributes.symbolize_keys.merge(
        player: player.to_h,
        entities: entities.map(&:to_h),
        items: items.map(&:to_h),
        inventory: inventory.map(&:to_h),
        shop_stock: shop_stock.map(&:to_h)
      )
    end

    # Serialized level state WITHOUT the player. Rpg::Run stores levels this way and owns the
    # single player separately, so one character can move between persistent floors.
    def to_level_h
      to_h.tap { |h| h.delete(:player) }
    end

    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym)
      new(
        hash.slice(:width, :height, :tiles, :explored, :messages, :turn, :depth, :state, :next_id, :kills, :difficulty, :shop_stock, :spawn_snapshot).merge(
          player: Player.from_h(hash[:player]),
          entities: (hash[:entities] || []).map { |e| Entity.from_h(e) },
          items: (hash[:items] || []).map { |i| Item.from_h(i) },
          inventory: (hash[:inventory] || []).map { |i| Item.from_h(i) },
          shop_stock: (hash[:shop_stock] || []).map { |i| Item.from_h(i) }
        )
      )
    end

    # Rebuilds a level from a to_level_h payload, injecting the run's live player object (so
    # mutations during play are written back to the run, not to a throwaway copy).
    def self.from_level_h(hash, player:)
      hash = hash.transform_keys(&:to_sym).merge(player: player.to_h)
      world = from_h(hash)
      world.player = player
      world
    end

    private

    # When the player steps onto their dropped bloodstain, reclaim its souls and clear it.
    def recover_bloodstain
      stain = bloodstain_at(player.x, player.y)
      return unless stain

      player.souls += stain.souls.to_i
      add_message("You reclaim #{stain.souls} souls from your bloodstain.")
      entities.delete(stain)
      cue(:gold)
    end

    def stringify_keys(hash)
      hash.transform_keys(&:to_s)
    end

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
      cue(:death)
    end
  end
end
