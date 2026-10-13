class_name GridModel
extends RefCounted

signal tile_revealed(cell: Vector2i, kind: int)

enum TileKind { HIDDEN, WATER, SHIP, TREASURE, ISLAND }

var grid_size: int = 6
var ship := ShipModel.new()
var _revealed: Dictionary = {}
var _special: Dictionary = {}

func generate(size: int = 6, seed_value: int = 0, shape: Array[Vector2i] = ShipModel.DEFAULT_SHAPE, treasure_count: int = 0, island_count: int = 0, section_hp: int = 5) -> bool:
	if size <= 0 or treasure_count < 0 or island_count < 0 or treasure_count + island_count > size * size - shape.size():
		return false
	var random := RandomNumberGenerator.new()
	if seed_value == 0:
		random.randomize()
	else:
		random.seed = seed_value
	var candidates: Array[Vector2i] = []
	for y in size:
		for x in size:
			candidates.append(Vector2i(x, y))
	_shuffle_with_rng(candidates, random)
	var rotations := [0, 1, 2, 3]
	for i in range(rotations.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var temp: int = rotations[i]
		rotations[i] = rotations[j]
		rotations[j] = temp
	for origin in candidates:
		for rotation in rotations:
			if ship.place(shape, origin, rotation, size, section_hp):
				grid_size = size
				_revealed.clear()
				_special.clear()
				var free: Array[Vector2i] = []
				for cell in candidates:
					if not ship.has_section(cell):
						free.append(cell)
				_shuffle_with_rng(free, random)
				for i in treasure_count:
					_special[free[i]] = TileKind.TREASURE
				for i in island_count:
					_special[free[treasure_count + i]] = TileKind.ISLAND
				return true
	return false

func _shuffle_with_rng(cells: Array[Vector2i], random: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var temp := cells[i]
		cells[i] = cells[j]
		cells[j] = temp

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size

func is_revealed(cell: Vector2i) -> bool:
	return _revealed.has(cell)

func reveal(cell: Vector2i) -> int:
	if not is_inside(cell) or is_revealed(cell):
		return TileKind.HIDDEN
	_revealed[cell] = true
	var kind := _kind_at(cell)
	tile_revealed.emit(cell, kind)
	return kind

func visible_kind(cell: Vector2i) -> int:
	if not is_inside(cell) or not is_revealed(cell):
		return TileKind.HIDDEN
	return _kind_at(cell)

func _kind_at(cell: Vector2i) -> int:
	if ship.has_section(cell):
		return TileKind.SHIP
	return _special.get(cell, TileKind.WATER)

func get_revealed_count() -> int:
	return _revealed.size()

func relocate_ship(shape: Array[Vector2i], origin: Vector2i, rotation: int, hp: int) -> bool:
	if not _revealed.is_empty():
		return false
	var candidate := ShipModel.new()
	if not candidate.place(shape, origin, rotation, grid_size, hp):
		return false
	var displaced: Array[int] = []
	for cell in _special.keys():
		if candidate.has_section(cell):
			displaced.append(_special[cell])
			_special.erase(cell)
	ship.place(shape, origin, rotation, grid_size, hp)
	for kind in displaced:
		for y in grid_size:
			var found := false
			for x in grid_size:
				var cell := Vector2i(x, y)
				if not ship.has_section(cell) and not _special.has(cell):
					_special[cell] = kind
					found = true
					break
			if found:
				break
	return true
