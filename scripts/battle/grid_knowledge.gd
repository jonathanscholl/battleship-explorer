class_name GridKnowledge
extends RefCounted

var grid_size: int
var _known: Dictionary = {}
var _section_hp: Dictionary = {}

func _init(size: int) -> void:
	grid_size = size

func observe(cell: Vector2i, kind: int, hp: int = 0) -> bool:
	if not is_inside(cell) or _known.has(cell):
		return false
	_known[cell] = kind
	if kind == GridModel.TileKind.SHIP:
		_section_hp[cell] = hp
	return true

func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size

func is_revealed(cell: Vector2i) -> bool:
	return _known.has(cell)

func visible_kind(cell: Vector2i) -> int:
	return _known.get(cell, GridModel.TileKind.HIDDEN)

func visible_section_hp(cell: Vector2i) -> int:
	return _section_hp.get(cell, 0)

func record_damage(cell: Vector2i, hp: int) -> void:
	if _section_hp.has(cell):
		_section_hp[cell] = maxi(0, hp)

func hidden_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in grid_size:
		for x in grid_size:
			var cell := Vector2i(x, y)
			if not _known.has(cell):
				cells.append(cell)
	return cells

func revealed_living_ship_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in grid_size:
		for x in grid_size:
			var cell := Vector2i(x, y)
			if _section_hp.get(cell, 0) > 0:
				cells.append(cell)
	return cells

func revealed_count() -> int:
	return _known.size()
