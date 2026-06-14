# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rpg::InventoryController do
  let(:app) { Rpg::Application.new }
  let(:screen) { Charming::Screen.new(width: 80, height: 24) }
  let(:route) { Rpg::Application.routes.resolve("/inventory") }

  it "renders the inventory screen" do
    ctrl = build_controller(described_class, app: app, screen: screen, route: route)
    response = ctrl.dispatch(:show)

    expect(response).to render_text("Inventory")
  end

  it "returns to the dungeon on esc" do
    response = press(described_class, "esc", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end

  it "returns to the dungeon on i" do
    response = press(described_class, "i", app: app, screen: screen, route: route)

    expect(response).to be_navigate
  end
end
