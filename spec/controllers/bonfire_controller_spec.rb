# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::BonfireController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/bonfire") }

  it "renders the bonfire menu" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("Bonfire")
    expect(response).to render_text("Souls:")
  end

  it "levels up when the player can afford it" do
    build_controller(described_class, app: app, screen: screen, route: route).dispatch(:show)
    state = app.session[:states][:dungeon]
    world = state.world
    world.player.souls = 1000
    state.world = world

    press(described_class, "l", app: app, screen: screen, route: route)

    expect(app.session[:states][:dungeon].world.player.level).to eq(2)
  end

  it "returns to the dungeon on esc" do
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end
end
