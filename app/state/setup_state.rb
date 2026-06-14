# frozen_string_literal: true

module Rpg
  class SetupState < Charming::ApplicationState
    attribute :emoji_index, :integer, default: 0
    attribute :difficulty_index, :integer, default: 1
  end
end
