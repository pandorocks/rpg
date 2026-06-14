# frozen_string_literal: true

module Rpg
  class Ai
    def self.take_turn(entity, world)
      return if entity.dead?
      return unless can_see?(entity, world.player, world)

      if adjacent?(entity, world.player)
        Combat.attack(entity, world.player, world)
      else
        dx = (world.player.x - entity.x).clamp(-1, 1)
        dy = (world.player.y - entity.y).clamp(-1, 1)
        moved = world.move_entity(entity, dx, dy)
        unless moved
          moved = world.move_entity(entity, dx, 0) unless dx.zero?
          world.move_entity(entity, 0, dy) unless moved || dy.zero?
        end
      end
    end

    def self.can_see?(entity, target, world, radius: 8)
      return false unless distance(entity.x, entity.y, target.x, target.y) <= radius

      Fov.bresenham(entity.x, entity.y, target.x, target.y).all? { |x, y| !world.solid?(x, y) }
    end

    def self.adjacent?(a, b)
      (a.x - b.x).abs <= 1 && (a.y - b.y).abs <= 1 && !(a.x == b.x && a.y == b.y)
    end

    def self.distance(x1, y1, x2, y2)
      Math.sqrt(((x2 - x1)**2) + ((y2 - y1)**2))
    end
  end
end
