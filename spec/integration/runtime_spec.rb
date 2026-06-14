# frozen_string_literal: true

require "spec_helper"

RSpec.describe "RPG runtime" do
  it "boots, renders, handles movement, help, and quits" do
    backend = memory_backend("l", "k", "?", "q", width: 80, height: 24)
    runtime = Charming::Runtime.new(Rpg::Application.new, backend: backend)

    expect { runtime.run }.not_to raise_error

    expect(backend.frames.size).to be >= 4
    help_frame = Charming::UI::Width.strip_ansi(backend.frames[3].to_s)
    expect(help_frame).to include("Controls:")
    expect(help_frame).to include("n : new game / setup")
  end
end
