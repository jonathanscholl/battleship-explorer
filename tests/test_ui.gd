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
	var screen: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.get("audio").set_music_volume(0.0)
	screen.get("audio").set_sound_volume(0.0)
	var battle: BattleModel = screen.get("battle")
	_check(screen.get("level_overlay").visible and battle.paused, "Level select did not open paused")
	screen.call("_start_level", 0)
	_check(not screen.get("level_overlay").visible and battle.state == BattleModel.State.SETUP, "Level did not enter placement")
	_check(not screen.get("showing_enemy") and screen.get("launch_button").visible, "Own board or setup controls missing")
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	var grid_rect: Rect2 = screen.get("grid_rect")
	var cell_size: float = screen.get("cell_size")
	tap.position = grid_rect.position + Vector2(1.5, 2.5) * cell_size
	screen.call("_gui_input", tap)
	_check(battle.player_grid.ship.sections.size() == 3 and battle.player_grid.ship.get_total_hp() == 24, "Tap did not place ship")
	_check(not screen.get("launch_button").disabled, "Placed ship did not enable launch")
	screen.get("launch_button").pressed.emit()
	_check(battle.state == BattleModel.State.RUNNING and screen.get("showing_enemy") and screen.get("fire_button").visible, "Launch did not enter battle")
	grid_rect = screen.get("grid_rect")
	cell_size = screen.get("cell_size")
	tap.position = grid_rect.position + Vector2.ONE * cell_size * 0.5
	screen.call("_gui_input", tap)
	_check(battle.player_scouts.pending.size() == 1 and battle.player_crew_available() == 2, "Touch did not dispatch one-worker scout")
	screen.call("_gui_input", tap)
	_check(battle.player_scouts.pending.size() == 1, "Repeated touch dispatched a second scout")
	battle.advance(battle.rules.scout_travel_time + 0.01)
	_check(battle.player_knowledge.revealed_count() == 4 and battle.player_crew_available() == 3, "Scout did not reveal and release crew")
	var target: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	battle._discover(true, target)
	tap.position = grid_rect.position + (Vector2(target) + Vector2.ONE * 0.5) * cell_size
	screen.call("_gui_input", tap)
	_check(battle.player_cannon.target == target, "Tap did not select target")
	screen.call("_update_hud")
	_check(not screen.get("fire_button").disabled, "Targeted fire button remained disabled")
	var hp_before := battle.enemy_grid.ship.get_total_hp()
	screen.get("fire_button").pressed.emit()
	_check(battle.player_crew_available() == 1 and battle.enemy_grid.ship.get_total_hp() == hp_before, "Fire did not reserve crew before shot")
	battle.advance(battle.rules.gun_aim_time + 0.01)
	_check(battle.enemy_grid.ship.get_total_hp() == hp_before - 1, "Manual fire did not hit")
	screen.get("armory_button").pressed.emit()
	_check(screen.get("armory_overlay").visible and battle.paused, "Armory did not pause battle")
	battle.player_upgrades.grant_coins(20)
	screen.call("_update_hud")
	screen.get("damage_button").pressed.emit()
	_check(battle.player_upgrades.damage_level == 2, "Armory damage upgrade did not purchase")
	screen.get("armory_close_button").pressed.emit()
	_check(not battle.paused and not screen.get("armory_overlay").visible, "Armory did not resume battle")
	var preview: Rect2 = screen.get("preview_rect")
	tap.position = preview.position + preview.size * 0.5
	screen.call("_gui_input", tap)
	_check(not screen.get("showing_enemy"), "Preview tap did not switch to own waters")
	screen.call("_switch_view")
	_check(screen.get("showing_enemy"), "Switch did not return to enemy waters")
	var own_cell: Vector2i = battle.player_grid.ship.sections.keys()[0]
	battle.player_grid.ship.damage(own_cell, 4)
	screen.call("_update_hud")
	screen.get("crew_repair_button").pressed.emit()
	_check(battle.player_order.get("kind", "") == "repair" and battle.player_crew_available() == 1, "Repair did not assign crew")
	var menu_button: Button = screen.get("menu_button")
	menu_button.pressed.emit()
	_check(screen.get("pause_overlay").visible and battle.paused, "Menu did not pause battle")
	screen.get("resume_button").pressed.emit()
	_check(not battle.paused, "Resume did not restore battle")
	if failures == 0:
		print("PASS: %d tactical UI checks" % checks)
	else:
		print("FAIL: %d of %d tactical UI checks" % [failures, checks])
	screen.get("effects").clear_effects()
	screen.queue_free()
	for i in 6:
		await process_frame
	quit(1 if failures > 0 else 0)
