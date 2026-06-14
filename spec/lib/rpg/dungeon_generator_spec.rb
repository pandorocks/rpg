# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::DungeonGenerator do
  it "generates a playable dungeon" do
    world = described_class.generate(width: 40, height: 16, depth: 1, seed: 42)

    expect(world.width).to eq(40)
    expect(world.height).to eq(16)
    expect(world.player.hp).to be_positive
    expect(world.tile_at(world.player.x, world.player.y)).to eq("floor")
    expect(world.alive_enemies).not_to be_empty
    expect(world.items).not_to be_empty
  end

  it "places stairs on a floor tile in a different room than the player" do
    world = described_class.generate(width: 60, height: 20, depth: 1, seed: 7)
    sx, sy = find_stairs(world)

    expect(sx).not_to be_nil
    expect(world.tile_at(sx, sy)).to eq("stairs")
    expect([sx, sy]).not_to eq([world.player.x, world.player.y])
  end

  it "does not place entities inside walls" do
    world = described_class.generate(width: 60, height: 20, depth: 1, seed: 99)

    world.alive_enemies.each do |enemy|
      expect(world.tile_at(enemy.x, enemy.y)).to eq("floor")
      expect([enemy.x, enemy.y]).not_to eq([world.player.x, world.player.y])
    end
  end

  it "does not place items inside walls" do
    world = described_class.generate(width: 60, height: 20, depth: 1, seed: 99)

    world.items.each do |item|
      expect(world.tile_at(item.x, item.y)).to eq("floor")
    end
  end

  it "produces deeper dungeons" do
    shallow = described_class.generate(width: 60, height: 20, depth: 1, seed: 5)
    deep = described_class.generate(width: 60, height: 20, depth: 5, seed: 5)

    expect(deep.depth).to be > shallow.depth
    expect(deep.alive_enemies.size).to be >= shallow.alive_enemies.size
  end

  it "applies easy difficulty modifiers" do
    easy = described_class.generate(width: 60, height: 20, depth: 1, seed: 1, difficulty: "Easy")
    normal = described_class.generate(width: 60, height: 20, depth: 1, seed: 1, difficulty: "Normal")

    expect(easy.player.max_hp).to be > normal.player.max_hp
    expect(easy.player.damage).to be > normal.player.damage
    expect(easy.alive_enemies.first.max_hp).to be < normal.alive_enemies.first.max_hp
  end

  it "applies hard difficulty modifiers" do
    hard = described_class.generate(width: 60, height: 20, depth: 1, seed: 1, difficulty: "Hard")
    normal = described_class.generate(width: 60, height: 20, depth: 1, seed: 1, difficulty: "Normal")

    expect(hard.player.max_hp).to be < normal.player.max_hp
    expect(hard.player.damage).to be < normal.player.damage
    expect(hard.alive_enemies.first.max_hp).to be > normal.alive_enemies.first.max_hp
  end

  def find_stairs(world)
    world.width.times do |x|
      world.height.times do |y|
        return [x, y] if world.tile_at(x, y) == "stairs"
      end
    end
    [nil, nil]
  end
end
