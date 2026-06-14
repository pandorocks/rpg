# frozen_string_literal: true

module Rpg
  class InventoryState < Charming::ApplicationState
    attribute :selected_index, :integer, default: 0
  end
end
