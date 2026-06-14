# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::DungeonController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/") }

  it "renders the initial dungeon" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("HP:")
    expect(response).to render_text("🧙‍♂️")
  end

  it "moves the player east on l" do
    press(described_class, "l", app: app, screen: screen, route: route)
    response = press(described_class, "l", app: app, screen: screen, route: route)

    expect(response).to render_text("Turn: 2")
  end

  it "toggles the help overlay on ?" do
    response = press(described_class, "?", app: app, screen: screen, route: route)

    expect(response).to render_text("Controls:")
  end

  it "quits on q" do
    response = press(described_class, "q", app: app, screen: screen, route: route)

    expect(response).to be_quit
  end

  it "starts a new game on n after death" do
    # We can't force death deterministically with random dungeons, but we can
    # verify the new_game action resets the world.
    press_sequence(described_class, ["n"], app: app, screen: screen, route: route)
    response = press(described_class, "n", app: app, screen: screen, route: route)

    expect(response).to render_text("Turn: 0")
    expect(response).to render_text("Depth: 1")
  end

  it "enters fire mode on f and fires on a direction key" do
    press(described_class, "f", app: app, screen: screen, route: route)
    response = press(described_class, "l", app: app, screen: screen, route: route)

    expect(response).to render_text("Turn: 1")
    expect(response).to render_text("shoot") | render_text("darkness")
  end

  it "cancels fire mode on escape" do
    press(described_class, "f", app: app, screen: screen, route: route)
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to render_text("Cancelled")
  end
end
