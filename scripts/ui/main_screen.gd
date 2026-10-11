extends Control

const FOAM := Color("a5e7da")
const SAND := Color("f7dca1")
const DAMAGE := Color("f47e71")
const GOLD := Color("ffd166")
const ISLAND_SPRITE := preload("res://assets/sprites/island.png")
const TREASURE_SPRITE := preload("res://assets/sprites/treasure.png")
const DESTROYED_SPRITE := preload("res://assets/sprites/destroyed.svg")
const COIN_SPRITE := preload("res://assets/sprites/coin.svg")
const OCEAN_BACKGROUND := preload("res://assets/backgrounds/ocean_adventure.png")
const SHIP_V2 := preload("res://assets/sprites/ship-v2.png")
const CANNONBALL_ICON := preload("res://assets/sprites/cannonball.svg")
const STOPWATCH_ICON := preload("res://assets/sprites/stopwatch.svg")
const REPAIR_ICON := preload("res://assets/sprites/repair.svg")
const INK := Color("1b253f")
const PLANK := Color("754329")
const PLANK_LIGHT := Color("b7783e")
const CYAN := Color("40eaff")

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
var result_logo: TextureRect
var retry_button: Button
var next_button: Button
var select_button: Button
var level_overlay: ColorRect
var level_buttons: Array[Button] = []
var level_logo: TextureRect
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
	for texture in [SHIP_V2, ISLAND_SPRITE, TREASURE_SPRITE]:
		sprite_regions[texture] = texture.get_image().get_used_rect()
	enemy_label = _make_label("", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	level_label = _make_label("", 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	coin_label = _make_label("", 22, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	player_label = _make_label("", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label = _make_label("Tap hidden waters to explore", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	view_label = _make_label("ENEMY WATERS", 19, INK, HORIZONTAL_ALIGNMENT_CENTER)
	preview_button = _make_button("<>", _switch_view)
	restart_button = _make_button("RESTART", _restart)
	levels_button = _make_button("LEVELS", _open_level_select)
	settings_button = _make_button("AUDIO", _open_settings)
	damage_button = _make_button("DAMAGE", _buy.bind(UpgradeState.Kind.DAMAGE))
	speed_button = _make_button("SPEED", _buy.bind(UpgradeState.Kind.SPEED))
	repair_button = _make_button("REPAIR", _buy.bind(UpgradeState.Kind.REPAIR))
	_style_button(preview_button, Color("d38b31"), 23)
	for button in [restart_button, levels_button, settings_button]:
		_style_button(button, Color("754329"), 12)
	_style_button(damage_button, Color("e94845"), 14)
	_style_button(speed_button, Color("8a4bdc"), 14)
	_style_button(repair_button, Color("52ae3b"), 14)
	damage_button.icon = CANNONBALL_ICON
	speed_button.icon = STOPWATCH_ICON
	repair_button.icon = REPAIR_ICON
	effects = BattleEffects.new()
	add_child(effects)
	effects.impact_landed.connect(func() -> void: audio.play_sound("impact"))
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0.03, 0.12, 0.20, 0.86)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	add_child(result_overlay)
	result_label = _make_label("", 30, SAND, HORIZONTAL_ALIGNMENT_CENTER, result_overlay)
	retry_button = _make_button("RETRY", _restart, result_overlay)
	next_button = _make_button("NEXT LEVEL", _next_level, result_overlay)
	select_button = _make_button("LEVEL SELECT", _open_level_select, result_overlay)
	for button in [retry_button, next_button, select_button]:
		_style_button(button, PLANK_LIGHT, 17)
	result_logo = _make_logo(result_overlay)
	level_overlay = ColorRect.new()
	level_overlay.color = Color(0.03, 0.13, 0.21, 0.86)
	level_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(level_overlay)
	_make_label("CHOOSE A LEVEL", 28, SAND, HORIZONTAL_ALIGNMENT_CENTER, level_overlay)
	for index in catalog.levels.size():
		var level_button := _make_button("", _start_level.bind(index), level_overlay)
		_style_button(level_button, PLANK_LIGHT, 17)
		level_buttons.append(level_button)
	level_logo = _make_logo(level_overlay)
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
	var done_button := _make_button("DONE", _close_settings, settings_overlay)
	_style_button(done_button, PLANK_LIGHT, 17)
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

func _style_button(button: Button, fill: Color, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("d1d9d9"))
	button.add_theme_color_override("font_outline_color", INK)
	button.add_theme_constant_override("outline_size", 2)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill.darkened(0.24 if state == "pressed" else 0.40 if state == "disabled" else 0.0)
		style.border_color = INK
		style.set_border_width_all(3)
		style.set_corner_radius_all(5)
		style.shadow_color = Color(0.02, 0.10, 0.14, 0.7)
		style.shadow_size = 3
		if state == "hover":
			style.bg_color = fill.lightened(0.12)
		button.add_theme_stylebox_override(state, style)

func _make_slider(value: float, callback: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value * 100.0
	slider.value_changed.connect(func(level: float) -> void: callback.call(level / 100.0))
	settings_overlay.add_child(slider)
	return slider

func _make_logo(parent: Node) -> TextureRect:
	var logo := TextureRect.new()
	logo.texture = SHIP_V2
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(logo)
	return logo

func _update_layout() -> void:
	if battle == null or enemy_label == null:
		return
	var width := size.x
	var height := size.y
	var preview_size := floorf(minf(200.0, width * 0.30))
	preview_rect = Rect2(Vector2(width - preview_size - 15, 118), Vector2.ONE * preview_size)
	enemy_label.position = Vector2(106, 28)
	enemy_label.size = Vector2(width - 235, 24)
	coin_label.position = Vector2(width - 90, 36)
	coin_label.size = Vector2(73, 30)
	level_label.position = Vector2(16, 85)
	level_label.size = Vector2(width - preview_size - 38, 25)
	restart_button.position = Vector2(18, 122)
	restart_button.size = Vector2(103, 31)
	levels_button.position = Vector2(18, 160)
	levels_button.size = Vector2(103, 31)
	settings_button.position = Vector2(18, 198)
	settings_button.size = Vector2(103, 31)
	preview_button.position = Vector2(preview_rect.position.x - 47, 160)
	preview_button.size = Vector2(39, 42)
	var main_top := maxf(preview_rect.end.y + 45, height * 0.31)
	var main_bottom := height - 198
	var available := maxf(180.0, main_bottom - main_top)
	var grid_px := maxf(180.0, minf(width - 34, available))
	cell_size = floorf(grid_px / battle.enemy_grid.grid_size)
	grid_px = cell_size * battle.enemy_grid.grid_size
	grid_rect = Rect2(Vector2(floorf((width - grid_px) / 2.0), floorf(main_top + (available - grid_px) / 2.0)), Vector2.ONE * grid_px)
	view_label.position = Vector2((width - 210) / 2.0, grid_rect.position.y - 38)
	view_label.size = Vector2(210, 31)
	hint_label.position = Vector2(12, height - 194)
	hint_label.size = Vector2(width - 24, 24)
	player_label.position = Vector2(106, height - 154)
	player_label.size = Vector2(width - 125, 28)
	var button_width := (width - 40) / 3.0
	var button_y := height - 99
	damage_button.position = Vector2(12, button_y)
	damage_button.size = Vector2(button_width, 78)
	speed_button.position = Vector2(20 + button_width, button_y)
	speed_button.size = Vector2(button_width, 78)
	repair_button.position = Vector2(28 + button_width * 2.0, button_y)
	repair_button.size = Vector2(button_width, 78)
	result_overlay.position = Vector2.ZERO
	result_overlay.size = size
	result_label.position = Vector2(16, height * 0.39)
	result_label.size = Vector2(width - 32, 48)
	result_logo.position = Vector2((width - 136) / 2.0, height * 0.18)
	result_logo.size = Vector2(136, 136)
	for index in 3:
		var button: Button = [next_button, retry_button, select_button][index]
		button.position = Vector2((width - 208) / 2.0, height * 0.48 + index * 66)
		button.size = Vector2(208, 52)
	level_overlay.position = Vector2.ZERO
	level_overlay.size = size
	var menu_title: Label = level_overlay.get_child(0)
	menu_title.position = Vector2(16, height * 0.22)
	menu_title.size = Vector2(width - 32, 48)
	level_logo.position = Vector2((width - 144) / 2.0, height * 0.045)
	level_logo.size = Vector2(144, 144)
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
	enemy_label.text = "%d/%d" % [battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp()]
	player_label.text = "%d/%d" % [battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp()]
	coin_label.text = "%d" % battle.player_upgrades.coins
	level_label.text = current_level.title.to_upper()
	var upgrades := battle.player_upgrades
	var running := battle.state == BattleModel.State.RUNNING and not battle.paused
	var damage_cost := upgrades.next_cost(UpgradeState.Kind.DAMAGE)
	var speed_cost := upgrades.next_cost(UpgradeState.Kind.SPEED)
	damage_button.text = "DAMAGE +\n%s" % ["MAX" if damage_cost < 0 else "%d GOLD" % damage_cost]
	speed_button.text = "SPEED +\n%s" % ["MAX" if speed_cost < 0 else "%d GOLD" % speed_cost]
	repair_button.text = "REPAIR\n%d GOLD" % upgrades.next_cost(UpgradeState.Kind.REPAIR)
	damage_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.DAMAGE, running)
	speed_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.SPEED, running)
	repair_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.REPAIR, running)

func _draw() -> void:
	draw_texture_rect(OCEAN_BACKGROUND, Rect2(Vector2.ZERO, size), false)
	if battle == null or cell_size <= 0.0:
		return
	_draw_wood_panel(Rect2(13, 21, size.x - 142, 57))
	_draw_wood_panel(Rect2(size.x - 119, 21, 106, 57))
	_draw_sprite(SHIP_V2, Rect2(12, 2, 88, 88))
	_draw_heart(Vector2(113, 62), 11)
	_draw_hp_bar(Vector2(135, 57), size.x - 290, battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp(), Color("f45351"))
	draw_texture_rect(COIN_SPRITE, Rect2(size.x - 111, 34, 29, 29), false)
	_draw_wood_panel(Rect2(14, 84, size.x - preview_rect.size.x - 41, 28), true)
	_draw_wood_panel(Rect2(preview_rect.position.x - 5, preview_rect.position.y - 30, preview_rect.size.x + 10, 27), true)
	draw_string(ThemeDB.fallback_font, Vector2(preview_rect.position.x, preview_rect.position.y - 9), "YOUR WATERS" if showing_enemy else "ENEMY WATERS", HORIZONTAL_ALIGNMENT_CENTER, preview_rect.size.x, 12, INK)
	_draw_wood_panel(Rect2(view_label.position.x - 8, view_label.position.y - 2, view_label.size.x + 16, 32), true)
	_draw_grid_frame(grid_rect, false)
	_draw_grid(grid_rect, showing_enemy)
	_draw_grid_frame(preview_rect, true)
	_draw_grid(preview_rect, not showing_enemy)
	draw_rect(Rect2(20, hint_label.position.y - 1, size.x - 40, 24), Color(0.02, 0.19, 0.30, 0.70))
	_draw_wood_panel(Rect2(13, size.y - 167, size.x - 26, 60))
	_draw_sprite(SHIP_V2, Rect2(13, size.y - 185, 90, 90))
	_draw_heart(Vector2(114, size.y - 127), 11)
	_draw_hp_bar(Vector2(137, size.y - 135), size.x - 230, battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp(), Color("6de94a"))

func _draw_wood_panel(rect: Rect2, parchment: bool = false) -> void:
	draw_rect(rect.grow(3), INK)
	draw_rect(rect, Color("e9bb71") if parchment else PLANK)
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 3)), Color("ffe2a0") if parchment else PLANK_LIGHT)
	draw_rect(rect.grow(-2), Color("71432b"), false, 2)
	for x in [rect.position.x + 8, rect.end.x - 12]:
		draw_circle(Vector2(x, rect.position.y + 12), 2.0, Color("5b332b"))

func _draw_heart(center: Vector2, radius: float) -> void:
	var red := Color("ff5d58")
	draw_circle(center + Vector2(-radius * 0.45, -radius * 0.25), radius * 0.52, INK)
	draw_circle(center + Vector2(radius * 0.45, -radius * 0.25), radius * 0.52, INK)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, -radius * 0.1), center + Vector2(radius, -radius * 0.1), center + Vector2(0, radius)]), INK)
	draw_circle(center + Vector2(-radius * 0.42, -radius * 0.25), radius * 0.38, red)
	draw_circle(center + Vector2(radius * 0.42, -radius * 0.25), radius * 0.38, red)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.78, -radius * 0.1), center + Vector2(radius * 0.78, -radius * 0.1), center + Vector2(0, radius * 0.75)]), red)

func _draw_grid_frame(area: Rect2, small: bool) -> void:
	draw_rect(area.grow(12 if not small else 8), Color("102f50"))
	draw_rect(area.grow(8 if not small else 5), Color("047eae"))
	draw_rect(area.grow(5 if not small else 3), CYAN, false, 2.0)

func _draw_hp_bar(at: Vector2, width: float, hp: int, maximum: int, fill: Color) -> void:
	draw_rect(Rect2(at, Vector2(width, 18)), INK)
	if maximum > 0:
		draw_rect(Rect2(at + Vector2(3, 3), Vector2((width - 6) * float(hp) / maximum, 12)), fill)
		draw_rect(Rect2(at + Vector2(3, 3), Vector2((width - 6) * float(hp) / maximum, 3)), fill.lightened(0.35))

func _draw_grid(area: Rect2, enemy_waters: bool) -> void:
	var knowledge := battle.player_knowledge if enemy_waters else battle.enemy_knowledge
	var own_grid := battle.enemy_grid if enemy_waters else battle.player_grid
	var tile := area.size.x / knowledge.grid_size
	draw_rect(area, Color("0b6593"))
	for y in knowledge.grid_size:
		for x in knowledge.grid_size:
			var cell := Vector2i(x, y)
			var rect := Rect2(area.position + Vector2(x, y) * tile, Vector2.ONE * tile)
			var inset := 2.0 if area == grid_rect else 1.0
			var kind := knowledge.visible_kind(cell)
			var own_ship := not enemy_waters and own_grid.ship.has_section(cell)
			var hidden := kind == GridModel.TileKind.HIDDEN and not own_ship
			draw_rect(rect.grow(-inset), Color("07517f") if hidden else Color("0c9bce"))
			draw_rect(rect.grow(-inset - 1), Color("54eaff"), false, 1.5 if area == grid_rect else 0.7)
			if hidden and area == grid_rect:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.12, tile * 0.16), Vector2(tile * 0.30, 2)), Color("146c99"))
				draw_rect(Rect2(rect.position + Vector2(tile * 0.62, tile * 0.75), Vector2(tile * 0.20, 2)), Color("146c99"))
			if not hidden:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.11, tile * 0.12), Vector2(tile * 0.72, 2)), Color("60dfff", 0.45))
			if kind == GridModel.TileKind.HIDDEN and not own_ship:
				if area == grid_rect:
					draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, tile * 0.70), "?", HORIZONTAL_ALIGNMENT_CENTER, tile, int(tile * 0.50), Color("76c3e1"))
			elif kind == GridModel.TileKind.WATER:
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, tile * 0.75), "×", HORIZONTAL_ALIGNMENT_CENTER, tile, int(tile * 0.64), Color.WHITE)
			elif kind == GridModel.TileKind.TREASURE:
				_draw_sprite(TREASURE_SPRITE, rect.grow(-tile * 0.04))
			elif kind == GridModel.TileKind.ISLAND:
				_draw_sprite(ISLAND_SPRITE, rect.grow(-tile * 0.04))
			elif kind == GridModel.TileKind.SHIP or own_ship:
				var hp := knowledge.visible_section_hp(cell) if enemy_waters else own_grid.ship.get_section_hp(cell)
				if hp <= 0:
					draw_texture_rect(DESTROYED_SPRITE, rect.grow(-tile * 0.1), false)
				else:
					var wave := sin(float(Time.get_ticks_msec()) * 0.002 + float(x + y)) * 0.7 if area == grid_rect else 0.0
					var ship_rect := rect.grow(-tile * 0.015)
					ship_rect.position.y += wave
					_draw_sprite(SHIP_V2, ship_rect, Color("d7fff4") if own_ship else Color.WHITE)
				if area == grid_rect:
					draw_rect(Rect2(rect.position + Vector2(tile * 0.16, tile * 0.88), Vector2(tile * 0.68 * float(hp) / own_grid.ship.section_max_hp, 3)), FOAM if hp > 0 else DAMAGE)
				if own_ship and knowledge.is_revealed(cell):
					draw_rect(rect.grow(-3), DAMAGE, false, 2.0)
			if enemy_waters and battle.player_cannon.target == cell and area == grid_rect:
				var pulse := 0.72 + sin(float(Time.get_ticks_msec()) * 0.008) * 0.28
				var corner := tile * 0.20
				for px in [rect.position.x + 3, rect.end.x - 3]:
					for py in [rect.position.y + 3, rect.end.y - 3]:
						var direction_x := 1.0 if px < rect.get_center().x else -1.0
						var direction_y := 1.0 if py < rect.get_center().y else -1.0
						draw_line(Vector2(px, py), Vector2(px + direction_x * corner, py), Color(1, 0.18, 0.12, pulse), 4)
						draw_line(Vector2(px, py), Vector2(px, py + direction_y * corner), Color(1, 0.18, 0.12, pulse), 4)

func _draw_sprite(texture: Texture2D, destination: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(texture, destination, sprite_regions[texture], tint)
