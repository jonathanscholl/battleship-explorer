extends Control

const OCEAN := Color("198ca4")
const DEEP := Color("17667f")
const HIDDEN := Color("255e79")
const FOAM := Color("a5e7da")
const SAND := Color("f7dca1")
const WOOD := Color("ab694a")
const DAMAGE := Color("f47e71")
const GOLD := Color("ffd166")
const LEAF := Color("65c77a")

var battle: BattleModel
var grid: GridModel # Compatibility for the foundation touch smoke test.
var showing_enemy := true
var grid_rect := Rect2()
var preview_rect := Rect2()
var cell_size := 0.0
var enemy_label: Label
var coin_label: Label
var player_label: Label
var hint_label: Label
var view_label: Label
var preview_button: Button
var restart_button: Button
var damage_button: Button
var speed_button: Button
var repair_button: Button
var result_overlay: ColorRect
var result_label: Label
var retry_button: Button

func _ready() -> void:
	battle = BattleModel.new()
	grid = battle.enemy_grid
	battle.tile_discovered.connect(_on_tile_discovered)
	battle.shot_fired.connect(_on_shot_fired)
	battle.battle_finished.connect(_on_battle_finished)
	battle.economy_changed.connect(_on_economy_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_label = _make_label("ENEMY  15 / 15", 17, SAND, HORIZONTAL_ALIGNMENT_LEFT)
	coin_label = _make_label("0 COINS", 16, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	player_label = _make_label("YOUR SHIP  15 / 15", 17, FOAM, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label = _make_label("Tap hidden waters to explore", 16, SAND, HORIZONTAL_ALIGNMENT_CENTER)
	view_label = _make_label("ENEMY WATERS", 15, FOAM, HORIZONTAL_ALIGNMENT_LEFT)
	preview_button = _make_button("SWAP VIEW", _switch_view)
	restart_button = _make_button("RESTART", _restart)
	damage_button = _make_button("DAMAGE", _buy.bind(UpgradeState.Kind.DAMAGE))
	speed_button = _make_button("SPEED", _buy.bind(UpgradeState.Kind.SPEED))
	repair_button = _make_button("REPAIR", _buy.bind(UpgradeState.Kind.REPAIR))
	for button in [damage_button, speed_button, repair_button]:
		button.add_theme_font_size_override("font_size", 13)
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.03, 0.16, 0.22, 0.90)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	add_child(result_overlay)
	result_label = _make_label("", 30, SAND, HORIZONTAL_ALIGNMENT_CENTER, result_overlay)
	retry_button = _make_button("PLAY AGAIN", _restart, result_overlay)
	resized.connect(_update_layout)
	_update_layout()
	_update_hud()

func _make_label(caption: String, font_size: int, color: Color, alignment: HorizontalAlignment, parent: Node = self) -> Label:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _make_button(caption: String, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _update_layout() -> void:
	if battle == null or enemy_label == null:
		return
	var width := size.x
	var height := size.y
	var top := maxf(42.0, height * 0.055)
	var bottom := maxf(38.0, height * 0.045)
	var preview_size := floorf(minf(96.0, width * 0.25))
	preview_rect = Rect2(Vector2(width - preview_size - 16, top + 82), Vector2.ONE * preview_size)
	enemy_label.position = Vector2(16, top)
	enemy_label.size = Vector2(width - preview_size - 44, 28)
	coin_label.position = Vector2(width - 120, top)
	coin_label.size = Vector2(104, 28)
	restart_button.position = Vector2(16, top + 52)
	restart_button.size = Vector2(96, 36)
	preview_button.position = Vector2(preview_rect.position.x, top + 42)
	preview_button.size = Vector2(preview_size, 36)
	var main_top := preview_rect.end.y + 12
	var main_bottom := height - bottom - 160
	var available := maxf(180.0, main_bottom - main_top)
	var grid_px := maxf(180.0, minf(width - 28, available))
	cell_size = floorf(grid_px / battle.enemy_grid.grid_size)
	grid_px = cell_size * battle.enemy_grid.grid_size
	grid_rect = Rect2(Vector2(floorf((width - grid_px) / 2.0), floorf(main_top + (available - grid_px) / 2.0)), Vector2.ONE * grid_px)
	view_label.position = Vector2(grid_rect.position.x, grid_rect.position.y - 27)
	view_label.size = Vector2(grid_px, 24)
	player_label.position = Vector2(16, height - bottom - 136)
	player_label.size = Vector2(width - 32, 28)
	hint_label.position = Vector2(16, height - bottom - 105)
	hint_label.size = Vector2(width - 32, 30)
	var button_width := (width - 44) / 3.0
	var button_y := height - bottom - 62
	damage_button.position = Vector2(16, button_y)
	damage_button.size = Vector2(button_width, 56)
	speed_button.position = Vector2(22 + button_width, button_y)
	speed_button.size = Vector2(button_width, 56)
	repair_button.position = Vector2(28 + button_width * 2.0, button_y)
	repair_button.size = Vector2(button_width, 56)
	result_overlay.position = Vector2.ZERO
	result_overlay.size = size
	result_label.position = Vector2(16, height * 0.39)
	result_label.size = Vector2(width - 32, 48)
	retry_button.position = Vector2((width - 160) / 2.0, height * 0.49)
	retry_button.size = Vector2(160, 52)
	queue_redraw()

func _process(delta: float) -> void:
	if battle == null:
		return
	battle.advance(delta)
	queue_redraw()

func _notification(what: int) -> void:
	if battle == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		battle.set_paused(true)
		_update_hud()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		battle.set_paused(false)
		_update_hud()

func _gui_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		point = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
		point = event.position
	else:
		return
	if preview_rect.has_point(point):
		_switch_view()
		accept_event()
		return
	if not grid_rect.has_point(point) or not showing_enemy:
		return
	var local := point - grid_rect.position
	var cell := Vector2i(int(local.x / cell_size), int(local.y / cell_size))
	if battle.player_knowledge.visible_kind(cell) == GridModel.TileKind.SHIP:
		if battle.player_select_target(cell):
			hint_label.text = "Cannon target selected"
	elif battle.player_discover(cell):
		pass
	accept_event()
	queue_redraw()

func _switch_view() -> void:
	showing_enemy = not showing_enemy
	view_label.text = "ENEMY WATERS" if showing_enemy else "YOUR WATERS"
	queue_redraw()

func _restart() -> void:
	battle.start_battle()
	grid = battle.enemy_grid
	showing_enemy = true
	view_label.text = "ENEMY WATERS"
	hint_label.text = "Tap hidden waters to explore"
	result_overlay.visible = false
	_update_hud()
	queue_redraw()

func _buy(kind: UpgradeState.Kind) -> void:
	if battle.purchase_player(kind):
		match kind:
			UpgradeState.Kind.DAMAGE: hint_label.text = "Cannon damage upgraded!"
			UpgradeState.Kind.SPEED: hint_label.text = "Cannon fires faster!"
			UpgradeState.Kind.REPAIR: hint_label.text = "Ship repaired!"
		_update_hud()
		queue_redraw()

func _on_tile_discovered(by_player: bool, _cell: Vector2i, kind: int) -> void:
	if by_player:
		match kind:
			GridModel.TileKind.SHIP: hint_label.text = "Ship spotted! Tap to target"
			GridModel.TileKind.TREASURE: hint_label.text = "Treasure! +%d coins" % battle.rules.treasure_coins
			GridModel.TileKind.ISLAND: hint_label.text = "Island! +%d coins" % battle.rules.island_coins
			_: hint_label.text = "Just water... keep exploring"
	elif kind == GridModel.TileKind.SHIP:
		hint_label.text = "Enemy found your ship!"
	queue_redraw()

func _on_shot_fired(by_player: bool, _cell: Vector2i, damage: int, _section_hp: int, _ship_hp: int) -> void:
	hint_label.text = "Hit! -%d HP" % damage if by_player else "Enemy cannon! -%d HP" % damage
	_update_hud()
	queue_redraw()

func _on_battle_finished(result: int) -> void:
	result_label.text = "VICTORY!" if result == BattleModel.State.VICTORY else "SHIP SUNK"
	result_overlay.visible = true
	_update_hud()
	queue_redraw()

func _on_economy_changed(by_player: bool) -> void:
	if by_player:
		_update_hud()

func _update_hud() -> void:
	if enemy_label == null:
		return
	enemy_label.text = "ENEMY  %d / %d" % [battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp()]
	player_label.text = "YOUR SHIP  %d / %d" % [battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp()]
	coin_label.text = "%d COINS" % battle.player_upgrades.coins
	var upgrades := battle.player_upgrades
	var running := battle.state == BattleModel.State.RUNNING and not battle.paused
	var damage_cost := upgrades.next_cost(UpgradeState.Kind.DAMAGE)
	var speed_cost := upgrades.next_cost(UpgradeState.Kind.SPEED)
	damage_button.text = "DAMAGE %d\n%s" % [upgrades.damage_level, "MAX" if damage_cost < 0 else "%d COINS" % damage_cost]
	speed_button.text = "SPEED %ds\n%s" % [int(battle.player_cannon.interval), "MAX" if speed_cost < 0 else "%d COINS" % speed_cost]
	repair_button.text = "REPAIR +%d\n%d COINS" % [battle.rules.repair_hp, upgrades.next_cost(UpgradeState.Kind.REPAIR)]
	damage_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.DAMAGE, running)
	speed_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.SPEED, running)
	repair_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.REPAIR, running)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("104155"))
	if battle == null or cell_size <= 0.0:
		return
	_draw_hp_bar(Vector2(16, enemy_label.position.y + 31), size.x - preview_rect.size.x - 44, battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp(), DAMAGE)
	_draw_hp_bar(Vector2(16, player_label.position.y - 8), size.x - 32, battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp(), FOAM)
	_draw_grid(grid_rect, showing_enemy)
	_draw_grid(preview_rect, not showing_enemy)

func _draw_hp_bar(at: Vector2, width: float, hp: int, maximum: int, fill: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 7)), DEEP)
	if maximum > 0:
		draw_rect(Rect2(at, Vector2(width * float(hp) / maximum, 7)), fill)

func _draw_grid(area: Rect2, enemy_waters: bool) -> void:
	var knowledge := battle.player_knowledge if enemy_waters else battle.enemy_knowledge
	var own_grid := battle.enemy_grid if enemy_waters else battle.player_grid
	var tile := area.size.x / knowledge.grid_size
	draw_rect(area.grow(4), DEEP)
	for y in knowledge.grid_size:
		for x in knowledge.grid_size:
			var cell := Vector2i(x, y)
			var rect := Rect2(area.position + Vector2(x, y) * tile, Vector2.ONE * tile)
			var inset := 2.0 if area == grid_rect else 1.0
			draw_rect(rect.grow(-inset), OCEAN)
			var kind := knowledge.visible_kind(cell)
			var own_ship := not enemy_waters and own_grid.ship.has_section(cell)
			if kind == GridModel.TileKind.HIDDEN and not own_ship:
				draw_rect(rect.grow(-inset - 1), HIDDEN)
				if area == grid_rect:
					draw_string(ThemeDB.fallback_font, rect.position + Vector2(tile * 0.40, tile * 0.68), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(tile * 0.43), SAND)
			elif kind == GridModel.TileKind.WATER and not own_ship:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.17, tile * 0.48), Vector2(tile * 0.35, maxf(2.0, tile * 0.04))), FOAM)
			elif kind == GridModel.TileKind.TREASURE:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.22, tile * 0.43), Vector2(tile * 0.56, tile * 0.36)), WOOD)
				draw_rect(Rect2(rect.position + Vector2(tile * 0.25, tile * 0.34), Vector2(tile * 0.50, tile * 0.16)), GOLD)
				draw_rect(Rect2(rect.position + Vector2(tile * 0.47, tile * 0.47), Vector2(tile * 0.08, tile * 0.20)), GOLD)
			elif kind == GridModel.TileKind.ISLAND:
				draw_circle(rect.get_center(), tile * 0.28, SAND)
				draw_rect(Rect2(rect.position + Vector2(tile * 0.48, tile * 0.28), Vector2(maxf(2.0, tile * 0.06), tile * 0.34)), WOOD)
				draw_circle(rect.position + Vector2(tile * 0.51, tile * 0.29), tile * 0.14, LEAF)
			elif kind == GridModel.TileKind.SHIP or own_ship:
				var hp := knowledge.visible_section_hp(cell) if enemy_waters else own_grid.ship.get_section_hp(cell)
				var hull := WOOD if hp > 0 else Color("584f54")
				draw_rect(Rect2(rect.position + Vector2(tile * 0.16, tile * 0.48), Vector2(tile * 0.68, tile * 0.28)), hull)
				draw_rect(Rect2(rect.position + Vector2(tile * 0.28, tile * 0.28), Vector2(tile * 0.44, tile * 0.20)), SAND if hp > 0 else DAMAGE)
				if area == grid_rect:
					draw_rect(Rect2(rect.position + Vector2(tile * 0.16, tile * 0.83), Vector2(tile * 0.68 * float(hp) / own_grid.ship.section_max_hp, 3)), FOAM if hp > 0 else DAMAGE)
				if own_ship and knowledge.is_revealed(cell):
					draw_rect(rect.grow(-3), DAMAGE, false, 2.0)
			if enemy_waters and battle.player_cannon.target == cell and area == grid_rect:
				draw_rect(rect.grow(-3), SAND, false, 3.0)
