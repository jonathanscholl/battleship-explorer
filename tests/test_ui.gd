extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.get("audio").set_music_volume(0.0)
	screen.get("audio").set_sound_volume(0.0)
	var menu: ColorRect = screen.get("level_overlay")
	if not menu.visible or not screen.get("battle").paused:
		push_error("Level select did not open at startup")
		quit(1)
		return
	screen.call("_start_level", 0)
	if menu.visible:
		push_error("Level 1 did not start")
		quit(1)
		return
	var pause_overlay: ColorRect = screen.get("pause_overlay")
	var menu_button: Button = screen.get("menu_button")
	menu_button.pressed.emit()
	if not pause_overlay.visible or not screen.get("battle").paused:
		push_error("Menu did not pause battle")
		quit(1)
		return
	screen.get("resume_button").pressed.emit()
	if pause_overlay.visible or screen.get("battle").paused:
		push_error("Resume did not restore battle")
		quit(1)
		return
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	var grid_rect: Rect2 = screen.get("grid_rect")
	var cell_size: float = screen.get("cell_size")
	tap.position = grid_rect.position + Vector2.ONE * cell_size * 0.5
	screen.call("_gui_input", tap)
	var grid: GridModel = screen.get("grid")
	if grid.get_revealed_count() != 0 or screen.get("battle").player_scouts.pending.size() != 1:
		push_error("Touch did not dispatch a scout")
		quit(1)
		return
	screen.call("_gui_input", tap)
	if screen.get("battle").player_scouts.pending.size() != 1:
		push_error("Repeated touch dispatched another scout")
		quit(1)
		return
	var battle: BattleModel = screen.get("battle")
	battle.advance(battle.rules.scout_travel_time)
	if battle.player_knowledge.revealed_count() != 4 or battle.enemy_knowledge.revealed_count() != 0:
		push_error("Touch changed the wrong grid")
		quit(1)
		return
	var preview: Rect2 = screen.get("preview_rect")
	tap.position = preview.position + preview.size * 0.5
	screen.call("_gui_input", tap)
	if screen.get("showing_enemy") or battle.player_knowledge.revealed_count() != 4:
		push_error("Preview tap did not swap views or changed game state")
		quit(1)
		return
	screen.call("_switch_view")
	if not screen.get("showing_enemy"):
		push_error("View did not switch back")
		quit(1)
		return
	var damage_button: Button = screen.get("damage_button")
	var repair_button: Button = screen.get("repair_button")
	if not damage_button.disabled and battle.player_upgrades.coins < 8:
		push_error("Unaffordable damage button is enabled")
		quit(1)
		return
	if not repair_button.disabled:
		push_error("Repair button enabled at full health")
		quit(1)
		return
	battle.player_upgrades.grant_coins(maxi(0, 8 - battle.player_upgrades.coins))
	if damage_button.disabled:
		push_error("Affordable damage button did not enable")
		quit(1)
		return
	screen.call("_buy", UpgradeState.Kind.DAMAGE)
	var next_damage_cost := battle.player_upgrades.next_cost(UpgradeState.Kind.DAMAGE)
	if battle.player_upgrades.damage_level != 2 or damage_button.text.find("DAMAGE") < 0 or damage_button.text.find("%d GOLD" % next_damage_cost) < 0:
		push_error("Damage button did not purchase or update")
		quit(1)
		return
	var scout_button: Button = screen.get("scout_button")
	battle.player_upgrades.grant_coins(maxi(0, 12 - battle.player_upgrades.coins))
	if scout_button.disabled:
		push_error("Affordable scout upgrade did not enable")
		quit(1)
		return
	screen.call("_buy", UpgradeState.Kind.SCOUT)
	if battle.player_upgrades.scout_level != 2 or scout_button.text.find("22") < 0:
		push_error("Scout upgrade button did not purchase or update")
		quit(1)
		return
	print("PASS: touch, scouts, view switching, upgrade buttons")
	screen.get("effects").clear_effects()
	screen.queue_free()
	for i in 6:
		await process_frame
	quit(0)
