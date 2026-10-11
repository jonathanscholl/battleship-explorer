class_name GridModel
extends RefCounted

signal tile_revealed(cell: Vector2i, kind: int)

enum TileKind { HIDDEN, WATER, SHIP }

var grid_size: int = 6
var ship := ShipModel.new()
var _revealed: Dictionary = {}

func generate(size: int = 6, seed_value: int = 0, shape: Array[Vector2i] = ShipModel.DEFAULT_SHAPE) -> bool:
	if size <= 0:
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
			if ship.place(shape, origin, rotation, size):
				grid_size = size
				_revealed.clear()
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
	var kind := TileKind.SHIP if ship.has_section(cell) else TileKind.WATER
	tile_revealed.emit(cell, kind)
	return kind

func visible_kind(cell: Vector2i) -> int:
	if not is_inside(cell) or not is_revealed(cell):
		return TileKind.HIDDEN
	return TileKind.SHIP if ship.has_section(cell) else TileKind.WATER

func get_revealed_count() -> int:
	return _revealed.size()
