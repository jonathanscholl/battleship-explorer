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
	var special_grid := GridModel.new()
	var one_section: Array[Vector2i] = [Vector2i.ZERO]
	_check(special_grid.generate(5, 7, one_section, 1, 1, 3), "Special relocation setup failed")
	var special_cell: Vector2i = special_grid._special.keys()[0]
	_check(special_grid.relocate_ship(one_section, special_cell, 0, 3), "Ship could not displace a hidden special tile")
	_check(special_grid._special.size() == 2 and not special_grid._special.has(special_cell), "Ship placement lost or overlapped a special tile")
	var level: LevelDefinition = load("res://resources/levels/first_encounter.tres")
	var battle := BattleModel.new(41, level.to_rules(), true)
	_check(battle.state == BattleModel.State.SETUP and battle.player_grid.ship.sections.is_empty(), "Tactical battle did not begin with placement")
	battle.advance(100.0)
	_check(battle.enemy_knowledge.revealed_count() == 0 and battle.enemy_scouts.pending.is_empty(), "Enemy acted before placement")
	_check(not battle.begin_battle() and not battle.place_player_ship(Vector2i(4, 4), 0), "Invalid or absent placement accepted")
	_check(battle.place_player_ship(Vector2i(1, 2), 0), "Valid ship placement failed")
	_check(battle.player_upgrades.ship == battle.player_grid.ship, "Placement detached upgrade state from the ship")
	_check(battle.player_grid.ship.get_total_hp() == level.player_shape.size() * level.player_section_hp * level.tactical_hp_multiplier, "Tactical HP multiplier wrong")
	for cell: Vector2i in battle.player_grid.ship.sections.keys():
		_check(not battle.player_grid._special.has(cell), "Ship placement overlaps a special tile")
	_check(battle.begin_battle() and battle.state == BattleModel.State.RUNNING, "Placed ship could not begin battle")
	_check(not battle.place_player_ship(Vector2i(0, 0), 0), "Ship moved after battle started")
	_check(battle.player_crew_available() == level.crew_total and not battle.player_order_fire(), "Crew or untargeted gun start wrong")
	_check(battle.player_send_scout(Vector2i(0, 0)), "Scout order failed")
	_check(battle.player_crew_available() == level.crew_total - 1 and battle.player_knowledge.revealed_count() == 0, "Scout did not occupy one worker during travel")
	var target: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	battle._discover(true, target)
	_check(battle.player_select_target(target), "Discovered target could not be selected")
	_check(battle.player_order_fire() and battle.player_crew_available() == 0, "Gun did not occupy two workers")
	_check(not battle.player_order_fire() and not battle.player_send_scout(Vector2i(4, 4)), "Busy crew accepted another order")
	var hp_before := battle.enemy_grid.ship.get_total_hp()
	battle.advance(1.0)
	_check(battle.enemy_grid.ship.get_total_hp() == hp_before, "Shot fired before aim finished")
	battle.set_paused(true)
	var remaining: float = battle.player_order["remaining"]
	battle.advance(100.0)
	_check(is_equal_approx(float(battle.player_order["remaining"]), remaining) and not battle.player_order_repair(), "Pause advanced or accepted order")
	battle.set_paused(false)
	battle.advance(2.01)
	_check(battle.enemy_grid.ship.get_total_hp() == hp_before - battle.player_cannon.damage, "Manual shot did not resolve")
	_check(battle.player_crew_available() == level.crew_total, "Crew did not return after scout and gun orders")
	var own_cell: Vector2i = battle.player_grid.ship.sections.keys()[0]
	battle.player_grid.ship.damage(own_cell, 4)
	var coins_before_repair := battle.player_upgrades.coins
	_check(battle.player_order_repair() and battle.player_crew_available() == 1 and battle.player_upgrades.coins == coins_before_repair - level.repair_order_cost, "Repair did not reserve two crew and coins")
	_check(not battle.player_order_fire(), "Fire started while two crew were repairing")
	battle.advance(level.repair_order_time + 0.01)
	_check(battle.player_grid.ship.get_section_hp(own_cell) == level.player_section_hp * level.tactical_hp_multiplier and battle.player_crew_available() == level.crew_total, "Repair did not complete and release crew")
	battle.start_battle(41)
	_check(battle.state == BattleModel.State.SETUP and battle.player_crew_available() == level.crew_total and battle.player_order.is_empty(), "Retry kept tactical orders")

	var enemy := BattleModel.new(52, level.to_rules(), true)
	enemy.place_player_ship(Vector2i(0, 0), 0)
	enemy.begin_battle()
	enemy.advance(level.enemy_order_interval)
	_check(enemy.enemy_scouts.pending.size() == 1 and enemy.enemy_crew_available() == level.crew_total - 1, "Enemy did not assign a scout")
	enemy.advance(level.scout_travel_time + 0.01)
	_check(enemy.enemy_knowledge.revealed_count() == 4 and enemy.enemy_crew_available() == level.crew_total, "Enemy scout did not return and reveal")


	var enemy_attack := BattleModel.new(53, level.to_rules(), true)
	enemy_attack.place_player_ship(Vector2i(0, 0), 0)
	enemy_attack.begin_battle()
	var exposed: Vector2i = enemy_attack.player_grid.ship.sections.keys()[0]
	enemy_attack._discover(false, exposed)
	enemy_attack.enemy_order_remaining = 0.01
	enemy_attack.advance(0.01)
	_check(enemy_attack.enemy_order.get("kind", "") == "fire" and enemy_attack.enemy_crew_available() <= 1, "Enemy did not assign two crew to attack")
	var player_hp_before := enemy_attack.player_grid.ship.get_total_hp()
	enemy_attack.advance(level.gun_aim_time + 0.01)
	_check(enemy_attack.player_grid.ship.get_total_hp() == player_hp_before - enemy_attack.enemy_cannon.damage, "Enemy aimed shot did not hit")

	var enemy_repair := BattleModel.new(54, level.to_rules(), true)
	enemy_repair.place_player_ship(Vector2i(0, 0), 0)
	enemy_repair.begin_battle()
	var damaged_cell: Vector2i = enemy_repair.enemy_grid.ship.sections.keys()[0]
	enemy_repair._discover(true, damaged_cell)
	enemy_repair.enemy_grid.ship.damage(damaged_cell, level.enemy_repair_threshold * level.tactical_hp_multiplier)
	enemy_repair.player_knowledge.record_section_hp(damaged_cell, enemy_repair.enemy_grid.ship.get_section_hp(damaged_cell))
	enemy_repair.enemy_upgrades.grant_coins(level.repair_order_cost)
	enemy_repair.enemy_order_remaining = 0.01
	enemy_repair.advance(0.01)
	_check(enemy_repair.enemy_order.get("kind", "") == "repair" and enemy_repair.enemy_crew_available() <= 1, "Enemy did not assign two crew to repair")
	var damaged_hp := enemy_repair.enemy_grid.ship.get_total_hp()
	enemy_repair.advance(level.repair_order_time + 0.01)
	_check(enemy_repair.enemy_grid.ship.get_total_hp() > damaged_hp and enemy_repair.player_knowledge.visible_section_hp(damaged_cell) == enemy_repair.enemy_grid.ship.get_section_hp(damaged_cell), "Enemy repair did not restore known section")

	var short_rules := BattleRules.new()
	short_rules.player_shape = [Vector2i.ZERO, Vector2i.RIGHT]
	short_rules.enemy_shape = [Vector2i.ZERO, Vector2i.RIGHT]
	short_rules.player_section_hp = 3
	short_rules.enemy_section_hp = 1
	short_rules.tactical_hp_multiplier = 1
	short_rules.enemy_order_interval = 100.0
	var finish := BattleModel.new(91, short_rules, true)
	finish.place_player_ship(Vector2i(0, 0), 0)
	finish.begin_battle()
	for cell: Vector2i in finish.enemy_grid.ship.sections.keys():
		finish._discover(true, cell)
	var first: Vector2i = finish.enemy_grid.ship.sections.keys()[0]
	finish.player_select_target(first)
	finish.player_order_fire()
	finish.advance(short_rules.gun_aim_time + 0.01)
	_check(finish.state == BattleModel.State.RUNNING and finish.enemy_grid.ship.get_total_hp() == 1, "Battle ended after only one shot")
	_check(finish.player_order_fire(), "Second manual shot was not available")
	finish.advance(short_rules.gun_aim_time + 0.01)
	_check(finish.state == BattleModel.State.VICTORY and finish.enemy_grid.ship.get_total_hp() == 0, "Manual fire could not win battle")
	if failures == 0:
		print("PASS: %d tactical checks" % checks)
	else:
		print("FAIL: %d of %d tactical checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
