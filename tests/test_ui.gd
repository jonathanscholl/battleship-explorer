extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var tap := InputEventScreenTouch.new()
	tap.pressed = true
	var grid_rect: Rect2 = screen.get("grid_rect")
	var cell_size: float = screen.get("cell_size")
	tap.position = grid_rect.position + Vector2.ONE * cell_size * 0.5
	screen.call("_gui_input", tap)
	var grid: GridModel = screen.get("grid")
	if grid.get_revealed_count() != 1:
		push_error("Touch did not reveal a tile")
		quit(1)
		return
	screen.call("_gui_input", tap)
	if grid.get_revealed_count() != 1:
		push_error("Repeated touch changed the grid")
		quit(1)
		return
	var battle: BattleModel = screen.get("battle")
	if battle.player_knowledge.revealed_count() != 1 or battle.enemy_knowledge.revealed_count() != 0:
		push_error("Touch changed the wrong grid")
		quit(1)
		return
	var preview: Rect2 = screen.get("preview_rect")
	tap.position = preview.position + preview.size * 0.5
	screen.call("_gui_input", tap)
	if screen.get("showing_enemy") or battle.player_knowledge.revealed_count() != 1:
		push_error("Preview tap did not swap views or changed game state")
		quit(1)
		return
	screen.call("_switch_view")
	if not screen.get("showing_enemy"):
		push_error("View did not switch back")
		quit(1)
		return
	print("PASS: touch discovery and view switching")
	quit(0)
