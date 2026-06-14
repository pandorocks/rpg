# frozen_string_literal: true

module Rpg
  class GameBalance
    EMOJIS = [
      {emoji: "🧙", name: "Wizard"},
      {emoji: "🥷", name: "Ninja"},
      {emoji: "🦸", name: "Superhero"},
      {emoji: "🐱", name: "Cat"}
    ].freeze

    DIFFICULTIES = [
      {name: "Easy", player_hp: 1.5, player_damage: 1.5, xp_gain: 1.5, enemy_hp: 0.7, enemy_damage: 0.5},
      {name: "Normal", player_hp: 1.0, player_damage: 1.0, xp_gain: 1.0, enemy_hp: 1.0, enemy_damage: 1.0},
      {name: "Hard", player_hp: 0.7, player_damage: 0.7, xp_gain: 0.7, enemy_hp: 1.5, enemy_damage: 1.5}
    ].freeze

    def self.emoji_options
      EMOJIS
    end

    def self.difficulty_options
      DIFFICULTIES
    end

    def self.emoji_for(index)
      EMOJIS[index.to_i].fetch(:emoji)
    end

    def self.difficulty_for(index)
      DIFFICULTIES[index.to_i]
    end

    def self.apply_player_hp(base, difficulty_name)
      (base * multiplier_for(difficulty_name, :player_hp)).to_i
    end

    def self.apply_player_damage(base, difficulty_name)
      (base * multiplier_for(difficulty_name, :player_damage)).to_i
    end

    def self.apply_enemy_hp(base, difficulty_name)
      (base * multiplier_for(difficulty_name, :enemy_hp)).to_i
    end

    def self.apply_enemy_damage(base, difficulty_name)
      (base * multiplier_for(difficulty_name, :enemy_damage)).to_i
    end

    def self.apply_xp(base, difficulty_name)
      (base * multiplier_for(difficulty_name, :xp_gain)).to_i
    end

    def self.multiplier_for(difficulty_name, key)
      option = DIFFICULTIES.find { |d| d[:name] == difficulty_name }
      option ? option.fetch(key) : 1.0
    end
  end
end
