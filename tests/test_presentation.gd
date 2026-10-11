extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	for path in ["res://assets/sprites/ship.png", "res://assets/sprites/island.png", "res://assets/sprites/treasure.png", "res://assets/sprites/water_hidden.svg", "res://assets/sprites/water_revealed.svg", "res://assets/sprites/target.svg", "res://assets/sprites/destroyed.svg", "res://assets/sprites/cannon.svg", "res://assets/sprites/cannonball.svg", "res://assets/sprites/coin.svg", "res://assets/sprites/impact.svg", "res://assets/sprites/splash.svg"]:
		var texture := load(path) as Texture2D
		_check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Missing sprite: " + path)
	var screen: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var audio: GameAudio = screen.get("audio")
	var effects: BattleEffects = screen.get("effects")
	_check(not audio.unlocked and not audio.music_player.playing, "Audio began before a gesture")
	audio.set_music_volume(0.0)
	audio.set_sound_volume(0.0)
	screen.call("_start_level", 0)
	_check(audio.unlocked and not audio.music_player.playing, "Mute changed gesture unlock behavior")
	var battle: BattleModel = screen.get("battle")
	var target: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	battle._discover(true, target)
	battle.player_cannon.select_target(battle.player_knowledge, target)
	var hp_before := battle.enemy_grid.ship.get_total_hp()
	battle.player_cannon.remaining = 0.01
	battle.advance(0.01)
	_check(battle.enemy_grid.ship.get_total_hp() == hp_before - 1, "Projectile animation delayed damage")
	_check(effects.get_child_count() > 0, "Shot spawned no visual effect")
	var impacts := [0]
	effects.impact_landed.connect(func() -> void: impacts[0] += 1)
	screen.call("_switch_view")
	_check(effects.generation > 0, "View switch did not cancel effects")
	await create_timer(0.4).timeout
	_check(impacts[0] == 0, "Canceled projectile produced a stale impact")
	screen.call("_open_settings")
	_check(battle.paused and screen.get("settings_overlay").visible, "Audio settings did not pause battle")
	var hp_hold := battle.enemy_grid.ship.get_total_hp()
	var coins_hold := battle.player_upgrades.coins
	audio.unlocked = false
	audio.set_music_volume(0.25)
	audio.set_sound_volume(0.35)
	_check(audio.music_volume == 0.25 and audio.sound_volume == 0.35 and battle.enemy_grid.ship.get_total_hp() == hp_hold and battle.player_upgrades.coins == coins_hold, "Volume changed gameplay")
	audio.set_music_volume(0.0)
	audio.set_sound_volume(0.0)
	audio.unlocked = true
	screen.call("_close_settings")
	_check(not battle.paused and not screen.get("settings_overlay").visible, "Audio settings did not resume battle")
	var final_cell: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	for cell in battle.enemy_grid.ship.sections.keys():
		battle.enemy_grid.ship.damage(cell, battle.enemy_grid.ship.get_section_hp(cell) if cell != final_cell else battle.enemy_grid.ship.get_section_hp(cell) - 1)
	battle.player_cannon.select_target(battle.player_knowledge, final_cell)
	battle.player_cannon.remaining = 0.01
	battle.advance(0.01)
	_check(battle.state == BattleModel.State.VICTORY and battle.enemy_grid.ship.get_total_hp() == 0, "Presentation changed terminal shot ordering")
	await create_timer(0.5).timeout
	screen.call("_restart")
	_check(battle.enemy_grid.ship.get_total_hp() == battle.enemy_grid.ship.get_max_hp() and battle.player_knowledge.revealed_count() == 0, "Restart kept effect-related battle state")
	_check(effects.get_child_count() == 0, "Restart left an effect node")
	screen.queue_free()
	for i in 6:
		await process_frame
	if failures == 0:
		print("PASS: %d presentation checks" % checks)
	else:
		print("FAIL: %d of %d presentation checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
