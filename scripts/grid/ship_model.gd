class_name ShipModel
extends RefCounted

const DEFAULT_SHAPE: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]

var sections: Dictionary = {}
var section_max_hp: int = 5

func place(shape: Array[Vector2i], origin: Vector2i, rotation: int, grid_size: int, hp: int = 5) -> bool:
	if shape.is_empty() or hp <= 0 or grid_size <= 0 or not _is_connected(shape):
		return false
	var candidate: Dictionary = {}
	for offset in shape:
		var rotated := offset
		match posmod(rotation, 4):
			1: rotated = Vector2i(-offset.y, offset.x)
			2: rotated = Vector2i(-offset.x, -offset.y)
			3: rotated = Vector2i(offset.y, -offset.x)
		var cell := origin + rotated
		if cell.x < 0 or cell.y < 0 or cell.x >= grid_size or cell.y >= grid_size or candidate.has(cell):
			return false
		candidate[cell] = hp
	sections = candidate
	section_max_hp = hp
	return true

func _is_connected(shape: Array[Vector2i]) -> bool:
	var remaining: Dictionary = {}
	for cell in shape:
		remaining[cell] = true
	if remaining.size() != shape.size():
		return false
	var frontier: Array[Vector2i] = [shape[0]]
	remaining.erase(shape[0])
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_back()
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = current + step
			if remaining.erase(neighbor):
				frontier.append(neighbor)
	return remaining.is_empty()

func has_section(cell: Vector2i) -> bool:
	return sections.has(cell)

func get_section_hp(cell: Vector2i) -> int:
	return sections.get(cell, 0)

func get_total_hp() -> int:
	var total := 0
	for hp in sections.values():
		total += hp
	return total

func get_max_hp() -> int:
	return sections.size() * section_max_hp

func damage(cell: Vector2i, amount: int) -> int:
	if not sections.has(cell) or amount <= 0:
		return 0
	var dealt: int = mini(amount, sections[cell])
	sections[cell] -= dealt
	return dealt

func repair(amount: int) -> int:
	if amount <= 0:
		return 0
	var restored := 0
	var cells: Array = sections.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for cell in cells:
		if sections[cell] <= 0:
			continue
		var gain: int = mini(amount - restored, section_max_hp - sections[cell])
		sections[cell] += gain
		restored += gain
		if restored == amount:
			return restored
	for cell in cells:
		if sections[cell] != 0:
			continue
		var gain: int = mini(amount - restored, section_max_hp)
		sections[cell] = gain
		restored += gain
		if restored == amount:
			break
	return restored
