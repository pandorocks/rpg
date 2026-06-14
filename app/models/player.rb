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
    attribute :xp, :integer, default: 0
    attribute :level, :integer, default: 1
    attribute :damage, :integer
    attribute :vision_turns, :integer, default: 0
    attribute :strength_turns, :integer, default: 0

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
