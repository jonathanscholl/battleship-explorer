class_name LevelDefinition
extends Resource

@export var id := ""
@export var title := ""
@export var grid_size := 6
@export var player_shape: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]
@export var enemy_shape: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]
@export var player_section_hp := 5
@export var enemy_section_hp := 5
@export var player_starting_coins := 0
@export var enemy_starting_coins := 0
@export var treasure_count := 2
@export var island_count := 2
@export var treasure_coins := 10
@export var island_coins := 5
@export var damage_coins_per_hp := 1
@export var scout_scan_width := 2
@export var scout_travel_time := 1.6
@export var scout_cooldown := 12.0
@export var player_scout_launch_interval := 4.0
@export var enemy_scout_launch_interval := 7.0
@export var cannon_interval := 5.0
@export var cannon_damage := 1
@export var damage_values: Array[int] = [1, 2, 3, 4]
@export var speed_values: Array[float] = [5.0, 4.0, 3.0, 2.0]
@export var damage_costs: Array[int] = [8, 16, 28]
@export var speed_costs: Array[int] = [10, 20, 35]
@export var repair_cost := 8
@export var repair_hp := 5
@export var enemy_repair_threshold := 5

func validate() -> String:
	if id.is_empty() or title.is_empty() or grid_size < 3 or grid_size > 10:
		return "Level identity or grid size is invalid"
	if player_section_hp <= 0 or enemy_section_hp <= 0 or player_starting_coins < 0 or enemy_starting_coins < 0:
		return "Ship HP or starting coins are invalid"
	if treasure_count < 0 or island_count < 0 or treasure_coins < 0 or island_coins < 0 or damage_coins_per_hp < 0:
		return "Special tile or reward values are invalid"
	if scout_scan_width < 2 or scout_scan_width > mini(3, grid_size) or scout_travel_time <= 0.0 or scout_cooldown <= 0.0:
		return "Scout range or timing is invalid"
	if player_scout_launch_interval <= 0.0 or enemy_scout_launch_interval <= 0.0 or cannon_interval <= 0.0 or cannon_damage <= 0:
		return "Time interval or cannon damage is invalid"
	if not _shape_fits(player_shape) or not _shape_fits(enemy_shape):
		return "A ship shape is disconnected or cannot fit"
	if maxi(player_shape.size(), enemy_shape.size()) + treasure_count + island_count > grid_size * grid_size:
		return "Special tiles cannot fit beside a ship"
	if damage_values.is_empty() or speed_values.is_empty() or damage_values[0] != cannon_damage or not is_equal_approx(speed_values[0], cannon_interval):
		return "Upgrade starting values do not match the cannon"
	if damage_costs.size() != damage_values.size() - 1 or speed_costs.size() != speed_values.size() - 1:
		return "Upgrade costs do not match their levels"
	for i in damage_values.size():
		if damage_values[i] <= 0 or (i > 0 and damage_values[i] <= damage_values[i - 1]):
			return "Damage levels must increase"
	for i in speed_values.size():
		if speed_values[i] < 0.1 or (i > 0 and speed_values[i] >= speed_values[i - 1]):
			return "Speed levels must decrease within the safe interval"
	for cost in damage_costs:
		if cost <= 0:
			return "Damage costs must be positive"
	for cost in speed_costs:
		if cost <= 0:
			return "Speed costs must be positive"
	if repair_cost <= 0 or repair_hp <= 0 or enemy_repair_threshold <= 0:
		return "Repair values are invalid"
	return ""

func _shape_fits(shape: Array[Vector2i]) -> bool:
	if shape.is_empty():
		return false
	for y in grid_size:
		for x in grid_size:
			for rotation in 4:
				if ShipModel.new().place(shape, Vector2i(x, y), rotation, grid_size, 1):
					return true
	return false

func to_rules() -> BattleRules:
	var rules := BattleRules.new()
	rules.grid_size = grid_size
	rules.player_shape = player_shape.duplicate()
	rules.enemy_shape = enemy_shape.duplicate()
	rules.player_section_hp = player_section_hp
	rules.enemy_section_hp = enemy_section_hp
	rules.player_starting_coins = player_starting_coins
	rules.enemy_starting_coins = enemy_starting_coins
	rules.treasure_count = treasure_count
	rules.island_count = island_count
	rules.treasure_coins = treasure_coins
	rules.island_coins = island_coins
	rules.damage_coins_per_hp = damage_coins_per_hp
	rules.scout_scan_width = scout_scan_width
	rules.scout_travel_time = scout_travel_time
	rules.scout_cooldown = scout_cooldown
	rules.player_scout_launch_interval = player_scout_launch_interval
	rules.enemy_scout_launch_interval = enemy_scout_launch_interval
	rules.cannon_interval = cannon_interval
	rules.cannon_damage = cannon_damage
	rules.damage_values = damage_values.duplicate()
	rules.speed_values = speed_values.duplicate()
	rules.damage_costs = damage_costs.duplicate()
	rules.speed_costs = speed_costs.duplicate()
	rules.repair_cost = repair_cost
	rules.repair_hp = repair_hp
	rules.enemy_repair_threshold = enemy_repair_threshold
	return rules
