# frozen_string_literal: true

module Rpg
  class Combat
    def self.attack(attacker, target, world)
      damage = damage_for(attacker, world)
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} hit #{target.name} for #{damage} damage.")
      world.cue(:hit)

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")
      world.cue(:enemy_death) if attacker.is_a?(Player)

      gain_souls(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.shoot(attacker, target, world)
      damage = damage_for(attacker, world)
      target.hp -= damage
      world.add_message("#{attacker.name.capitalize} shoot #{target.name} for #{damage} damage.")
      world.cue(:hit)

      return unless target.hp <= 0

      target.hp = 0
      target.dead = true if target.respond_to?(:dead=)
      world.add_message("#{target.name} dies!")
      world.cue(:enemy_death) if attacker.is_a?(Player)

      gain_souls(attacker, target, world) if attacker.is_a?(Player)
    end

    def self.damage_for(attacker, world)
      base = if attacker.is_a?(Player)
        Equipment.player_damage(attacker, world.inventory) + strength_bonus(attacker)
      else
        attacker.damage
      end
      return base unless attacker.is_a?(Entity) && target_is?(attacker, world.player)

      defense = Equipment.player_defense(world.player, world.inventory)
      [base - defense, 1].max
    end

    def self.strength_bonus(player)
      (player.strength_turns.to_i > 0) ? 3 : 0
    end

    def self.target_is?(attacker, target)
      target.is_a?(Player)
    end

    # Souls are the single currency (merged XP + gold): earned from kills, spent at bonfires to
    # level up and at shops to buy. The award is the enemy's intrinsic soul value plus its bounty.
    def self.gain_souls(player, target, world)
      base = {
        dragon: 100,
        troll: 50,
        robot: 45,
        ghost: 40,
        orc: 30,
        goblin: 20,
        zombie: 25
      }.fetch(target.kind.to_sym, 10)
      souls = GameBalance.apply_xp(base, world.difficulty) + target.gold.to_i
      player.souls += souls
      world.kills += 1
      world.add_message("You absorb #{souls} souls.")
    end
  end
end
