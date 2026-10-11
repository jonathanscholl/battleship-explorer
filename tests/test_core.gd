extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		failures += 1

func _run() -> void:
	var ship := ShipModel.new()
	_check(not ship.place([Vector2i(0, 0), Vector2i(2, 0)], Vector2i(0, 0), 0, 6), "Disconnected ship accepted")
	_check(not ship.place(ShipModel.DEFAULT_SHAPE, Vector2i(5, 5), 0, 6), "Out-of-bounds placement accepted")
	_check(ship.place(ShipModel.DEFAULT_SHAPE, Vector2i(2, 2), 1, 6), "Valid rotated placement rejected")
	_check(ship.sections.size() == 3 and ship.get_total_hp() == 15, "Wrong section count or total HP")
	_check(ship.damage(Vector2i(2, 2), 9) == 5, "Excess damage counted")
	_check(ship.get_total_hp() == 10, "Total HP did not decrease")
	_check(ship.repair(100) == 5 and ship.get_total_hp() == ship.get_max_hp(), "Repair exceeded or missed max HP")
	var grid := GridModel.new()
	_check(grid.generate(6, 12345), "Grid generation failed")
	_check(grid.ship.sections.size() == 3, "Generated ship has wrong size")
	for cell in grid.ship.sections:
		_check(grid.is_inside(cell), "Generated ship outside grid")
		_check(grid.visible_kind(cell) == GridModel.TileKind.HIDDEN, "Hidden ship leaked through visible_kind")
	var target: Vector2i = grid.ship.sections.keys()[0]
	_check(grid.reveal(target) == GridModel.TileKind.SHIP, "Ship discovery failed")
	_check(grid.reveal(target) == GridModel.TileKind.HIDDEN, "Repeat discovery accepted")
	_check(grid.get_revealed_count() == 1, "Repeat discovery changed count")
	_check(grid.reveal(Vector2i(-1, 0)) == GridModel.TileKind.HIDDEN, "Outside tile accepted")
	var water_found := false
	for y in 6:
		for x in 6:
			var cell := Vector2i(x, y)
			if not grid.ship.has_section(cell):
				water_found = grid.reveal(cell) == GridModel.TileKind.WATER
				break
		if water_found:
			break
	_check(water_found, "Water discovery failed")
	if failures == 0:
		print("PASS: %d core checks" % checks)
	else:
		print("FAIL: %d of %d core checks" % [failures, checks])
	quit(1 if failures > 0 else 0)
