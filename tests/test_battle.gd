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
	var unknown := GridKnowledge.new(6)
	var idle_cannon := CannonModel.new()
	_check(not idle_cannon.advance(5.0, unknown), "Cannon fired without a target")
	_check(not idle_cannon.select_target(unknown, Vector2i(0, 0)), "Hidden tile was targetable")
	unknown.observe(Vector2i(0, 0), GridModel.TileKind.WATER)
	_check(not idle_cannon.select_target(unknown, Vector2i(0, 0)), "Water was targetable")
	unknown.observe(Vector2i(1, 0), GridModel.TileKind.SHIP, 0)
	_check(not idle_cannon.select_target(unknown, Vector2i(1, 0)), "Destroyed section was targetable")
	var ai_a := EnemyAI.new(GridKnowledge.new(6), 91)
	var ai_b := EnemyAI.new(GridKnowledge.new(6), 91)
	_check(ai_a.choose_discovery() == ai_b.choose_discovery(), "AI choice depends on hidden grid data")
	var battle := BattleModel.new(42)
	_check(battle.player_grid != battle.enemy_grid, "Sides share a grid")
	_check(battle.player_grid.ship.get_total_hp() == 15 and battle.enemy_grid.ship.get_total_hp() == 15, "Wrong initial HP")
	_check(battle.enemy_ai.knowledge == battle.enemy_knowledge, "AI has wrong knowledge")
	_check(battle.enemy_knowledge.hidden_cells().size() == 36, "Enemy sees a hidden player tile")
	var ai_choice := battle.enemy_ai.choose_discovery()
	_check(battle.enemy_knowledge.visible_kind(ai_choice) == GridModel.TileKind.HIDDEN, "AI did not choose hidden tile")
	var target: Vector2i = battle.enemy_grid.ship.sections.keys()[0]
	_check(battle.player_knowledge.visible_kind(target) == GridModel.TileKind.HIDDEN, "Player view leaked ship")
	_check(not battle.player_select_target(target), "Hidden ship was targetable")
	_check(battle._discover(true, target), "Player could not discover ship")
	_check(battle.player_knowledge.visible_kind(target) == GridModel.TileKind.SHIP, "Found ship not in knowledge")
	_check(not battle._discover(true, target), "Repeated discovery accepted")
	_check(not battle.player_send_scout(Vector2i(-1, -1)), "Out-of-bounds scout accepted")
	_check(battle.player_select_target(target), "Found ship could not be targeted")
	var shots: Array = []
	battle.shot_fired.connect(func(by_player: bool, cell: Vector2i, damage: int, section_hp: int, ship_hp: int) -> void: shots.append([by_player, cell, damage, section_hp, ship_hp]))
	battle.advance(2.5)
	_check(battle.enemy_knowledge.revealed_count() == 0, "Enemy scout launched early")
	_check(battle.player_knowledge.revealed_count() == 1, "Enemy timing changed player knowledge")
	_check(shots.size() == 0, "Cannon fired early")
	battle.advance(2.5)
	_check(shots.size() >= 1 and battle.enemy_grid.ship.get_total_hp() == 14, "Player auto-fire did not damage ship")
	_check(battle.player_knowledge.visible_section_hp(target) == 4, "Shot did not update known section HP")
	var second: Vector2i = battle.enemy_grid.ship.sections.keys()[1]
	_check(battle._discover(true, second), "Second test setup discovery failed")
	_check(battle.player_select_target(second), "Manual target change failed")
	_check(battle.player_cannon.target == second, "Cannon target did not change")
	battle.player_cannon.damage = 9
	battle.player_cannon.remaining = 0.01
	battle.advance(0.01)
	_check(battle.enemy_grid.ship.get_section_hp(second) == 0, "Excess shot did not cap at section HP")
	_check(battle.enemy_grid.ship.get_total_hp() == 9, "Excess shot damaged total HP")
	_check(battle.player_cannon.target == target, "Destroyed target did not retarget")
	var hold := battle.player_cannon.remaining
	var enemy_count := battle.enemy_knowledge.revealed_count()
	battle.set_paused(true)
	battle.advance(100.0)
	_check(battle.player_cannon.remaining == hold and battle.enemy_knowledge.revealed_count() == enemy_count, "Pause accumulated time")
	_check(not battle.player_send_scout(Vector2i(0, 0)), "Scout worked while paused")
	battle.set_paused(false)
	battle.start_battle(42)
	_check(battle.state == BattleModel.State.RUNNING and battle.player_knowledge.revealed_count() == 0, "Restart kept old state")
	_check(battle.player_cannon.target == Vector2i(-1, -1) and battle.enemy_grid.ship.get_total_hp() == 15, "Restart kept old target or HP")
	var quiet := BattleModel.new(13)
	quiet.enemy_scout_decision_remaining = 1000.0
	quiet.advance(5.0)
	_check(quiet.player_grid.ship.get_total_hp() == 15, "Enemy attacked an undiscovered section")

	# Both cannons are due together; the player's killing shot resolves first.
	var tie := BattleModel.new(7)
	var enemy_last: Vector2i = tie.enemy_grid.ship.sections.keys()[0]
	var player_last: Vector2i = tie.player_grid.ship.sections.keys()[0]
	for cell in tie.enemy_grid.ship.sections.keys():
		tie.enemy_grid.ship.damage(cell, 5 if cell != enemy_last else 4)
	for cell in tie.player_grid.ship.sections.keys():
		tie.player_grid.ship.damage(cell, 5 if cell != player_last else 4)
	tie._discover(true, enemy_last)
	tie._discover(false, player_last)
	tie.player_cannon.select_target(tie.player_knowledge, enemy_last)
	tie.enemy_cannon.select_target(tie.enemy_knowledge, player_last)
	tie.player_cannon.remaining = 0.01
	tie.enemy_cannon.remaining = 0.01
	var tie_shots: Array = []
	var results: Array = []
	tie.shot_fired.connect(func(p: bool, c: Vector2i, d: int, s: int, h: int) -> void: tie_shots.append([p, c, d, s, h]))
	tie.battle_finished.connect(func(result: int) -> void: results.append(result))
	tie.advance(0.01)
	_check(tie.state == BattleModel.State.VICTORY and tie_shots.size() == 1 and results.size() == 1, "Player-first tie rule failed")
	tie.advance(100.0)
	_check(tie_shots.size() == 1 and results.size() == 1, "Actions continued after victory")

	var loss := BattleModel.new(9)
	var last: Vector2i = loss.player_grid.ship.sections.keys()[0]
	for cell in loss.player_grid.ship.sections.keys():
		loss.player_grid.ship.damage(cell, 5 if cell != last else 4)
	loss._discover(false, last)
	loss.enemy_cannon.select_target(loss.enemy_knowledge, last)
	loss.enemy_cannon.remaining = 0.01
	loss.advance(0.01)
	_check(loss.state == BattleModel.State.DEFEAT, "Enemy cannot win")

	var full_win := BattleModel.new(21)
	full_win.enemy_scout_decision_remaining = 1000.0
	for cell in full_win.enemy_grid.ship.sections.keys():
		full_win._discover(true, cell)
	for i in 15:
		full_win.advance(5.0)
	_check(full_win.state == BattleModel.State.VICTORY and full_win.enemy_grid.ship.get_total_hp() == 0, "Full automatic battle cannot be won")
	var full_loss := BattleModel.new(22)
	for cell in full_loss.player_grid.ship.sections.keys():
		full_loss._discover(false, cell)
	for i in 15:
		full_loss.advance(5.0)
	_check(full_loss.state == BattleModel.State.DEFEAT and full_loss.player_grid.ship.get_total_hp() == 0, "Full automatic battle cannot be lost")

	if failures == 0:
		print("PASS: %d battle checks" % checks)
	else:
		print("FAIL: %d of %d battle checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
