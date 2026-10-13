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
	var small := GridModel.new()
	var small_shape: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN]
	_check(small.generate(2, 6, small_shape, 1, 0), "Crowded valid grid failed")
	_check(not small.generate(2, 6, small_shape, 1, 1), "Overfull grid accepted")
	var grid := GridModel.new()
	_check(grid.generate(6, 88, ShipModel.DEFAULT_SHAPE, 2, 2), "Special grid failed")
	var treasure := 0
	var island := 0
	for y in 6:
		for x in 6:
			var cell := Vector2i(x, y)
			_check(grid.visible_kind(cell) == GridModel.TileKind.HIDDEN, "Hidden special leaked")
			var kind := grid.reveal(cell)
			if kind == GridModel.TileKind.TREASURE:
				treasure += 1
				_check(not grid.ship.has_section(cell), "Treasure overlaps ship")
			elif kind == GridModel.TileKind.ISLAND:
				island += 1
				_check(not grid.ship.has_section(cell), "Island overlaps ship")
	_check(treasure == 2 and island == 2, "Wrong special counts")

	var battle := BattleModel.new(101, null, false)
	var treasure_cell := Vector2i(-1, -1)
	var island_cell := Vector2i(-1, -1)
	for cell in battle.enemy_grid._special:
		if battle.enemy_grid._special[cell] == GridModel.TileKind.TREASURE:
			treasure_cell = cell
		elif battle.enemy_grid._special[cell] == GridModel.TileKind.ISLAND:
			island_cell = cell
	_check(battle.player_knowledge.visible_kind(treasure_cell) == GridModel.TileKind.HIDDEN, "Preview leaked treasure")
	_check(battle._discover(true, treasure_cell), "Treasure discovery failed")
	_check(battle.player_upgrades.coins == 10, "Treasure reward wrong")
	_check(not battle._discover(true, treasure_cell) and battle.player_upgrades.coins == 10, "Treasure paid twice")
	battle.advance(0.8)
	_check(battle._discover(true, island_cell) and battle.player_upgrades.coins == 15, "Island reward wrong")
	_check(battle.enemy_upgrades.coins == 0, "Player discovery paid enemy")
	var ship_cell: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	battle._discover(true, ship_cell)
	battle.player_cannon.select_target(battle.player_knowledge, ship_cell)
	battle.player_cannon.damage = 9
	battle.player_cannon.remaining = 0.01
	battle.advance(0.01)
	_check(battle.player_upgrades.coins == 20, "Damage reward exceeded actual 5 HP")
	_check(battle.enemy_grid.ship.get_section_hp(ship_cell) == 0, "Shot did not destroy section")
	battle.advance(5.0)
	_check(battle.player_upgrades.coins == 20, "Destroyed section generated more coins")

	var rules := BattleRules.new()
	var ship := ShipModel.new()
	ship.place(ShipModel.DEFAULT_SHAPE, Vector2i.ZERO, 0, 6)
	var cannon := CannonModel.new()
	var upgrades := UpgradeState.new(rules, cannon, ship)
	_check(not upgrades.purchase(UpgradeState.Kind.DAMAGE, true), "Unaffordable purchase accepted")
	upgrades.grant_coins(8)
	cannon.remaining = 2.5
	_check(upgrades.purchase(UpgradeState.Kind.DAMAGE, true), "Exact-cost damage purchase failed")
	_check(upgrades.coins == 0 and cannon.damage == 2 and cannon.remaining == 2.5, "Damage upgrade altered cooldown or balance")
	upgrades.grant_coins(10)
	_check(upgrades.purchase(UpgradeState.Kind.SPEED, true), "Exact-cost speed purchase failed")
	_check(upgrades.coins == 0 and cannon.interval == 4.0 and is_equal_approx(cannon.remaining, 2.0), "Speed did not preserve cooldown progress")
	_check(cannon.remaining > 0.0, "Speed created immediate shot")
	upgrades.grant_coins(100)
	_check(upgrades.purchase(UpgradeState.Kind.DAMAGE, true) and upgrades.purchase(UpgradeState.Kind.DAMAGE, true), "Damage progression failed")
	_check(cannon.damage == 4 and not upgrades.purchase(UpgradeState.Kind.DAMAGE, true), "Damage max level failed")
	_check(upgrades.purchase(UpgradeState.Kind.SPEED, true) and upgrades.purchase(UpgradeState.Kind.SPEED, true), "Speed progression failed")
	_check(cannon.interval == 2.0 and not upgrades.purchase(UpgradeState.Kind.SPEED, true), "Speed max level failed")
	_check(not upgrades.purchase(UpgradeState.Kind.REPAIR, true), "Repair at full HP accepted")
	upgrades.grant_coins(16)
	var first := Vector2i(0, 0)
	var second := Vector2i(1, 0)
	ship.damage(first, 5)
	ship.damage(second, 2)
	var before := ship.get_total_hp()
	_check(upgrades.purchase(UpgradeState.Kind.REPAIR, true), "Repair purchase failed")
	_check(ship.get_section_hp(second) == 5 and ship.get_section_hp(first) == 3, "Repair order incorrect")
	_check(ship.get_total_hp() == before + 5 and ship.get_total_hp() <= ship.get_max_hp(), "Repair exceeded HP cap")
	_check(upgrades.purchase(UpgradeState.Kind.REPAIR, true) and ship.get_total_hp() == ship.get_max_hp(), "Second repair did not cap at max")
	for cell in ship.sections.keys():
		ship.damage(cell, 5)
	_check(not upgrades.purchase(UpgradeState.Kind.REPAIR, true), "Sunk ship repaired")
	_check(not upgrades.purchase(UpgradeState.Kind.REPAIR, false), "Purchase worked after battle")

	var enemy := BattleModel.new(44, null, false)
	enemy.enemy_grid.ship.damage(enemy.enemy_grid.ship.sections.keys()[0], 5)
	enemy.enemy_upgrades.grant_coins(8)
	enemy.advance(0.01)
	_check(enemy.enemy_grid.ship.get_total_hp() == 15 and enemy.enemy_upgrades.coins == 0, "Enemy did not prioritize repair")
	enemy.enemy_upgrades.grant_coins(8)
	enemy.advance(0.01)
	_check(enemy.enemy_upgrades.damage_level == 2 and enemy.enemy_cannon.damage == 2, "Enemy did not buy damage")
	_check(enemy.enemy_ai.knowledge == enemy.enemy_knowledge, "Enemy upgrade gained hidden grid access")
	var enemy_target: Vector2i = enemy.player_grid.ship.sections.keys()[0]
	enemy._discover(false, enemy_target)
	enemy.enemy_cannon.select_target(enemy.enemy_knowledge, enemy_target)
	enemy.enemy_cannon.remaining = 0.01
	enemy.advance(0.01)
	_check(enemy.player_grid.ship.get_total_hp() == 13 and enemy.enemy_upgrades.coins == 2, "Enemy damage reward wrong")

	# Regression: an enemy repair must revive the revealed section in the player's
	# knowledge too. Otherwise both sections can appear wrecked while HP remains.
	var first_level: LevelDefinition = load("res://resources/levels/first_encounter.tres")
	var repair_battle := BattleModel.new(77, first_level.to_rules(), false)
	var repaired_events: Array = []
	repair_battle.ship_repaired.connect(func(by_player: bool, amount: int) -> void: repaired_events.append([by_player, amount]))
	var sections: Array = repair_battle.enemy_grid.ship.sections.keys()
	var repaired_cell: Vector2i = sections[0]
	var other_cell: Vector2i = sections[1]
	repair_battle._discover(true, repaired_cell)
	repair_battle._discover(true, other_cell)
	repair_battle.enemy_upgrades.grant_coins(first_level.repair_cost)
	repair_battle.player_cannon.damage = first_level.enemy_section_hp
	repair_battle.player_cannon.select_target(repair_battle.player_knowledge, repaired_cell)
	repair_battle.player_cannon.remaining = 0.01
	repair_battle.advance(0.01)
	_check(repair_battle.enemy_grid.ship.get_section_hp(repaired_cell) == first_level.enemy_section_hp and repair_battle.player_knowledge.visible_section_hp(repaired_cell) == first_level.enemy_section_hp, "Enemy repaired a section but player still sees a wreck")
	_check(repaired_events.size() == 1 and repaired_events[0] == [false, first_level.enemy_section_hp], "Enemy repair event missing or incorrect")
	_check(repair_battle.player_knowledge.revealed_count() == 2, "Repair revealed a hidden tile")
	repair_battle.player_cannon.select_target(repair_battle.player_knowledge, other_cell)
	repair_battle.player_cannon.remaining = 0.01
	repair_battle.advance(0.01)
	_check(repair_battle.enemy_grid.ship.get_total_hp() == first_level.enemy_section_hp and repair_battle.player_cannon.target == repaired_cell, "Cannon did not retarget repaired section")
	repair_battle.player_cannon.remaining = 0.01
	repair_battle.advance(0.01)
	_check(repair_battle.state == BattleModel.State.VICTORY and repair_battle.enemy_grid.ship.get_total_hp() == 0, "Repaired two-section ship cannot be defeated")
	var own_repair := BattleModel.new(78, first_level.to_rules(), false)
	var own_cell: Vector2i = own_repair.player_grid.ship.sections.keys()[0]
	own_repair._discover(false, own_cell)
	own_repair.player_grid.ship.damage(own_cell, first_level.player_section_hp)
	own_repair.enemy_knowledge.record_section_hp(own_cell, 0)
	own_repair.player_upgrades.grant_coins(first_level.repair_cost)
	_check(own_repair.purchase_player(UpgradeState.Kind.REPAIR) and own_repair.enemy_knowledge.visible_section_hp(own_cell) == first_level.player_section_hp, "Player repair did not update enemy knowledge")
	_check(own_repair.enemy_knowledge.revealed_count() == 1 and own_repair.enemy_cannon.select_target(own_repair.enemy_knowledge, own_cell), "Player repair leaked hidden sections or remained untargetable")

	if failures == 0:
		print("PASS: %d economy checks" % checks)
	else:
		print("FAIL: %d of %d economy checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
