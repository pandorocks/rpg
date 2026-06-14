# frozen_string_literal: true

module Rpg
  class Entity
    attr_accessor :id, :kind, :x, :y, :hp, :max_hp, :damage, :dead

    def initialize(id:, kind:, x:, y:, hp:, max_hp:, damage:, dead: false)
      @id = id
      @kind = kind
      @x = x
      @y = y
      @hp = hp
      @max_hp = max_hp
      @damage = damage
      @dead = dead
    end

    def to_h
      {id: @id, kind: @kind, x: @x, y: @y, hp: @hp, max_hp: @max_hp, damage: @damage, dead: @dead}
    end

    def self.from_h(hash)
      new(**hash.transform_keys(&:to_sym))
    end

    def dead?
      @dead
    end

    def alive?
      !@dead
    end

    def name
      @kind.capitalize
    end
  end
end
