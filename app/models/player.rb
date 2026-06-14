# frozen_string_literal: true

require "active_model"

module Rpg
  class Player
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :x, :integer
    attribute :y, :integer
    attribute :hp, :integer
    attribute :max_hp, :integer
    attribute :souls, :integer, default: 0
    attribute :level, :integer, default: 1
    attribute :damage, :integer
    attribute :defense, :integer, default: 0
    attribute :vision_turns, :integer, default: 0
    attribute :strength_turns, :integer, default: 0
    attribute :weapon_id, :integer
    attribute :armor_id, :integer
    attribute :ring_id, :integer
    # Estus: limited healing charges, refilled only by resting at a bonfire.
    attribute :estus_charges, :integer, default: 3
    attribute :max_estus_charges, :integer, default: 3
    # Respawn anchor: the bonfire the player wakes at after dying (set by resting).
    attribute :respawn_depth, :integer, default: 1
    attribute :respawn_x, :integer
    attribute :respawn_y, :integer

    def alive?
      hp > 0
    end

    def name
      "you"
    end

    def to_h
      attributes.symbolize_keys
    end

    def self.from_h(hash)
      new(hash.transform_keys(&:to_sym))
    end
  end
end
