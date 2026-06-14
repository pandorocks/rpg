# frozen_string_literal: true

module Rpg
  # A Run is the whole playthrough: the single authoritative Player plus a cache of the floors
  # the player has generated, keyed by depth. Each cached level is a World#to_level_h payload
  # (level state WITHOUT the player). The player is owned here and injected into whichever
  # level is current, so one character moves between PERSISTENT floors — the foundation the
  # soulslike loop (run back to your bloodstain) sits on.
  class Run
    attr_accessor :player, :levels, :current_depth, :width, :height, :difficulty, :mode, :next_id

    def self.new_game(difficulty: "Normal", width: 60, height: 20, mode: "respawn", seed: nil)
      run = new(width: width, height: height, difficulty: difficulty, mode: mode)
      world = run.send(:generate_level, 1, seed: seed)
      run.player = world.player
      run.next_id = world.next_id
      # The starting bonfire is the first respawn anchor (the player spawns on it).
      run.player.respawn_depth = 1
      run.player.respawn_x = world.player.x
      run.player.respawn_y = world.player.y
      run.levels[1] = world.to_level_h
      run.current_depth = 1
      run
    end

    def initialize(player: nil, levels: nil, current_depth: 1, width: 60, height: 20,
      difficulty: "Normal", mode: "respawn", next_id: 1)
      @player = player
      @levels = levels || {}
      @current_depth = current_depth
      @width = width
      @height = height
      @difficulty = difficulty
      @mode = mode
      @next_id = next_id
    end

    # The live World for the current floor, with the run's player injected and FOV computed.
    def current_world
      build_world(current_depth)
    end

    # Writes a played level back into the cache and captures the player + id counter from it.
    def save_world(world)
      @player = world.player
      @next_id = world.next_id
      @levels[current_depth] = world.to_level_h
      world
    end

    def has_level?(depth)
      @levels.key?(depth)
    end

    # Move one floor deeper. Returns the new current world, or nil when blocked (not on stairs,
    # or enemies still alive). Generates the floor on first visit, reloads it otherwise.
    def descend
      world = current_world
      return nil unless world.on_stairs?

      if world.alive_enemies.any?
        world.add_message("Enemies block the stairs!")
        save_world(world)
        return nil
      end

      save_world(world)
      @current_depth += 1
      target = has_level?(@current_depth) ? build_world(@current_depth) : generate_and_cache(@current_depth)
      enter(target, entrance: "upstairs", direction: :descend)
    end

    # Move one floor up (only meaningful from depth > 1, standing on an upstairs tile). The
    # destination floor always already exists. Returns the new current world, or nil if blocked.
    def ascend
      return nil if @current_depth <= 1

      world = current_world
      return nil unless world.on_upstairs?

      if world.alive_enemies.any?
        world.add_message("Enemies block the way back!")
        save_world(world)
        return nil
      end

      save_world(world)
      @current_depth -= 1
      target = build_world(@current_depth)
      enter(target, entrance: "stairs", direction: :ascend)
    end

    # Soulslike death (respawn mode): drop the player's souls as a bloodstain on the floor where
    # they fell (replacing any older bloodstain — its souls are lost), reset every floor's
    # enemies, and wake the player at their last bonfire with full HP and estus. The dead world
    # passed in is the floor death happened on. Returns the world the player wakes up in.
    def respawn!(dead_world)
      # Adopt the just-died player as the run's player first: it carries this turn's mutated
      # state (souls, position). Otherwise save_world below would overwrite our soul reset.
      @player = dead_world.player
      remove_bloodstains
      # The dead floor is a live copy that may still hold the prior bloodstain; strip it too so
      # save_world below doesn't write it back after remove_bloodstains cleared the cache.
      dead_world.entities.reject! { |e| e.kind == "bloodstain" }
      if player.souls.to_i > 0
        dead_world.entities << Entity.new(
          id: bump_id, kind: "bloodstain", x: player.x, y: player.y,
          hp: 0, max_hp: 0, damage: 0, dead: false, souls: player.souls
        )
      end
      player.souls = 0
      save_world(dead_world)
      respawn_all_enemies

      self.current_depth = player.respawn_depth || 1
      target = build_world(current_depth)
      anchor_x, anchor_y = player.respawn_x, player.respawn_y
      anchor_x, anchor_y = target.find_tile("bonfire") if anchor_x.nil?
      player.x = anchor_x
      player.y = anchor_y
      player.hp = player.max_hp
      player.estus_charges = player.max_estus_charges
      target.state = "playing"
      target.add_message("You died. Recover your lost souls.")
      target.cue(:death)
      target.compute_fov
      save_world(target)
      target
    end

    # Reset every cached floor's enemies from its generation snapshot (bloodstains survive).
    def respawn_all_enemies
      levels.each_key do |depth|
        world = World.from_level_h(levels[depth], player: player)
        world.respawn_enemies!
        levels[depth] = world.to_level_h
      end
    end

    def to_h
      {
        current_depth: current_depth,
        width: width,
        height: height,
        difficulty: difficulty,
        mode: mode,
        next_id: next_id,
        player: player.to_h,
        levels: levels.transform_keys(&:to_s)
      }
    end

    def self.from_h(hash)
      hash = hash.transform_keys(&:to_sym)
      new(
        player: Player.from_h(hash[:player]),
        levels: (hash[:levels] || {}).transform_keys(&:to_i),
        current_depth: hash[:current_depth],
        width: hash[:width],
        height: hash[:height],
        difficulty: hash[:difficulty],
        mode: hash[:mode],
        next_id: hash[:next_id]
      )
    end

    private

    def bump_id
      id = @next_id
      @next_id += 1
      id
    end

    # Strip any existing bloodstain from every cached floor (the previous death's souls are lost).
    def remove_bloodstains
      levels.each_key do |depth|
        world = World.from_level_h(levels[depth], player: player)
        next unless world.entities.any? { |e| e.kind == "bloodstain" }

        world.entities.reject! { |e| e.kind == "bloodstain" }
        levels[depth] = world.to_level_h
      end
    end

    # Reposition the player at the destination floor's entrance, announce it, persist, return.
    def enter(world, entrance:, direction:)
      x, y = world.find_tile(entrance) || world.find_tile("stairs") || [player.x, player.y]
      player.x = x
      player.y = y
      world.add_message(transition_message(world.biome, direction))
      world.cue(:descend)
      world.compute_fov
      save_world(world)
      world
    end

    def transition_message(biome, direction)
      name = Biome.name(biome)
      if direction == :descend
        "You descend into #{article(name)} #{name}..."
      else
        "You climb back up into #{article(name)} #{name}..."
      end
    end

    def article(word)
      %w[A E I O U].include?(word[0].upcase) ? "an" : "a"
    end

    def build_world(depth)
      world = World.from_level_h(@levels.fetch(depth), player: @player)
      world.next_id = @next_id
      world.compute_fov
      world
    end

    def generate_and_cache(depth)
      world = generate_level(depth)
      @next_id = world.next_id
      @levels[depth] = world.to_level_h
      build_world(depth)
    end

    def generate_level(depth, seed: nil)
      world = DungeonGenerator.generate(
        width: width, height: height, depth: depth,
        difficulty: difficulty, biome: Biome.for_depth(depth),
        next_id: @next_id, seed: seed
      )
      world.restock_shop(Random.new)
      world
    end
  end
end
