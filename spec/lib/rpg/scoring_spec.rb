# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::Scoring do
  def world_with(**overrides)
    player_attrs = {x: 1, y: 1, hp: 20, max_hp: 20, xp: 0, level: 1, damage: 5, gold: 0}
    player = Rpg::Player.new(player_attrs.merge(overrides.slice(:level, :gold)))
    world_attrs = {width: 5, height: 5, tiles: Array.new(25, "floor"), player: player, entities: [], items: [], difficulty: "Normal"}
    Rpg::World.new(world_attrs.merge(overrides.slice(:depth, :kills, :difficulty)))
  end

  it "calculates a base score" do
    world = world_with(gold: 10, kills: 3, depth: 2, level: 2)
    score = described_class.score_for(world)

    expect(score[:breakdown][:gold]).to eq(20)
    expect(score[:breakdown][:kills]).to eq(30)
    expect(score[:breakdown][:depth]).to eq(100)
    expect(score[:breakdown][:level]).to eq(25)
    expect(score[:raw]).to eq(175)
    expect(score[:total]).to eq(175)
  end

  it "applies difficulty multipliers" do
    easy = described_class.score_for(world_with(difficulty: "Easy"))
    normal = described_class.score_for(world_with(difficulty: "Normal"))
    hard = described_class.score_for(world_with(difficulty: "Hard"))

    expect(easy[:multiplier]).to eq(0.8)
    expect(normal[:multiplier]).to eq(1.0)
    expect(hard[:multiplier]).to eq(1.2)
    expect(hard[:total]).to be > normal[:total]
    expect(easy[:total]).to be < normal[:total]
  end
end
