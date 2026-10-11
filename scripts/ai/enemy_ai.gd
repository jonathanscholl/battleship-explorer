class_name EnemyAI
extends RefCounted

var knowledge: GridKnowledge
var _random := RandomNumberGenerator.new()

func _init(opponent_knowledge: GridKnowledge, seed_value: int = 0) -> void:
	knowledge = opponent_knowledge
	if seed_value == 0:
		_random.randomize()
	else:
		_random.seed = seed_value

func choose_discovery() -> Vector2i:
	var hidden := knowledge.hidden_cells()
	if hidden.is_empty():
		return Vector2i(-1, -1)
	return hidden[_random.randi_range(0, hidden.size() - 1)]
