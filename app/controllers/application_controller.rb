# frozen_string_literal: true

module Rpg
  class ApplicationController < Charming::Controller
    layout false

    key "ctrl+p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global
    key "?", :toggle_help, scope: :global

    command "New game" do
      state(:dungeon, DungeonState).new_game
      navigate_to "/"
    end

    command "Quit" do
      quit
    end

    def toggle_help
      session[:help_open] = !session[:help_open]
      render_default_action
    end
  end
end
