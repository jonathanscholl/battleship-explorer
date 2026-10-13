class_name BattleModel
extends RefCounted

signal tile_discovered(by_player: bool, cell: Vector2i, kind: int)
signal shot_fired(by_player: bool, cell: Vector2i, actual_damage: int, section_hp: int, ship_hp: int)
signal battle_finished(result: int)
signal economy_changed(by_player: bool)
signal scout_launched(by_player: bool, route: int, cells: Array[Vector2i])
signal ship_repaired(by_player: bool, restored_hp: int)

enum State { RUNNING, VICTORY, DEFEAT }

var state: State = State.RUNNING
var paused := false
var rules: BattleRules
var player_grid: GridModel
var enemy_grid: GridModel
var player_knowledge: GridKnowledge
var enemy_knowledge: GridKnowledge
var player_cannon: CannonModel
var enemy_cannon: CannonModel
var enemy_ai: EnemyAI
var player_scouts: ScoutFleet
var enemy_scouts: ScoutFleet
var player_upgrades: UpgradeState
var enemy_upgrades: UpgradeState
var enemy_scout_decision_remaining := 7.0

func _init(seed_value: int = 0, battle_rules: BattleRules = null) -> void:
	rules = battle_rules if battle_rules != null else BattleRules.new()
	start_battle(seed_value)

func start_battle(seed_value: int = 0) -> void:
	player_grid = GridModel.new()
	enemy_grid = GridModel.new()
	var player_seed := 0 if seed_value == 0 else seed_value * 2 + 1
	var enemy_seed := 0 if seed_value == 0 else seed_value * 2 + 2
	var player_ok := player_grid.generate(rules.grid_size, player_seed, rules.player_shape, rules.treasure_count, rules.island_count, rules.player_section_hp)
	var enemy_ok := enemy_grid.generate(rules.grid_size, enemy_seed, rules.enemy_shape, rules.treasure_count, rules.island_count, rules.enemy_section_hp)
	if not player_ok or not enemy_ok:
		push_error("Could not generate battle grids")
		state = State.DEFEAT
		return
	player_knowledge = GridKnowledge.new(rules.grid_size)
	enemy_knowledge = GridKnowledge.new(rules.grid_size)
	player_cannon = CannonModel.new(rules.cannon_interval, rules.cannon_damage)
	enemy_cannon = CannonModel.new(rules.cannon_interval, rules.cannon_damage)
	enemy_ai = EnemyAI.new(enemy_knowledge, 0 if seed_value == 0 else seed_value * 2 + 3)
	player_scouts = ScoutFleet.new(rules.grid_size, rules.scout_scan_width, rules.scout_travel_time, rules.player_scout_launch_interval, rules.scout_cooldown)
	enemy_scouts = ScoutFleet.new(rules.grid_size, rules.scout_scan_width, rules.scout_travel_time, rules.enemy_scout_launch_interval, rules.scout_cooldown)
	player_upgrades = UpgradeState.new(rules, player_cannon, player_grid.ship, player_scouts)
	enemy_upgrades = UpgradeState.new(rules, enemy_cannon, enemy_grid.ship, enemy_scouts)
	player_upgrades.changed.connect(_emit_economy_changed.bind(true))
	enemy_upgrades.changed.connect(_emit_economy_changed.bind(false))
	player_upgrades.grant_coins(rules.player_starting_coins)
	enemy_upgrades.grant_coins(rules.enemy_starting_coins)
	enemy_scout_decision_remaining = rules.enemy_scout_launch_interval
	state = State.RUNNING
	paused = false

func set_paused(value: bool) -> void:
	paused = value

func player_send_scout(cell: Vector2i) -> bool:
	if paused or state != State.RUNNING:
		return false
	var plan := player_scouts.dispatch_at(cell, player_knowledge)
	if plan.is_empty():
		return false
	var cells: Array[Vector2i] = plan["cells"]
	scout_launched.emit(true, plan["route"], cells)
	return true

func purchase_player(kind: UpgradeState.Kind) -> bool:
	if paused:
		return false
	var before_hp := player_grid.ship.get_total_hp()
	if not player_upgrades.purchase(kind, state == State.RUNNING):
		return false
	if kind == UpgradeState.Kind.REPAIR:
		_sync_repaired_sections(true, player_grid.ship.get_total_hp() - before_hp)
	return true

func _sync_repaired_sections(by_player: bool, restored_hp: int) -> void:
	var ship := player_grid.ship if by_player else enemy_grid.ship
	var opponent_knowledge := enemy_knowledge if by_player else player_knowledge
	for cell: Vector2i in ship.sections.keys():
		if opponent_knowledge.visible_kind(cell) == GridModel.TileKind.SHIP:
			opponent_knowledge.record_section_hp(cell, ship.get_section_hp(cell))
	ship_repaired.emit(by_player, restored_hp)

func _emit_economy_changed(by_player: bool) -> void:
	economy_changed.emit(by_player)

func player_select_target(cell: Vector2i) -> bool:
	if paused or state != State.RUNNING:
		return false
	return player_cannon.select_target(player_knowledge, cell)

func _discover(by_player: bool, cell: Vector2i) -> bool:
	var grid := enemy_grid if by_player else player_grid
	var knowledge := player_knowledge if by_player else enemy_knowledge
	if not grid.is_inside(cell) or knowledge.is_revealed(cell):
		return false
	var kind := grid.reveal(cell)
	if kind == GridModel.TileKind.HIDDEN:
		return false
	knowledge.observe(cell, kind, grid.ship.get_section_hp(cell) if kind == GridModel.TileKind.SHIP else 0)
	tile_discovered.emit(by_player, cell, kind)
	var upgrades := player_upgrades if by_player else enemy_upgrades
	if kind == GridModel.TileKind.TREASURE:
		upgrades.grant_coins(rules.treasure_coins)
	elif kind == GridModel.TileKind.ISLAND:
		upgrades.grant_coins(rules.island_coins)
	return true

func advance(delta: float) -> void:
	if paused or state != State.RUNNING or delta <= 0.0:
		return
	for mission in player_scouts.advance(delta):
		for cell in mission["cells"]:
			_discover(true, cell)
	for mission in enemy_scouts.advance(delta):
		for cell in mission["cells"]:
			_discover(false, cell)
	enemy_scout_decision_remaining -= delta
	if enemy_scout_decision_remaining <= 0.0:
		enemy_scout_decision_remaining = enemy_scouts.launch_interval
		var choice := enemy_ai.choose_scout_target(enemy_scouts)
		if choice.x >= 0:
			var plan := enemy_scouts.dispatch_at(choice, enemy_knowledge)
			if not plan.is_empty():
				var cells: Array[Vector2i] = plan["cells"]
				scout_launched.emit(false, plan["route"], cells)
	# Resolve the player's due shot first. A terminal result prevents the enemy shot.
	if player_cannon.advance(delta, player_knowledge):
		_fire(true)
	if state == State.RUNNING and enemy_cannon.advance(delta, enemy_knowledge):
		_fire(false)
	if state == State.RUNNING:
		_enemy_purchase()

func _enemy_purchase() -> void:
	var damaged := enemy_grid.ship.get_max_hp() - enemy_grid.ship.get_total_hp()
	if damaged >= rules.enemy_repair_threshold:
		var before_hp := enemy_grid.ship.get_total_hp()
		if enemy_upgrades.purchase(UpgradeState.Kind.REPAIR, true):
			_sync_repaired_sections(false, enemy_grid.ship.get_total_hp() - before_hp)
			return
	if enemy_upgrades.purchase(UpgradeState.Kind.DAMAGE, true):
		return
	if enemy_upgrades.purchase(UpgradeState.Kind.SCOUT, true):
		return
	enemy_upgrades.purchase(UpgradeState.Kind.SPEED, true)

func _fire(by_player: bool) -> void:
	if state != State.RUNNING:
		return
	var cannon := player_cannon if by_player else enemy_cannon
	var grid := enemy_grid if by_player else player_grid
	var knowledge := player_knowledge if by_player else enemy_knowledge
	if not cannon.ensure_target(knowledge):
		return
	var cell := cannon.target
	var actual_damage := grid.ship.damage(cell, cannon.damage)
	var section_hp := grid.ship.get_section_hp(cell)
	var ship_hp := grid.ship.get_total_hp()
	knowledge.record_section_hp(cell, section_hp)
	if actual_damage > 0:
		var upgrades := player_upgrades if by_player else enemy_upgrades
		upgrades.grant_coins(actual_damage * rules.damage_coins_per_hp)
	shot_fired.emit(by_player, cell, actual_damage, section_hp, ship_hp)
	cannon.ensure_target(knowledge)
	if ship_hp == 0:
		state = State.VICTORY if by_player else State.DEFEAT
		battle_finished.emit(state)
