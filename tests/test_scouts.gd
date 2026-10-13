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
	var battle := BattleModel.new(212)
	var seen: Array = []
	battle.tile_discovered.connect(func(by_player: bool, cell: Vector2i, kind: int) -> void: seen.append([by_player, cell, kind]))
	_check(battle.player_send_scout(Vector2i(0, 0)), "First scout did not launch")
	_check(battle.player_scouts.pending.size() == 1 and battle.player_scouts.pending[0]["route"] == 0, "North route was not selected")
	_check(battle.player_scouts.pending[0]["cells"].size() == 4, "Scout did not scan a bounded 2x2 area")
	_check(battle.player_knowledge.revealed_count() == 0 and seen.is_empty(), "Scout revealed before arrival")
	_check(not battle.player_send_scout(Vector2i(4, 4)), "Shared launch cooldown did not block another route")
	battle.advance(1.0)
	_check(battle.player_knowledge.revealed_count() == 0, "Scout revealed mid-travel")
	battle.set_paused(true)
	var remaining: float = battle.player_scouts.pending[0]["remaining"]
	battle.advance(100.0)
	_check(is_equal_approx(battle.player_scouts.pending[0]["remaining"], remaining) and not battle.player_send_scout(Vector2i(4, 4)), "Pause advanced or launched scouts")
	battle.set_paused(false)
	battle.advance(0.61)
	_check(battle.player_knowledge.revealed_count() == 4 and seen.size() == 4, "Scout arrival did not reveal exactly four tiles")
	_check(not battle.player_send_scout(Vector2i(0, 0)), "Known cell accepted as scout target")
	battle.advance(2.4)
	_check(battle.player_send_scout(Vector2i(4, 4)), "Different route did not launch after shared cooldown")
	_check(not battle.player_send_scout(Vector2i(2, 0)), "North route cooldown was bypassed")
	var second: Dictionary = battle.player_scouts.pending[0]
	_check(second["route"] == 2, "South route was not selected")
	for cell: Vector2i in second["cells"]:
		_check(cell.y >= 4 and cell.y <= 5, "South scout exceeded route bounds")
	battle.player_upgrades.grant_coins(12)
	var previous_launch := battle.player_scouts.launch_remaining
	var previous_route := battle.player_scouts.cooldowns[2]
	_check(battle.purchase_player(UpgradeState.Kind.SCOUT), "Scout upgrade purchase failed")
	_check(battle.player_upgrades.scout_level == 2 and is_equal_approx(battle.player_scouts.launch_interval, 3.0) and is_equal_approx(battle.player_scouts.scout_cooldown, 9.0), "Scout upgrade tempos wrong")
	_check(is_equal_approx(battle.player_scouts.launch_remaining, previous_launch * 0.75) and is_equal_approx(battle.player_scouts.cooldowns[2], previous_route * 0.75), "Scout upgrade did not preserve cooldown progress")
	_check(not battle.purchase_player(UpgradeState.Kind.SCOUT), "Unaffordable scout upgrade accepted")
	battle.player_upgrades.grant_coins(22)
	_check(battle.purchase_player(UpgradeState.Kind.SCOUT) and battle.player_upgrades.scout_level == 3, "Second scout upgrade failed")
	_check(not battle.purchase_player(UpgradeState.Kind.SCOUT), "Scout maximum level ignored")
	battle.start_battle(212)
	_check(battle.player_knowledge.revealed_count() == 0 and battle.player_scouts.pending.is_empty() and battle.player_upgrades.scout_level == 1, "Restart retained scout state")
	var enemy_choice := battle.enemy_ai.choose_scout_target(battle.enemy_scouts)
	_check(battle.enemy_knowledge.visible_kind(enemy_choice) == GridModel.TileKind.HIDDEN and battle.enemy_scouts.plan_for(enemy_choice, battle.enemy_knowledge)["score"] == 4, "AI scout did not use hidden knowledge view")
	battle.advance(battle.rules.enemy_scout_launch_interval)
	_check(battle.enemy_scouts.pending.size() == 1 and battle.enemy_knowledge.revealed_count() == 0, "Enemy scout did not travel")
	battle.advance(battle.rules.scout_travel_time)
	_check(battle.enemy_knowledge.revealed_count() == 4, "Enemy scout did not reveal area")
	if failures == 0:
		print("PASS: %d scout checks" % checks)
	else:
		print("FAIL: %d of %d scout checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
