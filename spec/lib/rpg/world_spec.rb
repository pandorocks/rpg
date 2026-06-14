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

  it "kills enemies and awards XP" do
    world = small_world
    4.times { world.move_player(1, 0) if world.state == "playing" }

    expect(world.alive_enemies).to be_empty
    expect(world.player.xp).to be_positive
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
end
