# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::GameBalance do
  it "has emoji options" do
    expect(described_class.emoji_options).not_to be_empty
    expect(described_class.emoji_for(0)).to eq("🧙")
  end

  it "has difficulty options" do
    expect(described_class.difficulty_options.map { |d| d[:name] }).to contain_exactly("Easy", "Normal", "Hard")
  end

  it "applies easy buffs to players" do
    expect(described_class.apply_player_hp(30, "Easy")).to be > 30
    expect(described_class.apply_player_damage(5, "Easy")).to be > 5
  end

  it "applies easy nerfs to enemies" do
    expect(described_class.apply_enemy_hp(8, "Easy")).to be < 8
    expect(described_class.apply_enemy_damage(2, "Easy")).to be < 2
  end

  it "applies hard nerfs to players" do
    expect(described_class.apply_player_hp(30, "Hard")).to be < 30
    expect(described_class.apply_player_damage(5, "Hard")).to be < 5
  end

  it "applies hard buffs to enemies" do
    expect(described_class.apply_enemy_hp(8, "Hard")).to be > 8
    expect(described_class.apply_enemy_damage(2, "Hard")).to be > 2
  end

  it "multiplies xp by difficulty" do
    expect(described_class.apply_xp(20, "Easy")).to be > 20
    expect(described_class.apply_xp(20, "Hard")).to be < 20
  end

  it "leaves normal stats unchanged" do
    expect(described_class.apply_player_hp(30, "Normal")).to eq(30)
    expect(described_class.apply_enemy_damage(2, "Normal")).to eq(2)
    expect(described_class.apply_xp(20, "Normal")).to eq(20)
  end
end
