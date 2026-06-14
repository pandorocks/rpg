# frozen_string_literal: true

module Rpg
  class Application < Charming::Application
    root File.expand_path("../..", __dir__)

    # Collapse held-key auto-repeat into one move per frame so the character stops the instant
    # the key is released (no buffered-keystroke overshoot).
    coalesce_input true

    theme :phosphor, built_in: "phosphor"
    theme :dungeon, extends: :phosphor, overrides: {
      wall: {foreground: "#8B7355", bold: true},
      floor: {foreground: "#3a3a3a"},
      wall_cave: {foreground: "#6B5B45", bold: true},
      floor_cave: {foreground: "#4a4035"},
      wall_ice: {foreground: "#AADDFF", bold: true},
      floor_ice: {foreground: "#88BBDD"},
      wall_volcano: {foreground: "#FF4500", bold: true},
      floor_volcano: {foreground: "#8B0000"},
      wall_abyss: {foreground: "#6A0DAD", bold: true},
      floor_abyss: {foreground: "#2F4F4F"},
      player: {foreground: "#00FF00", bold: true},
      enemy: {foreground: "#FF4444", bold: true},
      item: {foreground: "#FFD700"},
      stairs: {foreground: "#AAAAAA", bold: true},
      blood: {foreground: "#AA0000"},
      log: {foreground: "#A0A0A0"},
      hud: {foreground: "#00FF00", bold: true}
    }

    default_theme :dungeon
  end
end
