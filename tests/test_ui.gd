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
	print("PASS: touch reveals one tile")
	quit(0)
