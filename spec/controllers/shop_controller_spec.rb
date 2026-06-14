# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::ShopController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/shop") }

  it "renders the shop" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("Merchant")
    expect(response).to render_text("Souls:")
  end

  it "restocks the shop when empty" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    ctrl.dispatch(:show)

    expect(app.session[:states][:dungeon].world.shop_stock).not_to be_empty
  end

  it "buys an affordable item" do
    build_controller(described_class, app: app, screen: screen, route: route).dispatch(:show)
    state = app.session[:states][:dungeon]
    world = state.world
    world.player.souls = 1000
    state.world = world

    response = press(described_class, "1", app: app, screen: screen, route: route)

    expect(response).to render_text("You buy")
  end

  it "refuses to sell an unaffordable item" do
    build_controller(described_class, app: app, screen: screen, route: route).dispatch(:show)
    state = app.session[:states][:dungeon]
    world = state.world
    world.player.souls = 0
    state.world = world

    response = press(described_class, "1", app: app, screen: screen, route: route)

    expect(response).to render_text("cannot afford")
  end

  it "returns to the dungeon on esc" do
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end
end
