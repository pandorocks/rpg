# frozen_string_literal: true

module Rpg
  class Player
    attr_accessor :x, :y, :hp, :max_hp, :xp, :level, :damage

    def initialize(x:, y:, hp:, max_hp:, damage:, xp: 0, level: 1)
      @x = x
      @y = y
      @hp = hp
      @max_hp = max_hp
      @xp = xp
      @level = level
      @damage = damage
    end

    def to_h
      {x: @x, y: @y, hp: @hp, max_hp: @max_hp, xp: @xp, level: @level, damage: @damage}
    end

    def self.from_h(hash)
      new(**hash.transform_keys(&:to_sym))
    end

    def alive?
      @hp > 0
    end

    def name
      "you"
    end
  end
end
