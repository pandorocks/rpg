# frozen_string_literal: true

module Rpg
  class Combat
    def self.attack(attacker, target, world)
      damage = attacker.damage
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} hit #{target.name} for #{damage} damage.")

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")

      gain_xp(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.shoot(attacker, target, world)
      damage = attacker.damage
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} shoot #{target.name} for #{damage} damage.")

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")

      gain_xp(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.gain_xp(player, target, world)
      xp = {troll: 50, orc: 30, goblin: 20}.fetch(target.kind.to_sym, 10)
      player.xp += xp
      world.add_message("You gain #{xp} XP.")
    end
  end
end
