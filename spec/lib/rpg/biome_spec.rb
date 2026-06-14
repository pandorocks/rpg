# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::Biome do
  it "assigns biomes by depth range" do
    expect(described_class.for_depth(1)).to eq(:dungeon)
    expect(described_class.for_depth(2)).to eq(:dungeon)
    expect(described_class.for_depth(3)).to eq(:cave)
    expect(described_class.for_depth(6)).to eq(:ice)
    expect(described_class.for_depth(8)).to eq(:volcano)
    expect(described_class.for_depth(9)).to eq(:abyss)
    expect(described_class.for_depth(20)).to eq(:abyss)
  end

  it "resolves biome names from strings or symbols" do
    expect(described_class.name("cave")).to eq("Cave")
    expect(described_class.name(:ice)).to eq("Ice Cavern")
    expect(described_class.name(nil)).to eq("Dungeon")
    expect(described_class.name("unknown")).to eq("Dungeon")
  end

  it "returns distinct glyphs per biome" do
    expect(described_class.wall_glyph(:dungeon)).to eq("🧱")
    expect(described_class.wall_glyph(:cave)).to eq("🪨")
    expect(described_class.wall_glyph(:ice)).to eq("🧊")
    expect(described_class.floor_glyph(:volcano)).not_to eq(described_class.floor_glyph(:abyss))
  end

  it "resolves a tile style for every biome" do
    theme = Rpg::Application.theme_for(:dungeon)

    %i[dungeon cave ice volcano abyss].each do |biome|
      expect(described_class.tile_style("wall", biome, theme)).to be_a(Charming::UI::Style)
      expect(described_class.tile_style("floor", biome, theme)).to be_a(Charming::UI::Style)
    end
  end

  it "provides room dimensions within the dungeon bounds" do
    rng = Random.new(1)
    w, h = described_class.room_dimensions(:cave, rng)

    expect(w).to be >= 5
    expect(w).to be <= 12
    expect(h).to be >= 4
    expect(h).to be <= 7
  end

  it "returns enemy tables that sum to one per biome" do
    %i[dungeon cave ice volcano abyss].each do |biome|
      table = described_class.enemy_weights(biome, 1)
      expect(table.values.sum).to be_within(0.001).of(1.0)
    end
  end

  it "increases dragon weight on deeper floors" do
    shallow = described_class.enemy_weights(:dungeon, 1)
    deep = described_class.enemy_weights(:dungeon, 6)

    expect(deep[:dragon]).to be > shallow[:dragon]
  end

  it "preserves biome flavor when scaling depth" do
    abyss_shallow = described_class.enemy_weights(:abyss, 3)
    abyss_deep = described_class.enemy_weights(:abyss, 9)

    expect(abyss_deep[:dragon]).to be >= abyss_shallow[:dragon]
    expect(abyss_deep[:ghost]).to be_positive
  end

  it "spawns enemies using biome-specific weights" do
    rng = Random.new(42)
    kinds = 100.times.map { described_class.random_enemy_kind(:volcano, 8, rng) }

    expect(kinds.uniq).to include("dragon")
  end
end
