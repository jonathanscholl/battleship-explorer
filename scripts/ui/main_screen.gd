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
const HIDDEN_TILE := preload("res://assets/sprites/water_hidden.svg")
const WATER_TILE := preload("res://assets/sprites/water_revealed.svg")
const SHIP_SPRITE := preload("res://assets/sprites/ship.png")
const ISLAND_SPRITE := preload("res://assets/sprites/island.png")
const TREASURE_SPRITE := preload("res://assets/sprites/treasure.png")
const DESTROYED_SPRITE := preload("res://assets/sprites/destroyed.svg")
const TARGET_SPRITE := preload("res://assets/sprites/target.svg")
const CANNON_SPRITE := preload("res://assets/sprites/cannon.svg")
const COIN_SPRITE := preload("res://assets/sprites/coin.svg")

var battle: BattleModel
var catalog: LevelCatalog
var progress: LevelProgress
var current_level: LevelDefinition
var grid: GridModel # Compatibility for the foundation touch smoke test.
var showing_enemy := true
var grid_rect := Rect2()
var preview_rect := Rect2()
var cell_size := 0.0
var enemy_label: Label
var level_label: Label
var coin_label: Label
var player_label: Label
var hint_label: Label
var view_label: Label
var preview_button: Button
var restart_button: Button
var levels_button: Button
var damage_button: Button
var speed_button: Button
var repair_button: Button
var result_overlay: ColorRect
var result_label: Label
var retry_button: Button
var next_button: Button
var select_button: Button
var level_overlay: ColorRect
var level_buttons: Array[Button] = []
var audio: GameAudio
var effects: BattleEffects
var settings_button: Button
var settings_overlay: ColorRect
var music_slider: HSlider
var sound_slider: HSlider
var transition_tween: Tween
var last_shot_center := Vector2.ZERO
var sprite_regions: Dictionary = {}

func _ready() -> void:
	catalog = LevelCatalog.new()
	progress = LevelProgress.new(catalog)
	current_level = catalog.levels[0]
	battle = BattleModel.new(0, current_level.to_rules())
	grid = battle.enemy_grid
	battle.tile_discovered.connect(_on_tile_discovered)
	battle.shot_fired.connect(_on_shot_fired)
	battle.battle_finished.connect(_on_battle_finished)
	battle.economy_changed.connect(_on_economy_changed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	audio = GameAudio.new()
	add_child(audio)
	for texture in [SHIP_SPRITE, ISLAND_SPRITE, TREASURE_SPRITE]:
		sprite_regions[texture] = texture.get_image().get_used_rect()
	enemy_label = _make_label("ENEMY  15 / 15", 17, SAND, HORIZONTAL_ALIGNMENT_LEFT)
	level_label = _make_label("", 14, FOAM, HORIZONTAL_ALIGNMENT_LEFT)
	coin_label = _make_label("0 COINS", 16, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	player_label = _make_label("YOUR SHIP  15 / 15", 17, FOAM, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label = _make_label("Tap hidden waters to explore", 16, SAND, HORIZONTAL_ALIGNMENT_CENTER)
	view_label = _make_label("ENEMY WATERS", 15, FOAM, HORIZONTAL_ALIGNMENT_LEFT)
	preview_button = _make_button("SWAP VIEW", _switch_view)
	restart_button = _make_button("RESTART", _restart)
	levels_button = _make_button("LEVELS", _open_level_select)
	settings_button = _make_button("AUDIO", _open_settings)
	damage_button = _make_button("DAMAGE", _buy.bind(UpgradeState.Kind.DAMAGE))
	speed_button = _make_button("SPEED", _buy.bind(UpgradeState.Kind.SPEED))
	repair_button = _make_button("REPAIR", _buy.bind(UpgradeState.Kind.REPAIR))
	for button in [damage_button, speed_button, repair_button]:
		button.add_theme_font_size_override("font_size", 13)
	effects = BattleEffects.new()
	add_child(effects)
	effects.impact_landed.connect(func() -> void: audio.play_sound("impact"))
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.03, 0.16, 0.22, 0.90)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	add_child(result_overlay)
	result_label = _make_label("", 30, SAND, HORIZONTAL_ALIGNMENT_CENTER, result_overlay)
	retry_button = _make_button("RETRY", _restart, result_overlay)
	next_button = _make_button("NEXT LEVEL", _next_level, result_overlay)
	select_button = _make_button("LEVEL SELECT", _open_level_select, result_overlay)
	level_overlay = ColorRect.new()
	level_overlay.color = Color(0.03, 0.16, 0.22, 0.97)
	level_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(level_overlay)
	_make_label("CHOOSE A LEVEL", 28, SAND, HORIZONTAL_ALIGNMENT_CENTER, level_overlay)
	for index in catalog.levels.size():
		level_buttons.append(_make_button("", _start_level.bind(index), level_overlay))
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0.03, 0.16, 0.22, 0.97)
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.visible = false
	add_child(settings_overlay)
	_make_label("AUDIO", 28, SAND, HORIZONTAL_ALIGNMENT_CENTER, settings_overlay)
	_make_label("MUSIC", 17, FOAM, HORIZONTAL_ALIGNMENT_LEFT, settings_overlay)
	_make_label("SOUND EFFECTS", 17, FOAM, HORIZONTAL_ALIGNMENT_LEFT, settings_overlay)
	music_slider = _make_slider(audio.music_volume, audio.set_music_volume)
	sound_slider = _make_slider(audio.sound_volume, audio.set_sound_volume)
	_make_button("DONE", _close_settings, settings_overlay)
	battle.set_paused(true)
	resized.connect(_update_layout)
	_update_layout()
	_update_level_buttons()
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

func _make_slider(value: float, callback: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value * 100.0
	slider.value_changed.connect(func(level: float) -> void: callback.call(level / 100.0))
	settings_overlay.add_child(slider)
	return slider

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
	level_label.position = Vector2(16, top + 100)
	level_label.size = Vector2(width - preview_size - 44, 23)
	coin_label.position = Vector2(width - 120, top)
	coin_label.size = Vector2(104, 28)
	restart_button.position = Vector2(16, top + 52)
	restart_button.size = Vector2(96, 36)
	levels_button.position = Vector2(118, top + 52)
	levels_button.size = Vector2(90, 36)
	settings_button.position = Vector2(16, top + 151)
	settings_button.size = Vector2(82, 31)
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
	for index in 3:
		var button: Button = [next_button, retry_button, select_button][index]
		button.position = Vector2((width - 208) / 2.0, height * 0.48 + index * 66)
		button.size = Vector2(208, 52)
	level_overlay.position = Vector2.ZERO
	level_overlay.size = size
	var menu_title: Label = level_overlay.get_child(0)
	menu_title.position = Vector2(16, height * 0.22)
	menu_title.size = Vector2(width - 32, 48)
	for index in level_buttons.size():
		level_buttons[index].position = Vector2(28, height * 0.35 + index * 76)
		level_buttons[index].size = Vector2(width - 56, 60)
	effects.size = size
	settings_overlay.position = Vector2.ZERO
	settings_overlay.size = size
	var settings_title: Label = settings_overlay.get_child(0)
	settings_title.position = Vector2(16, height * 0.25)
	settings_title.size = Vector2(width - 32, 48)
	var music_label: Label = settings_overlay.get_child(1)
	music_label.position = Vector2(32, height * 0.37)
	music_label.size = Vector2(width - 64, 28)
	music_slider.position = Vector2(32, height * 0.42)
	music_slider.size = Vector2(width - 64, 32)
	var sound_label: Label = settings_overlay.get_child(2)
	sound_label.position = Vector2(32, height * 0.51)
	sound_label.size = Vector2(width - 64, 28)
	sound_slider.position = Vector2(32, height * 0.56)
	sound_slider.size = Vector2(width - 64, 32)
	var done_button: Button = settings_overlay.get_child(5)
	done_button.position = Vector2((width - 180) / 2.0, height * 0.69)
	done_button.size = Vector2(180, 52)
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
		battle.set_paused((level_overlay != null and level_overlay.visible) or (settings_overlay != null and settings_overlay.visible))
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
	if level_overlay.visible or result_overlay.visible or settings_overlay.visible:
		return
	audio.unlock()
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
	effects.clear_effects()
	showing_enemy = not showing_enemy
	view_label.text = "ENEMY WATERS" if showing_enemy else "YOUR WATERS"
	queue_redraw()

func _restart() -> void:
	_cancel_transition()
	effects.clear_effects()
	battle.start_battle()
	battle.set_paused(false)
	grid = battle.enemy_grid
	showing_enemy = true
	view_label.text = "ENEMY WATERS"
	hint_label.text = "Tap hidden waters to explore"
	result_overlay.visible = false
	result_overlay.modulate.a = 1.0
	level_overlay.visible = false
	_update_layout()
	_update_hud()
	queue_redraw()

func _start_level(index: int) -> void:
	if index < 0 or index >= catalog.levels.size() or not progress.is_unlocked(catalog.levels[index].id):
		return
	current_level = catalog.levels[index]
	audio.unlock()
	audio.play_sound("discover")
	battle.rules = current_level.to_rules()
	_restart()
	hint_label.text = "%s - set sail!" % current_level.title

func _next_level() -> void:
	var next_id := catalog.next_id(current_level.id)
	if progress.is_unlocked(next_id):
		_start_level(catalog.index_of(next_id))

func _open_level_select() -> void:
	_cancel_transition()
	effects.clear_effects()
	battle.set_paused(true)
	result_overlay.visible = false
	level_overlay.visible = true
	_update_level_buttons()
	_update_hud()

func _open_settings() -> void:
	audio.unlock()
	battle.set_paused(true)
	settings_overlay.visible = true
	_update_hud()

func _close_settings() -> void:
	settings_overlay.visible = false
	battle.set_paused(level_overlay.visible)
	_update_hud()

func _cancel_transition() -> void:
	if transition_tween != null and transition_tween.is_running():
		transition_tween.kill()

func _update_level_buttons() -> void:
	for index in level_buttons.size():
		var level := catalog.levels[index]
		var unlocked := progress.is_unlocked(level.id)
		level_buttons[index].text = "%d  %s%s" % [index + 1, level.title if unlocked else "LOCKED", "  DONE" if progress.completed.has(level.id) else ""]
		level_buttons[index].disabled = not unlocked

func _buy(kind: UpgradeState.Kind) -> void:
	if battle.purchase_player(kind):
		audio.play_sound("purchase")
		match kind:
			UpgradeState.Kind.DAMAGE: hint_label.text = "Cannon damage upgraded!"
			UpgradeState.Kind.SPEED: hint_label.text = "Cannon fires faster!"
			UpgradeState.Kind.REPAIR: hint_label.text = "Ship repaired!"
		_update_hud()
		queue_redraw()

func _on_tile_discovered(by_player: bool, cell: Vector2i, kind: int) -> void:
	var reward := battle.rules.treasure_coins if kind == GridModel.TileKind.TREASURE else battle.rules.island_coins if kind == GridModel.TileKind.ISLAND else 0
	effects.spawn_discovery(_cell_center(by_player, cell), kind, reward if by_player else 0)
	match kind:
		GridModel.TileKind.WATER: audio.play_sound("splash")
		GridModel.TileKind.SHIP: audio.play_sound("ship_found")
		GridModel.TileKind.TREASURE: audio.play_sound("treasure")
		GridModel.TileKind.ISLAND: audio.play_sound("discover")
	if by_player:
		match kind:
			GridModel.TileKind.SHIP: hint_label.text = "Ship spotted! Tap to target"
			GridModel.TileKind.TREASURE: hint_label.text = "Treasure! +%d coins" % battle.rules.treasure_coins
			GridModel.TileKind.ISLAND: hint_label.text = "Island! +%d coins" % battle.rules.island_coins
			_: hint_label.text = "Just water... keep exploring"
	elif kind == GridModel.TileKind.SHIP:
		hint_label.text = "Enemy found your ship!"
	queue_redraw()

func _on_shot_fired(by_player: bool, cell: Vector2i, damage: int, _section_hp: int, _ship_hp: int) -> void:
	last_shot_center = _cell_center(by_player, cell)
	var origin := Vector2(size.x * 0.5, size.y - 155.0) if by_player else Vector2(size.x * 0.5, 74.0)
	effects.spawn_shot(origin, last_shot_center, damage)
	audio.play_sound("cannon")
	hint_label.text = "Hit! -%d HP" % damage if by_player else "Enemy cannon! -%d HP" % damage
	_update_hud()
	queue_redraw()

func _on_battle_finished(result: int) -> void:
	effects.clear_effects()
	effects.spawn_sink(last_shot_center)
	audio.play_sound("sink")
	audio.play_sound("victory" if result == BattleModel.State.VICTORY else "defeat")
	result_label.text = "VICTORY!" if result == BattleModel.State.VICTORY else "SHIP SUNK"
	if result == BattleModel.State.VICTORY:
		progress.complete(current_level.id)
	next_button.visible = result == BattleModel.State.VICTORY and not catalog.next_id(current_level.id).is_empty()
	result_overlay.visible = true
	result_overlay.modulate.a = 0.0
	transition_tween = create_tween()
	transition_tween.tween_property(result_overlay, "modulate:a", 1.0, 0.45)
	_update_hud()
	queue_redraw()

func _on_economy_changed(by_player: bool) -> void:
	if by_player:
		_update_hud()

func _cell_center(by_player: bool, cell: Vector2i) -> Vector2:
	var area := grid_rect if by_player == showing_enemy else preview_rect
	var tile := area.size.x / battle.rules.grid_size
	return area.position + (Vector2(cell) + Vector2.ONE * 0.5) * tile

func _update_hud() -> void:
	if enemy_label == null:
		return
	enemy_label.text = "ENEMY  %d / %d" % [battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp()]
	player_label.text = "YOUR SHIP  %d / %d" % [battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp()]
	coin_label.text = "%d COINS" % battle.player_upgrades.coins
	level_label.text = current_level.title.to_upper()
	var upgrades := battle.player_upgrades
	var running := battle.state == BattleModel.State.RUNNING and not battle.paused
	var damage_cost := upgrades.next_cost(UpgradeState.Kind.DAMAGE)
	var speed_cost := upgrades.next_cost(UpgradeState.Kind.SPEED)
	damage_button.text = "DAMAGE %d\n%s" % [upgrades.damage_level, "MAX" if damage_cost < 0 else "%d COINS" % damage_cost]
	speed_button.text = "SPEED %.1fs\n%s" % [battle.player_cannon.interval, "MAX" if speed_cost < 0 else "%d COINS" % speed_cost]
	repair_button.text = "REPAIR +%d\n%d COINS" % [battle.rules.repair_hp, upgrades.next_cost(UpgradeState.Kind.REPAIR)]
	damage_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.DAMAGE, running)
	speed_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.SPEED, running)
	repair_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.REPAIR, running)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("123e53"))
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color("3b7180"), false, 2.0)
	if battle == null or cell_size <= 0.0:
		return
	draw_texture_rect(COIN_SPRITE, Rect2(Vector2(size.x - 143, coin_label.position.y + 5), Vector2(18, 18)), false)
	draw_texture_rect(CANNON_SPRITE, Rect2(Vector2(grid_rect.end.x - 28, view_label.position.y), Vector2(24, 24)), false)
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
			var kind := knowledge.visible_kind(cell)
			var own_ship := not enemy_waters and own_grid.ship.has_section(cell)
			draw_texture_rect(HIDDEN_TILE if kind == GridModel.TileKind.HIDDEN and not own_ship else WATER_TILE, rect.grow(-inset), false)
			if kind == GridModel.TileKind.HIDDEN and not own_ship:
				if area == grid_rect:
					draw_string(ThemeDB.fallback_font, rect.position + Vector2(tile * 0.40, tile * 0.68), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(tile * 0.43), SAND)
			elif kind == GridModel.TileKind.TREASURE:
				_draw_sprite(TREASURE_SPRITE, rect.grow(-tile * 0.12))
			elif kind == GridModel.TileKind.ISLAND:
				_draw_sprite(ISLAND_SPRITE, rect.grow(-tile * 0.10))
			elif kind == GridModel.TileKind.SHIP or own_ship:
				var hp := knowledge.visible_section_hp(cell) if enemy_waters else own_grid.ship.get_section_hp(cell)
				if hp <= 0:
					draw_texture_rect(DESTROYED_SPRITE, rect.grow(-tile * 0.1), false)
				else:
					var wave := sin(float(Time.get_ticks_msec()) * 0.002 + float(x + y)) * 0.7 if area == grid_rect else 0.0
					var ship_rect := rect.grow(-tile * 0.08)
					ship_rect.position.y += wave
					_draw_sprite(SHIP_SPRITE, ship_rect, Color("d7fff4") if own_ship else Color.WHITE)
				if area == grid_rect:
					draw_rect(Rect2(rect.position + Vector2(tile * 0.16, tile * 0.88), Vector2(tile * 0.68 * float(hp) / own_grid.ship.section_max_hp, 3)), FOAM if hp > 0 else DAMAGE)
				if own_ship and knowledge.is_revealed(cell):
					draw_rect(rect.grow(-3), DAMAGE, false, 2.0)
			if enemy_waters and battle.player_cannon.target == cell and area == grid_rect:
				var pulse := 0.72 + sin(float(Time.get_ticks_msec()) * 0.008) * 0.28
				draw_texture_rect(TARGET_SPRITE, rect.grow(-2), false, Color(1, 1, 1, pulse))

func _draw_sprite(texture: Texture2D, destination: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(texture, destination, sprite_regions[texture], tint)
