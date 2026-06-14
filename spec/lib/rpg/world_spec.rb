# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::World do
  def small_world
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    enemy = Rpg::Entity.new(id: 1, kind: "goblin", x: 3, y: 1, hp: 6, max_hp: 6, damage: 2)
    item = Rpg::Item.new(id: 2, kind: "potion", x: 1, y: 3)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [enemy], items: [item])
    world.compute_fov
    world
  end

  it "moves the player to an empty floor tile" do
    world = small_world
    world.move_player(1, 0)

    expect([world.player.x, world.player.y]).to eq([2, 1])
    expect(world.turn).to eq(1)
  end

  it "does not move into walls" do
    world = small_world
    world.move_player(0, -1)

    expect([world.player.x, world.player.y]).to eq([1, 1])
  end

  it "attacks enemies when moving into them" do
    world = small_world
    world.move_player(1, 0)
    world.move_player(1, 0)

    enemy = world.alive_enemies.first
    expect(enemy.hp).to be < enemy.max_hp
    expect(world.messages.any? { |m| m.include?("hit") }).to be true
  end

  it "kills enemies and awards souls" do
    world = small_world
    4.times { world.move_player(1, 0) if world.state == "playing" }

    expect(world.alive_enemies).to be_empty
    expect(world.player.souls).to be_positive
    expect(world.messages.any? { |m| m.include?("dies") }).to be true
  end

  it "picks up and uses potions" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 10, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "potion", x: 1, y: 2)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item

    expect(world.player.hp).to eq(20)
    expect(world.items).to be_empty
  end

  it "sets game over when the player dies" do
    world = small_world
    world.player.hp = 1
    # Move next to the goblin so it can attack on its turn.
    world.move_player(1, 0)

    expect(world.state).to eq("dead")
    expect(world.messages.last).to include("died")
  end

  it "shoots the first enemy along a straight line" do
    world = small_world
    world.fire_player(1, 0)

    enemy = world.entities.first
    expect(enemy.hp).to be < enemy.max_hp
    expect(world.messages.any? { |m| m.include?("shoot") }).to be true
    expect(world.turn).to eq(1)
  end

  it "shoots stop at walls" do
    world = small_world
    world.fire_player(0, -1)

    expect(world.entities.first.hp).to eq(world.entities.first.max_hp)
    expect(world.messages.last).to include("darkness")
  end

  it "uses a scroll of mapping to reveal the whole level" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "scroll_of_mapping", x: 1, y: 2)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item

    expect(world.explored.all?).to be true
    expect(world.messages.any? { |m| m.include?("reveals") }).to be true
  end

  it "uses a potion of strength to boost damage" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    enemy = Rpg::Entity.new(id: 1, kind: "goblin", x: 3, y: 1, hp: 20, max_hp: 20, damage: 2)
    item = Rpg::Item.new(id: 2, kind: "potion_of_strength", x: 1, y: 2)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [enemy], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item
    world.move_player(1, 0)

    expect(enemy.hp).to eq(20 - 8)
    expect(world.messages.any? { |m| m.include?("stronger") }).to be true
  end

  it "uses a potion of vision to extend sight" do
    width = 20
    height = 20
    tiles = Array.new(width * height, "floor")
    player = Rpg::Player.new(x: 10, y: 10, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "potion_of_vision", x: 10, y: 11)
    world = described_class.new(width: width, height: height, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov
    base_visible = world.visible.size

    world.move_player(0, 1)
    world.pickup_item

    expect(world.visible.size).to be > base_visible
    expect(world.player.vision_turns).to be_positive
  end

  it "serializes and deserializes round-trip" do
    world = small_world
    world.move_player(1, 0)
    world.add_message("hello")

    copy = described_class.from_h(world.to_h)

    expect(copy.player.x).to eq(world.player.x)
    expect(copy.turn).to eq(world.turn)
    expect(copy.messages.last).to eq("hello")
  end

  it "absorbs souls (intrinsic value + bounty) from enemies" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    enemy = Rpg::Entity.new(id: 1, kind: "goblin", x: 3, y: 1, hp: 6, max_hp: 6, damage: 2, gold: 10)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [enemy], items: [])
    world.compute_fov

    4.times { world.move_player(1, 0) if world.state == "playing" }

    # goblin base 20 (Normal) + 10 bounty
    expect(world.player.souls).to eq(30)
    expect(world.messages.any? { |m| m.include?("absorb") }).to be true
  end

  it "opens chests for souls" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "chest", x: 1, y: 2, value: 25)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item

    expect(world.player.souls).to eq(25)
    expect(world.messages.any? { |m| m.include?("chest") }).to be true
  end

  it "equips weapons from the ground" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "weapon", x: 1, y: 2, name: "Test Sword", stats: {"damage" => 3})
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item

    expect(world.player.weapon_id).to eq(2)
    expect(world.player_damage).to eq(8)
  end

  describe "soulslike mechanics" do
    def floor_world
      tiles = Array.new(25, "wall")
      (1..3).each { |x| (1..3).each { |y| tiles[y * 5 + x] = "floor" } }
      player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
      world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [])
      world.compute_fov
      world
    end

    it "drinks estus to heal and refuses when the flask is empty" do
      world = floor_world
      world.player.max_hp = 100
      world.player.hp = 50
      world.player.estus_charges = 1

      expect(world.quaff_estus).to be(true)
      expect(world.player.hp).to eq(90) # +40% of max
      expect(world.player.estus_charges).to eq(0)
      expect(world.quaff_estus).to be(false)
      expect(world.player.hp).to eq(90)
    end

    it "levels up by spending souls, and refuses when too poor" do
      world = floor_world
      world.player.souls = 250

      expect(world.level_up!).to be(true)
      expect(world.player.level).to eq(2)
      expect(world.player.souls).to eq(150) # cost was 100

      world.player.souls = 10
      expect(world.level_up!).to be(false) # next costs 200
      expect(world.player.level).to eq(2)
    end

    it "reclaims souls when stepping onto a bloodstain" do
      world = floor_world
      world.player.souls = 0
      world.entities << Rpg::Entity.new(id: 7, kind: "bloodstain", x: 2, y: 1, souls: 99)

      world.move_player(1, 0)

      expect(world.player.souls).to eq(99)
      expect(world.bloodstain_at(2, 1)).to be_nil
    end

    it "ignores bloodstains when gating the stairs" do
      world = floor_world
      world.entities << Rpg::Entity.new(id: 7, kind: "bloodstain", x: 2, y: 2, souls: 5)

      expect(world.alive_enemies).to be_empty
    end

    it "rests at a bonfire: full heal, refilled estus, respawned enemies, new anchor" do
      world = Rpg::DungeonGenerator.generate(width: 40, height: 20, depth: 1, seed: 3)
      bx, by = world.find_tile("bonfire")
      world.player.x = bx
      world.player.y = by
      world.player.hp = 1
      world.player.estus_charges = 0
      world.entities.each { |e| e.dead = true } # wipe the floor

      expect(world.rest_at_bonfire).to be(true)
      expect(world.player.hp).to eq(world.player.max_hp)
      expect(world.player.estus_charges).to eq(world.player.max_estus_charges)
      expect([world.player.respawn_x, world.player.respawn_y]).to eq([bx, by])
      expect(world.alive_enemies.size).to eq(world.spawn_snapshot.size) # enemies returned
    end
  end

  it "round-trips the spawn snapshot" do
    world = described_class.new_game(width: 40, height: 20)
    reloaded = described_class.from_h(world.to_h)

    expect(reloaded.spawn_snapshot).to eq(world.spawn_snapshot)
  end

  it "persists the kill count across a save/load round-trip" do
    world = small_world
    4.times { world.move_player(1, 0) if world.state == "playing" }
    expect(world.kills).to be > 0

    reloaded = described_class.from_h(world.to_h)

    expect(reloaded.kills).to eq(world.kills)
  end

  it "removes equipment from the floor once picked up" do
    tiles = Array.new(25, "wall")
    (1..3).each { |x| (1..3).each { |y| tiles[y * 5 + x] = "floor" } }
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "weapon", x: 1, y: 2, name: "Test Sword", stats: {"damage" => 3})
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov

    world.move_player(0, 1)
    world.pickup_item

    expect(world.items).not_to include(item)
    expect(world.item_at(1, 2)).to be_nil
  end

  it "keeps equipped gear after a save/load round-trip" do
    tiles = Array.new(25, "wall")
    (1..3).each { |x| (1..3).each { |y| tiles[y * 5 + x] = "floor" } }
    player = Rpg::Player.new(x: 1, y: 2, hp: 20, max_hp: 20, damage: 5)
    item = Rpg::Item.new(id: 2, kind: "weapon", x: 1, y: 2, name: "Test Sword", stats: {"damage" => 3})
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item])
    world.compute_fov
    world.pickup_item

    reloaded = described_class.from_h(world.to_h)

    expect(reloaded.equipped_weapon&.name).to eq("Test Sword")
    expect(reloaded.player_damage).to eq(8)
  end

  it "restocks the shop with uniquely identified items" do
    tiles = Array.new(25, "wall")
    (1..3).each { |x| (1..3).each { |y| tiles[y * 5 + x] = "floor" } }
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [], next_id: 10)

    world.restock_shop(Random.new(1))
    ids = world.shop_stock.map(&:id)

    expect(ids).to all(be_a(Integer))
    expect(ids.uniq).to eq(ids)
    expect(world.next_id).to eq(10 + world.shop_stock.size)
  end

  it "applies equipment bonuses in combat from inventory, not floor items" do
    tiles = Array.new(25, "wall")
    (1..3).each { |x| (1..3).each { |y| tiles[y * 5 + x] = "floor" } }
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5)
    sword = Rpg::Item.new(id: 2, kind: "weapon", name: "Test Sword", stats: {"damage" => 3})
    enemy = Rpg::Entity.new(id: 3, kind: "goblin", x: 2, y: 1, hp: 50, max_hp: 50, damage: 0)
    # Weapon lives only in inventory (equipped), never on the floor (world.items is empty).
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [enemy], items: [], inventory: [sword])
    world.player.weapon_id = 2
    world.compute_fov

    world.move_player(1, 0)

    expect(enemy.hp).to eq(50 - 8) # base 5 + weapon 3
  end

  it "buys equipment from the shop" do
    tiles = Array.new(25, "wall")
    (1..3).each do |x|
      (1..3).each do |y|
        tiles[y * 5 + x] = "floor"
      end
    end
    player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5, souls: 100)
    item = Rpg::Item.new(id: 99, kind: "armor", x: nil, y: nil, name: "Plate Armor", value: 50, stats: {"defense" => 3})
    world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [item], shop_stock: [item])
    world.compute_fov

    bought, message = world.buy_item(0)

    expect(bought).not_to be_nil
    expect(message).to include("You buy")
    expect(world.player.souls).to eq(50)
    expect(world.player.armor_id).to eq(99)
    expect(world.player_defense).to eq(3)
  end

  describe "sound cues" do
    it "cues :pickup when drinking a potion" do
      world = small_world
      world.player.x = 1
      world.player.y = 3
      world.pickup_item

      expect(world.sounds).to include(:pickup)
    end

    it "cues :buy when buying from the shop" do
      tiles = Array.new(25, "wall")
      (1..3).each do |x|
        (1..3).each { |y| tiles[y * 5 + x] = "floor" }
      end
      player = Rpg::Player.new(x: 1, y: 1, hp: 20, max_hp: 20, damage: 5, souls: 100)
      item = Rpg::Item.new(id: 99, kind: "armor", name: "Plate Armor", value: 50, stats: {"defense" => 3})
      world = described_class.new(width: 5, height: 5, tiles: tiles, player: player, entities: [], items: [], shop_stock: [item])

      world.buy_item(0)

      expect(world.sounds).to include(:buy)
    end

    it "cues :hit and :enemy_death when the player kills an enemy" do
      world = small_world
      4.times { world.move_player(1, 0) if world.state == "playing" }

      expect(world.alive_enemies).to be_empty
      expect(world.sounds).to include(:hit, :enemy_death)
    end

    it "cues :death when the player dies" do
      world = small_world
      world.player.hp = 0
      world.send(:check_game_over)

      expect(world.state).to eq("dead")
      expect(world.sounds).to include(:death)
    end

    it "cues :level_up when the player gains a level" do
      world = small_world
      world.player.souls = world.soul_cost_for_next_level
      world.level_up!

      expect(world.sounds).to include(:level_up)
    end

    it "does not serialize cues across save/load" do
      world = small_world
      world.cue(:pickup)
      reloaded = described_class.from_h(world.to_h)

      expect(reloaded.sounds).to eq([])
    end
  end
end
