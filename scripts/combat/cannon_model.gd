class_name CannonModel
extends RefCounted

var damage: int = 1
var interval: float = 5.0
var remaining: float = 5.0
var target: Vector2i = Vector2i(-1, -1)

func _init(fire_interval: float = 5.0, shot_damage: int = 1) -> void:
	interval = maxf(0.1, fire_interval)
	remaining = interval
	damage = maxi(1, shot_damage)

func set_interval(value: float) -> void:
	var progress := clampf(1.0 - remaining / interval, 0.0, 1.0)
	interval = maxf(0.1, value)
	remaining = maxf(0.01, interval * (1.0 - progress))

func select_target(knowledge: GridKnowledge, cell: Vector2i) -> bool:
	if knowledge.visible_kind(cell) != GridModel.TileKind.SHIP or knowledge.visible_section_hp(cell) <= 0:
		return false
	target = cell
	return true

func ensure_target(knowledge: GridKnowledge) -> bool:
	if knowledge.visible_kind(target) == GridModel.TileKind.SHIP and knowledge.visible_section_hp(target) > 0:
		return true
	var available := knowledge.revealed_living_ship_cells()
	if available.is_empty():
		target = Vector2i(-1, -1)
		remaining = interval
		return false
	target = available[0]
	return true

func advance(delta: float, knowledge: GridKnowledge) -> bool:
	if not ensure_target(knowledge):
		return false
	remaining -= maxf(0.0, delta)
	if remaining > 0.0:
		return false
	remaining = interval
	return true
