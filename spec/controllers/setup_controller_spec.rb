# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::SetupController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/setup") }

  it "renders the setup screen" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("Create your hero")
    expect(response).to render_text("Wizard")
    expect(response).to render_text("Normal")
  end

  it "navigates through emojis" do
    press(described_class, "down", app: app, screen: screen, route: route)
    response = press(described_class, "down", app: app, screen: screen, route: route)

    expect(response).to render_text("Superhero")
  end

  it "navigates through difficulties" do
    press(described_class, "left", app: app, screen: screen, route: route)
    response = press(described_class, "left", app: app, screen: screen, route: route)

    expect(response).to render_text("Easy")
  end

  it "starts a new game on enter" do
    response = press(described_class, "enter", app: app, screen: screen, route: route)

    expect(response).to be_navigate
    expect(app.session[:states][:dungeon].world).not_to be_nil
    expect(app.session[:states][:dungeon].world.state).to eq("playing")
  end

  it "quits on esc when no world exists" do
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_quit
  end

  it "returns to dungeon on esc when a world exists" do
    app.session[:states] = {dungeon: Rpg::DungeonState.new}
    app.session[:states][:dungeon].new_game
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end
end
