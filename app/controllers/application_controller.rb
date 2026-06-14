# frozen_string_literal: true

module Rpg
  class ApplicationController < Charming::Controller
    layout false

    key "ctrl+p", :open_command_palette, scope: :global
    key "q", :quit, scope: :global
    key "?", :toggle_help, scope: :global

    command "New game" do
      navigate_to "/setup"
    end

    command "Inventory" do
      navigate_to "/inventory"
    end

    command "Character" do
      navigate_to "/character"
    end

    command "Quit" do
      quit
    end

    def toggle_help
      session[:help_open] = !session[:help_open]
      render_default_action
    end

    private

    # The session-held audio player. Kept in session (not rebuilt per render) because it
    # owns a live child process.
    def audio_player
      session[:audio] ||= Charming::Audio::Player.new
    end

    # Plays the single most salient sound cued on *world* during this action, if any.
    # Fire-and-forget via run_task so playback never blocks the event loop and the child
    # is reaped on shutdown. No-ops in tests and when no audio backend is installed.
    def play_sounds(world)
      return if test?

      path = Sounds.path_for(world.sounds)
      return unless path && File.exist?(path)

      player = audio_player
      return unless player.available?

      run_task(:audio) do
        player.play(path)
        player.wait
      ensure
        player.stop
      end
    end

    def test?
      defined?(RSpec)
    end
  end
end
