# frozen_string_literal: true

module Rpg
  # Maps gameplay sound cues (recorded on World via World#cue) to the WAV files under
  # assets/sounds, and decides which single cue to play when several land on one turn.
  # The audio player is monophonic, so only the highest-priority cue per action is heard.
  module Sounds
    DIR = File.expand_path("../../assets/sounds", __dir__)

    FILES = {
      death: File.join(DIR, "death.wav"),
      level_up: File.join(DIR, "level_up.wav"),
      enemy_death: File.join(DIR, "enemy_death.wav"),
      buy: File.join(DIR, "buy.wav"),
      descend: File.join(DIR, "descend.wav"),
      pickup: File.join(DIR, "pickup.wav"),
      gold: File.join(DIR, "gold.wav"),
      equip: File.join(DIR, "equip.wav"),
      hit: File.join(DIR, "hit.wav")
    }.freeze

    # Most salient first. The winning cue for a turn is the earliest one in this list.
    PRIORITY = %i[death level_up enemy_death buy descend pickup gold equip hit].freeze

    # Returns the highest-priority cue present in *cues* (or nil when none). Pure, no I/O.
    def self.select(cues)
      PRIORITY.find { |cue| cues.include?(cue) }
    end

    # Returns the resolved WAV path for the winning cue in *cues*, or nil when there is none.
    def self.path_for(cues)
      cue = select(cues)
      cue && FILES[cue]
    end
  end
end
