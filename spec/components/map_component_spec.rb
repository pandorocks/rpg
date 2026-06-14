# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::MapComponent do
  let(:theme) { Rpg::Application.theme_for(:dungeon) }

  def component_for(world)
    described_class.new(world: world, width: 80, height: 20, theme: theme)
  end

  it "renders the player glyph" do
    world = Rpg::World.new_game(seed: 1)
    body = component_for(world).render

    expect(body).to include(Rpg::MapComponent::DEFAULT_PLAYER_GLYPH)
  end

  it "can render a custom player glyph" do
    world = Rpg::World.new_game(seed: 1)
    component = described_class.new(world: world, width: 80, height: 20, theme: theme, player_glyph: "@")
    body = Charming::UI::Width.strip_ansi(component.render)

    expect(body).to include("@")
  end

  it "renders walls and floors differently" do
    world = Rpg::World.new_game(seed: 1)
    body = Charming::UI::Width.strip_ansi(component_for(world).render)

    expect(body).to include("#")
    expect(body).to include(".")
  end

  it "hides unexplored tiles" do
    world = Rpg::World.new_game(seed: 1)
    body = Charming::UI::Width.strip_ansi(component_for(world).render)

    expect(body).to include(" ")
  end
end
