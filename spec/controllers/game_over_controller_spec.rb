# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::GameOverController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/game_over") }

  before do
    # Set up a dead world for the game over screen.
    state = app.session[:states] ||= {}
    state[:dungeon] = Rpg::DungeonState.new
    state[:dungeon].new_game
    world = state[:dungeon].world
    world.player.hp = 0
    world.state = "dead"
    state[:dungeon].world = world
  end

  it "renders the game over screen" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("You died!")
    expect(response).to render_text("Kills:")
  end

  it "navigates to setup on n" do
    response = press(described_class, "n", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end

  it "quits on q" do
    response = press(described_class, "q", app: app, screen: screen, route: route)

    expect(response).to be_quit
  end

  it "returns to the dungeon on esc" do
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end
end
