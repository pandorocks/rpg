# frozen_string_literal: true

module Rpg
  class Combat
    def self.attack(attacker, target, world)
      damage = damage_for(attacker, world)
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} hit #{target.name} for #{damage} damage.")

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")

      gain_xp(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.shoot(attacker, target, world)
      damage = damage_for(attacker, world)
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} shoot #{target.name} for #{damage} damage.")

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")

      gain_xp(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.damage_for(attacker, world)
      base = attacker.damage
      return base unless attacker.is_a?(Player) && attacker.strength_turns.to_i > 0

      base + 3
    end

    def self.gain_xp(player, target, world)
      base_xp = {
        dragon: 100,
        troll: 50,
        robot: 45,
        ghost: 40,
        orc: 30,
        goblin: 20,
        zombie: 25
      }.fetch(target.kind.to_sym, 10)
      xp = GameBalance.apply_xp(base_xp, world.difficulty)
      player.xp += xp
      world.kills += 1
      world.add_message("You gain #{xp} XP.")
      world.check_level_up
    end
  end
end
