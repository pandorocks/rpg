# frozen_string_literal: true

require "active_model"

module Rpg
  class Entity
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :integer
    attribute :kind, :string
    attribute :x, :integer
    attribute :y, :integer
    attribute :hp, :integer
    attribute :max_hp, :integer
    attribute :damage, :integer
    attribute :dead, :boolean, default: false
    attribute :gold, :integer, default: 0

    def alive?
      !dead
    end

    def dead?
      dead
    end

    def name
      kind.capitalize
    end

    def to_h
      attributes.symbolize_keys
    end

    def self.from_h(hash)
      new(hash.transform_keys(&:to_sym))
    end
  end
end
