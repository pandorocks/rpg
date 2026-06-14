# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Rpg::Run do
  def fresh_run
    described_class.new_game(width: 40, height: 20)
  end

  # Stand the player on the given tile kind and clear the current floor of enemies, then persist.
  def stage_on(run, tile_kind)
    world = run.current_world
    world.entities.each { |e| e.dead = true }
    run.player.x, run.player.y = world.find_tile(tile_kind)
    run.save_world(world)
  end

  it "starts a run with a single depth-1 level and a player" do
    run = fresh_run

    expect(run.current_depth).to eq(1)
    expect(run.levels.keys).to eq([1])
    expect(run.player).to be_a(Rpg::Player)
    expect(run.current_world.depth).to eq(1)
  end

  it "round-trips through JSON preserving player, levels, depth, and next_id" do
    run = fresh_run
    run.player.level = 5
    stage_on(run, "stairs")
    run.descend # gives us a second cached level

    restored = described_class.from_h(JSON.parse(JSON.generate(run.to_h)))

    expect(restored.current_depth).to eq(run.current_depth)
    expect(restored.player.level).to eq(5)
    expect(restored.levels.keys).to match_array(run.levels.keys)
    expect(restored.next_id).to eq(run.next_id)
    expect(restored.current_world.depth).to eq(run.current_depth)
  end

  it "carries the player to a newly generated floor on descend, placed at its entrance" do
    run = fresh_run
    run.player.level = 7
    run.player.max_hp = 60
    run.player.hp = 45
    stage_on(run, "stairs")

    world = run.descend

    expect(world).not_to be_nil
    expect(run.current_depth).to eq(2)
    expect(world.depth).to eq(2)
    expect(world.player.level).to eq(7)
    expect(world.player.hp).to eq(45)
    expect(world.on_upstairs?).to be(true)
  end

  it "reloads a previously visited floor on ascend, keeping prior changes" do
    run = fresh_run
    stage_on(run, "stairs") # clears depth-1 enemies and stands on the down-stairs
    run.descend

    stage_on(run, "upstairs") # clears depth-2 enemies and stands on the up-stairs
    world = run.ascend

    expect(world).not_to be_nil
    expect(run.current_depth).to eq(1)
    expect(world.alive_enemies).to be_empty # the depth-1 enemies we killed stayed dead
    expect(world.on_stairs?).to be(true) # came back up onto the down-stairs
  end

  it "drops a bloodstain and respawns the player at the bonfire on death" do
    run = fresh_run
    run.player.souls = 120
    bx, by = run.current_world.find_tile("bonfire")
    run.player.respawn_depth = 1
    run.player.respawn_x = bx
    run.player.respawn_y = by

    dead = run.current_world
    dead.player.x = 2
    dead.player.y = 2
    dead.player.hp = 0
    dead.state = "dead"
    target = run.respawn!(dead)

    expect(run.player.souls).to eq(0)
    expect([target.player.x, target.player.y]).to eq([bx, by])
    expect(target.player.hp).to eq(target.player.max_hp)
    expect(target.state).to eq("playing")
    stain = target.bloodstain_at(2, 2)
    expect(stain).not_to be_nil
    expect(stain.souls).to eq(120)
  end

  it "drops the bloodstain correctly across a serialized boundary (real per-request flow)" do
    json = JSON.generate(fresh_run.to_h)
    # The dead world and the responding run come from separate deserializations, exactly as
    # DungeonState does each request — the player object differs between them.
    dead = described_class.from_h(JSON.parse(json)).current_world
    dx, dy = dead.find_tile("stairs")
    dead.player.x = dx
    dead.player.y = dy
    dead.player.souls = 150
    dead.player.hp = 0
    dead.state = "dead"

    responder = described_class.from_h(JSON.parse(json))
    target = responder.respawn!(dead)

    expect(target.player.souls).to eq(0)
    expect(target.bloodstain_at(dx, dy)&.souls).to eq(150)
  end

  it "loses the previous bloodstain on a second death" do
    run = fresh_run
    bx, by = run.current_world.find_tile("bonfire")
    run.player.respawn_x = bx
    run.player.respawn_y = by

    run.player.souls = 50
    d1 = run.current_world
    d1.player.x = 3
    d1.player.y = 3
    run.respawn!(d1)

    run.player.souls = 70
    d2 = run.current_world
    d2.player.x = 4
    d2.player.y = 4
    run.respawn!(d2)

    target = run.current_world
    expect(target.bloodstain_at(3, 3)).to be_nil
    expect(target.bloodstain_at(4, 4)&.souls).to eq(70)
  end

  it "refuses to descend while enemies are alive" do
    run = fresh_run
    world = run.current_world
    run.player.x, run.player.y = world.find_tile("stairs")
    world.entities << Rpg::Entity.new(id: 999, kind: "goblin", x: 1, y: 1, hp: 5, max_hp: 5, damage: 1)
    run.save_world(world)

    expect(run.descend).to be_nil
    expect(run.current_depth).to eq(1)
    expect(run.current_world.messages).to include("Enemies block the stairs!")
  end
end
