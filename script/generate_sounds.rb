#!/usr/bin/env ruby
# frozen_string_literal: true

# Synthesizes the game's chiptune sound effects as 16-bit PCM mono WAV files under
# assets/sounds/. Pure Ruby — no gems, no external tools. Re-run to regenerate/tweak:
#
#   ruby script/generate_sounds.rb
#
# The resulting .wav files are committed so the game has sound without a build step.

require "fileutils"

SAMPLE_RATE = 22_050
AMPLITUDE = 0.32 # headroom so layered decays never clip

OUT_DIR = File.expand_path("../assets/sounds", __dir__)

# A single note: square or triangle wave at *freq* Hz for *dur* seconds, with a short
# attack and linear decay envelope to avoid clicks. Returns an array of float samples
# in [-1.0, 1.0]. freq: nil produces silence (a rest).
def note(freq, dur, wave: :square, gain: 1.0)
  count = (SAMPLE_RATE * dur).round
  attack = (SAMPLE_RATE * 0.005).round
  Array.new(count) do |i|
    env = (i < attack) ? i.to_f / attack : 1.0 - (i - attack).to_f / (count - attack)
    next 0.0 if freq.nil? || env <= 0

    phase = freq * i / SAMPLE_RATE.to_f
    sample = case wave
    when :triangle then 2.0 * (2.0 * (phase - (phase + 0.5).floor)).abs - 1.0
    else ((phase - phase.floor) < 0.5) ? 1.0 : -1.0 # square
    end
    sample * env * gain
  end
end

# Concatenates note arrays into one sample stream.
def sequence(*parts)
  parts.flatten(1)
end

def write_wav(name, samples)
  pcm = samples.map { |s| (s * AMPLITUDE * 32_767).round.clamp(-32_768, 32_767) }.pack("s<*")
  data_size = pcm.bytesize
  byte_rate = SAMPLE_RATE * 2 # mono, 16-bit

  header = +"RIFF"
  header << [36 + data_size].pack("V")
  header << "WAVE"
  header << "fmt "
  header << [16, 1, 1, SAMPLE_RATE, byte_rate, 2, 16].pack("VvvVVvv")
  header << "data"
  header << [data_size].pack("V")

  path = File.join(OUT_DIR, "#{name}.wav")
  File.binwrite(path, header + pcm)
  puts "wrote #{path} (#{data_size} bytes)"
end

# Note frequencies (Hz)
C5 = 523.25
E5 = 659.25
G5 = 783.99
A5 = 880.0
C6 = 1046.5
E6 = 1318.5

FileUtils.mkdir_p(OUT_DIR)

SOUNDS = {
  # Rising two-note blip — picking up / drinking an item.
  "pickup" => sequence(note(E5, 0.06), note(A5, 0.08)),

  # Bright shimmering double-ping — finding gold.
  "gold" => sequence(note(E6, 0.05, wave: :triangle), note(C6, 0.04, wave: :triangle), note(E6, 0.07, wave: :triangle)),

  # Short low thunk — equipping gear.
  "equip" => sequence(note(220, 0.06), note(330, 0.07)),

  # Ascending arpeggio — leveling up.
  "level_up" => sequence(note(C5, 0.08), note(E5, 0.08), note(G5, 0.08), note(C6, 0.14)),

  # Short low square — landing a hit.
  "hit" => sequence(note(150, 0.05), note(110, 0.05)),

  # Quick downward blip — killing an enemy.
  "enemy_death" => sequence(note(440, 0.05), note(294, 0.05), note(196, 0.07)),

  # Cash-register two-note — buying in the shop.
  "buy" => sequence(note(987.77, 0.06, wave: :triangle), note(nil, 0.02), note(E6, 0.1, wave: :triangle)),

  # Low descending sweep — descending the stairs.
  "descend" => sequence(note(330, 0.07), note(294, 0.07), note(262, 0.07), note(196, 0.12)),

  # Slow descending minor sting — death.
  "death" => sequence(note(330, 0.16), note(262, 0.16), note(196, 0.18), note(131, 0.4))
}.freeze

SOUNDS.each { |name, samples| write_wav(name, samples) }
puts "done — #{SOUNDS.size} sounds in #{OUT_DIR}"
