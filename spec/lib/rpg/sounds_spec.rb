# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::Sounds do
  describe ".select" do
    it "returns the highest-priority cue when several are present" do
      expect(described_class.select(%i[hit death pickup])).to eq(:death)
    end

    it "prefers level_up over enemy_death and hit" do
      expect(described_class.select(%i[hit enemy_death level_up])).to eq(:level_up)
    end

    it "returns the only cue present" do
      expect(described_class.select([:pickup])).to eq(:pickup)
    end

    it "returns nil when there are no cues" do
      expect(described_class.select([])).to be_nil
    end
  end

  describe ".path_for" do
    it "resolves the winning cue to its wav file" do
      expect(described_class.path_for(%i[hit pickup])).to eq(described_class::FILES[:pickup])
    end

    it "returns nil when there are no cues" do
      expect(described_class.path_for([])).to be_nil
    end
  end

  it "ships a wav file for every cue in the priority list" do
    described_class::PRIORITY.each do |cue|
      path = described_class::FILES.fetch(cue)
      expect(File.exist?(path)).to be(true), "missing sound file for #{cue}: #{path}"
    end
  end
end
