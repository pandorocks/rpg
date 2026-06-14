# frozen_string_literal: true

module Rpg
  class Application < Charming::Application
    root File.expand_path("../..", __dir__)

    theme :phosphor, built_in: "phosphor"
    theme :dungeon, extends: :phosphor, overrides: {
      wall: {foreground: "#8B7355", bold: true},
      floor: {foreground: "#3a3a3a"},
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
