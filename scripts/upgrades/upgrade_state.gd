class_name UpgradeState
extends RefCounted

signal changed

enum Kind { DAMAGE, SPEED, REPAIR, SCOUT }

var rules: BattleRules
var cannon: CannonModel
var ship: ShipModel
var scouts: ScoutFleet
var coins := 0
var damage_level := 1
var speed_level := 1
var scout_level := 1
const SCOUT_COSTS := [12, 22]
const SCOUT_TEMPO := [1.0, 0.75, 0.55]

func _init(battle_rules: BattleRules, side_cannon: CannonModel, side_ship: ShipModel, side_scouts: ScoutFleet = null) -> void:
	rules = battle_rules
	cannon = side_cannon
	ship = side_ship
	scouts = side_scouts

func grant_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	changed.emit()

func next_cost(kind: Kind) -> int:
	match kind:
		Kind.DAMAGE:
			return rules.damage_costs[damage_level - 1] if damage_level < rules.damage_values.size() else -1
		Kind.SPEED:
			return rules.speed_costs[speed_level - 1] if speed_level < rules.speed_values.size() else -1
		Kind.REPAIR:
			return rules.repair_cost
		Kind.SCOUT:
			return SCOUT_COSTS[scout_level - 1] if scouts != null and scout_level <= SCOUT_COSTS.size() else -1
	return -1

func can_purchase(kind: Kind, running: bool) -> bool:
	var cost := next_cost(kind)
	if not running or cost < 0 or coins < cost:
		return false
	if kind == Kind.REPAIR:
		return ship.get_total_hp() > 0 and ship.get_total_hp() < ship.get_max_hp()
	return true

func purchase(kind: Kind, running: bool) -> bool:
	if not can_purchase(kind, running):
		return false
	coins -= next_cost(kind)
	match kind:
		Kind.DAMAGE:
			damage_level += 1
			cannon.damage = rules.damage_values[damage_level - 1]
		Kind.SPEED:
			speed_level += 1
			cannon.set_interval(rules.speed_values[speed_level - 1])
		Kind.REPAIR:
			ship.repair(rules.repair_hp)
		Kind.SCOUT:
			scout_level += 1
			scouts.set_tempos(scouts.launch_interval * SCOUT_TEMPO[scout_level - 1] / SCOUT_TEMPO[scout_level - 2], scouts.scout_cooldown * SCOUT_TEMPO[scout_level - 1] / SCOUT_TEMPO[scout_level - 2])
	changed.emit()
	return true
