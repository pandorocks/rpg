# frozen_string_literal: true

module Rpg
  class Fov
    def self.compute(world, radius: 8)
      visible = Set.new
      px = world.player.x
      py = world.player.y
      visible << [px, py]

      y_min = [py - radius, 0].max
      y_max = [py + radius, world.height - 1].min
      x_min = [px - radius, 0].max
      x_max = [px + radius, world.width - 1].min

      (y_min..y_max).each do |y|
        (x_min..x_max).each do |x|
          next if x == px && y == py
          next unless distance(px, py, x, y) <= radius

          bresenham(px, py, x, y).each do |lx, ly|
            visible << [lx, ly]
            break if world.solid?(lx, ly)
          end
        end
      end

      visible
    end

    def self.distance(x1, y1, x2, y2)
      Math.sqrt(((x2 - x1)**2) + ((y2 - y1)**2))
    end

    # Returns every grid coordinate on the line from (x0, y0) to (x1, y1), inclusive.
    def self.bresenham(x0, y0, x1, y1)
      points = []
      dx = (x1 - x0).abs
      dy = (y1 - y0).abs
      sx = (x0 < x1) ? 1 : -1
      sy = (y0 < y1) ? 1 : -1
      err = dx - dy

      loop do
        points << [x0, y0]
        break if x0 == x1 && y0 == y1

        e2 = 2 * err
        if e2 > -dy
          err -= dy
          x0 += sx
        end
        if e2 < dx
          err += dx
          y0 += sy
        end
      end

      points
    end
  end
end
