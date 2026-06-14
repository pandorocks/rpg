# frozen_string_literal: true

module Rpg
  class Item
    attr_accessor :id, :kind, :x, :y

    def initialize(id:, kind:, x:, y:)
      @id = id
      @kind = kind
      @x = x
      @y = y
    end

    def to_h
      {id: @id, kind: @kind, x: @x, y: @y}
    end

    def self.from_h(hash)
      new(**hash.transform_keys(&:to_sym))
    end
  end
end
