# frozen_string_literal: true

require "active_model"

module Rpg
  class Item
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :integer
    attribute :kind, :string
    attribute :x, :integer
    attribute :y, :integer

    def to_h
      attributes.symbolize_keys
    end

    def self.from_h(hash)
      new(hash.transform_keys(&:to_sym))
    end
  end
end
