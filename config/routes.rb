# frozen_string_literal: true

Rpg::Application.routes do
  root "dungeon#show", title: "Dungeon"
  screen "/setup", to: "setup#show", title: "Setup"
  screen "/inventory", to: "inventory#show", title: "Inventory"
  screen "/character", to: "character#show", title: "Character"
  screen "/game_over", to: "game_over#show", title: "Game Over"
end
