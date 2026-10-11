class_name BattleModel
extends RefCounted

signal tile_discovered(by_player: bool, cell: Vector2i, kind: int)
signal shot_fired(by_player: bool, cell: Vector2i, actual_damage: int, section_hp: int, ship_hp: int)
signal battle_finished(result: int)

enum State { RUNNING, VICTORY, DEFEAT }

const PLAYER_DISCOVERY_INTERVAL := 0.8
const ENEMY_DISCOVERY_INTERVAL := 2.5

var state: State = State.RUNNING
var paused := false
var player_grid: GridModel
var enemy_grid: GridModel
var player_knowledge: GridKnowledge
var enemy_knowledge: GridKnowledge
var player_cannon: CannonModel
var enemy_cannon: CannonModel
var enemy_ai: EnemyAI
var player_discovery_remaining := 0.0
var enemy_discovery_remaining := ENEMY_DISCOVERY_INTERVAL

func _init(seed_value: int = 0) -> void:
	start_battle(seed_value)

func start_battle(seed_value: int = 0) -> void:
	player_grid = GridModel.new()
	enemy_grid = GridModel.new()
	var player_seed := 0 if seed_value == 0 else seed_value * 2 + 1
	var enemy_seed := 0 if seed_value == 0 else seed_value * 2 + 2
	var player_ok := player_grid.generate(6, player_seed)
	var enemy_ok := enemy_grid.generate(6, enemy_seed)
	if not player_ok or not enemy_ok:
		push_error("Could not generate battle grids")
		state = State.DEFEAT
		return
	player_knowledge = GridKnowledge.new(6)
	enemy_knowledge = GridKnowledge.new(6)
	player_cannon = CannonModel.new()
	enemy_cannon = CannonModel.new()
	enemy_ai = EnemyAI.new(enemy_knowledge, 0 if seed_value == 0 else seed_value * 2 + 3)
	player_discovery_remaining = 0.0
	enemy_discovery_remaining = ENEMY_DISCOVERY_INTERVAL
	state = State.RUNNING
	paused = false

func set_paused(value: bool) -> void:
	paused = value

func player_discover(cell: Vector2i) -> bool:
	if paused or state != State.RUNNING or player_discovery_remaining > 0.0:
		return false
	if not _discover(true, cell):
		return false
	player_discovery_remaining = PLAYER_DISCOVERY_INTERVAL
	return true

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
	return true

func advance(delta: float) -> void:
	if paused or state != State.RUNNING or delta <= 0.0:
		return
	player_discovery_remaining = maxf(0.0, player_discovery_remaining - delta)
	enemy_discovery_remaining -= delta
	if enemy_discovery_remaining <= 0.0:
		enemy_discovery_remaining = ENEMY_DISCOVERY_INTERVAL
		var choice := enemy_ai.choose_discovery()
		if choice.x >= 0:
			_discover(false, choice)
	# Resolve the player's due shot first. A terminal result prevents the enemy shot.
	if player_cannon.advance(delta, player_knowledge):
		_fire(true)
	if state == State.RUNNING and enemy_cannon.advance(delta, enemy_knowledge):
		_fire(false)

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
	knowledge.record_damage(cell, section_hp)
	shot_fired.emit(by_player, cell, actual_damage, section_hp, ship_hp)
	cannon.ensure_target(knowledge)
	if ship_hp == 0:
		state = State.VICTORY if by_player else State.DEFEAT
		battle_finished.emit(state)
