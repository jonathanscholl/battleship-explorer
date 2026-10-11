class_name BattleRules
extends RefCounted

var grid_size := 6
var treasure_count := 2
var island_count := 2
var treasure_coins := 10
var island_coins := 5
var damage_coins_per_hp := 1
var player_discovery_interval := 0.8
var enemy_discovery_interval := 2.5
var cannon_interval := 5.0
var cannon_damage := 1
var damage_values: Array[int] = [1, 2, 3, 4]
var speed_values: Array[float] = [5.0, 4.0, 3.0, 2.0]
var damage_costs: Array[int] = [8, 16, 28]
var speed_costs: Array[int] = [10, 20, 35]
var repair_cost := 8
var repair_hp := 5
var enemy_repair_threshold := 5
