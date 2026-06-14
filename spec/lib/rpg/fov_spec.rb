# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::Fov do
  def corridor_with_pillar
    tiles = Array.new(35, "wall")
    (1..5).each { |x| tiles[2 * 7 + x] = "floor" }
    tiles[2 * 7 + 3] = "wall" # pillar blocking the corridor
    player = Rpg::Player.new(x: 1, y: 2, hp: 10, max_hp: 10, damage: 3)
    Rpg::World.new(width: 7, height: 5, tiles: tiles, player: player, entities: [], items: [])
  end

  it "sees the player tile" do
    world = corridor_with_pillar
    visible = described_class.compute(world, radius: 4)

    expect(visible).to include([1, 2])
  end

  it "sees nearby floor tiles" do
    world = corridor_with_pillar
    visible = described_class.compute(world, radius: 4)

    expect(visible).to include([2, 2], [3, 2])
  end

  it "does not see through walls" do
    world = corridor_with_pillar
    visible = described_class.compute(world, radius: 4)

    expect(visible).not_to include([4, 2], [5, 2], [6, 2])
  end

  it "sees the wall tile that blocks sight" do
    world = corridor_with_pillar
    visible = described_class.compute(world, radius: 4)

    expect(visible).to include([3, 2])
  end

  it "respects a limited radius" do
    world = corridor_with_pillar
    visible = described_class.compute(world, radius: 1)

    expect(visible).to include([1, 2], [2, 2])
    expect(visible).not_to include([3, 2])
  end
end
