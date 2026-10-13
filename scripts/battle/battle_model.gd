class_name BattleModel
extends RefCounted

signal tile_discovered(by_player: bool, cell: Vector2i, kind: int)
signal shot_fired(by_player: bool, cell: Vector2i, actual_damage: int, section_hp: int, ship_hp: int)
signal battle_finished(result: int)
signal economy_changed(by_player: bool)
signal scout_launched(by_player: bool, route: int, cells: Array[Vector2i])
signal ship_repaired(by_player: bool, restored_hp: int)

enum State { RUNNING, VICTORY, DEFEAT, SETUP }

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
var tactical_mode := false
var player_crew_busy := 0
var enemy_crew_busy := 0
var player_order: Dictionary = {}
var enemy_order: Dictionary = {}
var enemy_order_remaining := 3.0

func _init(seed_value: int = 0, battle_rules: BattleRules = null, use_tactical_mode: bool = true) -> void:
	tactical_mode = use_tactical_mode
	rules = battle_rules if battle_rules != null else BattleRules.new()
	start_battle(seed_value)

func start_battle(seed_value: int = 0) -> void:
	player_grid = GridModel.new()
	enemy_grid = GridModel.new()
	var player_seed := 0 if seed_value == 0 else seed_value * 2 + 1
	var enemy_seed := 0 if seed_value == 0 else seed_value * 2 + 2
	var player_ok := player_grid.generate(rules.grid_size, player_seed, rules.player_shape, rules.treasure_count, rules.island_count, rules.player_section_hp * (rules.tactical_hp_multiplier if tactical_mode else 1))
	var enemy_ok := enemy_grid.generate(rules.grid_size, enemy_seed, rules.enemy_shape, rules.treasure_count, rules.island_count, rules.enemy_section_hp * (rules.tactical_hp_multiplier if tactical_mode else 1))
	if not player_ok or not enemy_ok:
		push_error("Could not generate battle grids")
		state = State.DEFEAT
		return
	if tactical_mode:
		player_grid.ship.sections.clear()
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
	enemy_order_remaining = rules.enemy_order_interval
	player_crew_busy = 0
	enemy_crew_busy = 0
	player_order.clear()
	enemy_order.clear()
	state = State.SETUP if tactical_mode else State.RUNNING
	paused = false

func set_paused(value: bool) -> void:
	paused = value

func place_player_ship(origin: Vector2i, rotation: int) -> bool:
	if not tactical_mode or state != State.SETUP or paused:
		return false
	return player_grid.relocate_ship(rules.player_shape, origin, rotation, rules.player_section_hp * rules.tactical_hp_multiplier)

func begin_battle() -> bool:
	if not tactical_mode or state != State.SETUP or paused or player_grid.ship.sections.is_empty():
		return false
	state = State.RUNNING
	return true

func player_crew_available() -> int:
	return rules.crew_total - player_crew_busy

func enemy_crew_available() -> int:
	return rules.crew_total - enemy_crew_busy

func player_can_fire() -> bool:
	return tactical_mode and state == State.RUNNING and not paused and player_order.is_empty() and player_crew_available() >= 2 and player_cannon.target.x >= 0 and player_knowledge.visible_kind(player_cannon.target) == GridModel.TileKind.SHIP and player_knowledge.visible_section_hp(player_cannon.target) > 0

func player_order_fire() -> bool:
	if not player_can_fire():
		return false
	player_crew_busy += 2
	player_order = {"kind": "fire", "remaining": rules.gun_aim_time * player_cannon.interval / rules.cannon_interval}
	return true

func player_can_repair() -> bool:
	return tactical_mode and state == State.RUNNING and not paused and player_order.is_empty() and player_crew_available() >= 2 and player_upgrades.coins >= rules.repair_order_cost and player_grid.ship.get_total_hp() > 0 and player_grid.ship.get_total_hp() < player_grid.ship.get_max_hp()

func player_order_repair() -> bool:
	if not player_can_repair() or not player_upgrades.spend_coins(rules.repair_order_cost):
		return false
	player_crew_busy += 2
	player_order = {"kind": "repair", "remaining": rules.repair_order_time}
	return true

func player_send_scout(cell: Vector2i) -> bool:
	if paused or state != State.RUNNING:
		return false
	if tactical_mode and player_crew_available() < 1:
		return false
	var plan := player_scouts.dispatch_at(cell, player_knowledge)
	if plan.is_empty():
		return false
	var cells: Array[Vector2i] = plan["cells"]
	if tactical_mode:
		player_crew_busy += 1
	scout_launched.emit(true, plan["route"], cells)
	return true

func purchase_player(kind: UpgradeState.Kind) -> bool:
	if (paused and not tactical_mode) or (tactical_mode and kind == UpgradeState.Kind.REPAIR):
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
	if tactical_mode:
		_advance_tactical(delta)
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


func _advance_tactical(delta: float) -> void:
	for mission in player_scouts.advance(delta):
		player_crew_busy = maxi(0, player_crew_busy - 1)
		for cell in mission["cells"]:
			_discover(true, cell)
	for mission in enemy_scouts.advance(delta):
		enemy_crew_busy = maxi(0, enemy_crew_busy - 1)
		for cell in mission["cells"]:
			_discover(false, cell)
	_advance_order(true, delta)
	if state != State.RUNNING:
		return
	_advance_order(false, delta)
	if state != State.RUNNING:
		return
	enemy_order_remaining -= delta
	if enemy_order_remaining <= 0.0:
		enemy_order_remaining = rules.enemy_order_interval
		_enemy_tactical_decide()

func _advance_order(by_player: bool, delta: float) -> void:
	var order := player_order if by_player else enemy_order
	if order.is_empty():
		return
	order["remaining"] = float(order["remaining"]) - delta
	if order["remaining"] > 0.0:
		return
	if by_player:
		player_order = {}
		player_crew_busy = maxi(0, player_crew_busy - 2)
	else:
		enemy_order = {}
		enemy_crew_busy = maxi(0, enemy_crew_busy - 2)
	if order["kind"] == "fire":
		_fire(by_player)
	else:
		var ship := player_grid.ship if by_player else enemy_grid.ship
		var restored := ship.repair(rules.repair_hp)
		if restored > 0:
			_sync_repaired_sections(by_player, restored)

func _enemy_tactical_decide() -> void:
	if enemy_order.is_empty() and enemy_crew_available() >= 2:
		var damaged := enemy_grid.ship.get_max_hp() - enemy_grid.ship.get_total_hp()
		if damaged >= rules.enemy_repair_threshold * rules.tactical_hp_multiplier and enemy_upgrades.coins >= rules.repair_order_cost:
			if enemy_upgrades.spend_coins(rules.repair_order_cost):
				enemy_crew_busy += 2
				enemy_order = {"kind": "repair", "remaining": rules.repair_order_time}
		elif enemy_cannon.ensure_target(enemy_knowledge):
			enemy_crew_busy += 2
			enemy_order = {"kind": "fire", "remaining": rules.gun_aim_time * enemy_cannon.interval / rules.cannon_interval}
	if enemy_crew_available() >= 1:
		var choice := enemy_ai.choose_scout_target(enemy_scouts)
		if choice.x >= 0:
			var plan := enemy_scouts.dispatch_at(choice, enemy_knowledge)
			if not plan.is_empty():
				enemy_crew_busy += 1
				var cells: Array[Vector2i] = plan["cells"]
				scout_launched.emit(false, plan["route"], cells)
	if enemy_order.is_empty() and enemy_upgrades.damage_level < rules.damage_values.size():
		enemy_upgrades.purchase(UpgradeState.Kind.DAMAGE, true)

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
