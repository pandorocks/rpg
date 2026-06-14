# frozen_string_literal: true

module Rpg
  class SetupState < Charming::ApplicationState
    attribute :emoji_index, :integer, default: 0
    attribute :difficulty_index, :integer, default: 1
    # false → respawn (soulslike) loop; true → permadeath + high-score "hardcore" mode.
    attribute :hardcore, :boolean, default: false
  end
end
