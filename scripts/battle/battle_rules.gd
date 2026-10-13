class_name BattleRules
extends RefCounted

var grid_size := 6
var player_shape: Array[Vector2i] = ShipModel.DEFAULT_SHAPE.duplicate()
var enemy_shape: Array[Vector2i] = ShipModel.DEFAULT_SHAPE.duplicate()
var player_section_hp := 5
var enemy_section_hp := 5
var player_starting_coins := 0
var enemy_starting_coins := 0
var treasure_count := 2
var island_count := 2
var treasure_coins := 10
var island_coins := 5
var damage_coins_per_hp := 1
var scout_scan_width := 2
var scout_travel_time := 1.6
var scout_cooldown := 12.0
var player_scout_launch_interval := 4.0
var enemy_scout_launch_interval := 7.0
var cannon_interval := 5.0
var cannon_damage := 1
var damage_values: Array[int] = [1, 2, 3, 4]
var speed_values: Array[float] = [5.0, 4.0, 3.0, 2.0]
var damage_costs: Array[int] = [8, 16, 28]
var speed_costs: Array[int] = [10, 20, 35]
var repair_cost := 8
var repair_hp := 5
var enemy_repair_threshold := 5

var crew_total := 3
var tactical_hp_multiplier := 2
var gun_aim_time := 3.0
var repair_order_time := 4.5
var repair_order_cost := 4
var enemy_order_interval := 3.0
