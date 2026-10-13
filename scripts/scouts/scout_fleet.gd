class_name ScoutFleet
extends RefCounted

const ROUTE_NAMES := ["NORTH", "CENTER", "SOUTH"]

var grid_size: int
var scan_width: int
var travel_time: float
var launch_interval: float
var scout_cooldown: float
var launch_remaining := 0.0
var cooldowns: Array[float] = [0.0, 0.0, 0.0]
var pending: Array[Dictionary] = []

func _init(size: int, width: int, travel: float, launch: float, cooldown: float) -> void:
	grid_size = size
	scan_width = width
	travel_time = travel
	launch_interval = launch
	scout_cooldown = cooldown

func route_rows(route: int) -> Vector2i:
	if route < 0 or route >= ROUTE_NAMES.size():
		return Vector2i(-1, -1)
	var first := int(floor(float(route * grid_size) / 3.0))
	var last := int(ceil(float((route + 1) * grid_size) / 3.0)) - 1
	if last - first + 1 < scan_width:
		if route == 2:
			first = maxi(0, last - scan_width + 1)
		else:
			last = mini(grid_size - 1, first + scan_width - 1)
	return Vector2i(first, last)

func is_pending(cell: Vector2i) -> bool:
	for mission in pending:
		if (mission["cells"] as Array).has(cell):
			return true
	return false

func plan_for(target: Vector2i, knowledge: GridKnowledge) -> Dictionary:
	if launch_remaining > 0.0 or not knowledge.is_inside(target) or knowledge.is_revealed(target) or is_pending(target):
		return {}
	var best: Dictionary = {}
	var best_score := 0
	for route in ROUTE_NAMES.size():
		if cooldowns[route] > 0.0:
			continue
		var rows := route_rows(route)
		if target.y < rows.x or target.y > rows.y:
			continue
		for anchor_y in range(maxi(rows.x, target.y - scan_width + 1), mini(target.y, rows.y - scan_width + 1) + 1):
			for anchor_x in range(maxi(0, target.x - scan_width + 1), mini(target.x, grid_size - scan_width) + 1):
				var cells: Array[Vector2i] = []
				var score := 0
				for dy in scan_width:
					for dx in scan_width:
						var cell := Vector2i(anchor_x + dx, anchor_y + dy)
						cells.append(cell)
						if not knowledge.is_revealed(cell) and not is_pending(cell):
							score += 1
				if score > best_score:
					best_score = score
					best = {"route": route, "cells": cells, "score": score}
	return best

func dispatch_at(target: Vector2i, knowledge: GridKnowledge) -> Dictionary:
	var plan := plan_for(target, knowledge)
	if plan.is_empty():
		return {}
	var route: int = plan["route"]
	launch_remaining = launch_interval
	cooldowns[route] = scout_cooldown
	pending.append({"route": route, "cells": plan["cells"], "remaining": travel_time})
	return plan

func advance(delta: float) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	if delta <= 0.0:
		return completed
	launch_remaining = maxf(0.0, launch_remaining - delta)
	for route in cooldowns.size():
		cooldowns[route] = maxf(0.0, cooldowns[route] - delta)
	for index in range(pending.size() - 1, -1, -1):
		var mission := pending[index]
		mission["remaining"] = float(mission["remaining"]) - delta
		if mission["remaining"] <= 0.0:
			completed.append(mission)
			pending.remove_at(index)
		else:
			pending[index] = mission
	return completed

func set_tempos(new_launch: float, new_cooldown: float) -> void:
	if launch_interval > 0.0:
		launch_remaining = launch_remaining * new_launch / launch_interval
	if scout_cooldown > 0.0:
		for route in cooldowns.size():
			cooldowns[route] = cooldowns[route] * new_cooldown / scout_cooldown
	launch_interval = new_launch
	scout_cooldown = new_cooldown
