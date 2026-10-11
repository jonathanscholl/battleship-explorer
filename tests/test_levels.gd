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
	var catalog := LevelCatalog.new()
	_check(catalog.levels.size() == 3, "Three valid levels did not load")
	if catalog.levels.size() != 3:
		quit(1)
		return
	_check(catalog.levels[0].id == "first_encounter" and catalog.levels[1].id == "pirate_scout" and catalog.levels[2].id == "pirate_captain", "Level order wrong")
	for level in catalog.levels:
		_check(level.validate().is_empty(), "Invalid authored level: " + level.id)
		for seed_value in [1, 2, 3, 17, 101]:
			var battle := BattleModel.new(seed_value, level.to_rules())
			_check(battle.state == BattleModel.State.RUNNING, "Level could not generate: " + level.id)
			_check(battle.player_grid.ship.get_total_hp() == level.player_shape.size() * level.player_section_hp, "Player HP differs from resource")
			_check(battle.enemy_grid.ship.get_total_hp() == level.enemy_shape.size() * level.enemy_section_hp, "Enemy HP differs from resource")
			_check(battle.player_upgrades.coins == level.player_starting_coins and battle.enemy_upgrades.coins == level.enemy_starting_coins, "Starting coins differ from resource")
			_check(battle.player_cannon.interval == level.cannon_interval and battle.enemy_discovery_remaining == level.enemy_discovery_interval, "Timers differ from resource")
			for grid in [battle.player_grid, battle.enemy_grid]:
				_check(grid._special.size() == level.treasure_count + level.island_count, "Special count wrong")
				for cell in grid._special:
					_check(not grid.ship.has_section(cell), "Special overlaps a ship")
	var invalid := LevelDefinition.new()
	invalid.id = "bad"
	invalid.title = "Bad"
	invalid.enemy_shape = [Vector2i.ZERO, Vector2i(2, 0)]
	_check(not invalid.validate().is_empty(), "Disconnected ship accepted")
	invalid.enemy_shape = [Vector2i.ZERO, Vector2i.RIGHT]
	invalid.treasure_count = 36
	_check(not invalid.validate().is_empty(), "Overfull level accepted")

	var path := "user://test_progress_m4.json"
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.remove_absolute(absolute)
	var progress := LevelProgress.new(catalog, path)
	_check(progress.is_unlocked("first_encounter") and not progress.is_unlocked("pirate_scout"), "Missing save did not start at level 1")
	_check(not progress.complete("pirate_scout"), "Locked level was completable")
	_check(progress.complete("first_encounter"), "Victory did not persist")
	_check(progress.is_unlocked("pirate_scout") and not progress.is_unlocked("pirate_captain"), "Victory unlocked wrong level")
	var reopened := LevelProgress.new(catalog, path)
	_check(reopened.is_unlocked("pirate_scout") and reopened.completed.has("first_encounter"), "Progress did not survive restart")
	_check(reopened.complete("first_encounter") and reopened.completed.size() == 1, "Replay erased or duplicated completion")
	_check(reopened.complete("pirate_scout") and reopened.is_unlocked("pirate_captain"), "Second victory did not unlock final level")
	_check(reopened.complete("pirate_captain") and catalog.next_id("pirate_captain").is_empty(), "Final level offered a next level")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken json")
	file.close()
	var corrupt := LevelProgress.new(catalog, path)
	_check(corrupt.unlocked.size() == 1 and corrupt.completed.is_empty(), "Corrupt save did not fall back")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 999, "completed": ["first_encounter"], "unlocked": ["pirate_scout"]}))
	file.close()
	var outdated := LevelProgress.new(catalog, path)
	_check(outdated.unlocked.size() == 1 and outdated.completed.is_empty(), "Outdated save did not fall back")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "completed": ["unknown", "first_encounter"], "unlocked": ["unknown"]}))
	file.close()
	var unknown := LevelProgress.new(catalog, path)
	_check(unknown.completed.size() == 1 and unknown.is_unlocked("pirate_scout") and not unknown.is_unlocked("unknown"), "Unknown IDs were accepted")
	DirAccess.remove_absolute(absolute)

	var screen: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set("progress", LevelProgress.new(catalog, path))
	screen.call("_update_level_buttons")
	_check(screen.get("level_overlay").visible, "Level select not shown")
	screen.call("_start_level", 1)
	_check(screen.get("current_level").id == "first_encounter", "Locked level started")
	screen.call("_start_level", 0)
	var first_battle: BattleModel = screen.get("battle")
	_check(not first_battle.paused and first_battle.rules.grid_size == 5, "Level 1 did not start")
	var player_last: Vector2i = first_battle.player_grid.ship.sections.keys()[0]
	for cell in first_battle.player_grid.ship.sections.keys():
		first_battle.player_grid.ship.damage(cell, first_battle.player_grid.ship.section_max_hp if cell != player_last else first_battle.player_grid.ship.section_max_hp - 1)
	first_battle._discover(false, player_last)
	first_battle.enemy_cannon.select_target(first_battle.enemy_knowledge, player_last)
	first_battle.enemy_cannon.remaining = 0.01
	first_battle.advance(0.01)
	_check(first_battle.state == BattleModel.State.DEFEAT and not screen.get("progress").is_unlocked("pirate_scout"), "Loss unlocked a level")
	screen.call("_restart")
	_check(first_battle.state == BattleModel.State.RUNNING and first_battle.player_grid.ship.get_total_hp() == 12, "Retry after loss did not reset")
	first_battle.player_upgrades.grant_coins(10)
	first_battle.purchase_player(UpgradeState.Kind.DAMAGE)
	first_battle.player_discover(first_battle.enemy_grid.ship.sections.keys()[0])
	screen.call("_restart")
	_check(first_battle.player_upgrades.coins == 4 and first_battle.player_upgrades.damage_level == 1 and first_battle.player_knowledge.revealed_count() == 0 and first_battle.player_cannon.target == Vector2i(-1, -1), "Retry retained temporary state")
	var target: Vector2i = first_battle.enemy_grid.ship.sections.keys()[0]
	for cell in first_battle.enemy_grid.ship.sections.keys():
		first_battle.enemy_grid.ship.damage(cell, first_battle.enemy_grid.ship.section_max_hp if cell != target else first_battle.enemy_grid.ship.section_max_hp - 1)
	first_battle._discover(true, target)
	first_battle.player_cannon.select_target(first_battle.player_knowledge, target)
	first_battle.player_cannon.remaining = 0.01
	first_battle.advance(0.01)
	_check(first_battle.state == BattleModel.State.VICTORY and screen.get("progress").is_unlocked("pirate_scout"), "Victory did not unlock level 2")
	screen.call("_next_level")
	_check(screen.get("current_level").id == "pirate_scout" and screen.get("battle").player_knowledge.revealed_count() == 0, "Next level did not start fresh")
	screen.call("_open_level_select")
	_check(screen.get("battle").paused and screen.get("level_overlay").visible, "Level select did not pause battle")
	screen.call("_start_level", 0)
	_check(screen.get("current_level").id == "first_encounter", "Completed level could not replay")
	screen.get("progress").complete("pirate_scout")
	screen.call("_start_level", 2)
	var final_battle: BattleModel = screen.get("battle")
	var final_target: Vector2i = final_battle.enemy_grid.ship.sections.keys()[0]
	for cell in final_battle.enemy_grid.ship.sections.keys():
		final_battle.enemy_grid.ship.damage(cell, final_battle.enemy_grid.ship.section_max_hp if cell != final_target else final_battle.enemy_grid.ship.section_max_hp - 1)
	final_battle._discover(true, final_target)
	final_battle.player_cannon.select_target(final_battle.player_knowledge, final_target)
	final_battle.player_cannon.remaining = 0.01
	final_battle.advance(0.01)
	_check(final_battle.state == BattleModel.State.VICTORY and not screen.get("next_button").visible, "Final level offered nonexistent next level")
	DirAccess.remove_absolute(absolute)

	if failures == 0:
		print("PASS: %d level and save checks" % checks)
	else:
		print("FAIL: %d of %d level and save checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
