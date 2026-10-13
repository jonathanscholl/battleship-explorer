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

func choose_scout_target(fleet: ScoutFleet) -> Vector2i:
	var best_score := 0
	var choices: Array[Vector2i] = []
	for cell in knowledge.hidden_cells():
		var plan := fleet.plan_for(cell, knowledge)
		if plan.is_empty():
			continue
		var score: int = plan["score"]
		if score > best_score:
			best_score = score
			choices.clear()
		if score == best_score:
			choices.append(cell)
	if choices.is_empty():
		return Vector2i(-1, -1)
	return choices[_random.randi_range(0, choices.size() - 1)]
