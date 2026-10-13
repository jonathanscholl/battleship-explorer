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
const PIXEL_FONT := preload("res://assets/fonts/PixelifySans.ttf")
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
var scout_button: Button
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
var menu_button: Button
var pause_overlay: ColorRect
var resume_button: Button
var pause_logo: TextureRect
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
	battle.scout_launched.connect(_on_scout_launched)
	battle.ship_repaired.connect(_on_ship_repaired)
	mouse_filter = Control.MOUSE_FILTER_STOP
	audio = GameAudio.new()
	add_child(audio)
	for texture in [SHIP_V2, ISLAND_SPRITE, TREASURE_SPRITE]:
		sprite_regions[texture] = texture.get_image().get_used_rect()
	enemy_label = _make_label("", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	level_label = _make_label("", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	coin_label = _make_label("", 25, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	player_label = _make_label("", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	hint_label = _make_label("Tap enemy waters to send a scout", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	view_label = _make_label("ENEMY WATERS", 23, Color("372615"), HORIZONTAL_ALIGNMENT_CENTER)
	preview_button = _make_button("SWAP", _switch_view)
	menu_button = _make_button("MENU", _open_pause)
	restart_button = _make_button("RESTART", _restart)
	levels_button = _make_button("LEVELS", _open_level_select)
	settings_button = _make_button("AUDIO", _open_settings)
	damage_button = _make_button("DAMAGE", _buy.bind(UpgradeState.Kind.DAMAGE))
	speed_button = _make_button("SPEED", _buy.bind(UpgradeState.Kind.SPEED))
	repair_button = _make_button("REPAIR", _buy.bind(UpgradeState.Kind.REPAIR))
	scout_button = _make_button("SCOUT +", _buy.bind(UpgradeState.Kind.SCOUT))
	_style_button(scout_button, Color("ca8c36"), 13)
	_style_button(preview_button, Color("d38b31"), 13)
	_style_button(menu_button, Color("754329"), 14)
	for button in [restart_button, levels_button, settings_button]:
		_style_button(button, Color("754329"), 12)
	for button in [damage_button, speed_button, repair_button]:
		_style_upgrade_input(button)
	effects = BattleEffects.new()
	add_child(effects)
	effects.impact_landed.connect(func() -> void: audio.play_sound("impact"))
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.02, 0.10, 0.18, 0.90)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	add_child(pause_overlay)
	_make_label("CAPTAIN'S LOG", 30, SAND, HORIZONTAL_ALIGNMENT_CENTER, pause_overlay)
	for button in [restart_button, levels_button, settings_button]:
		button.reparent(pause_overlay)
		_style_button(button, PLANK_LIGHT, 18)
	resume_button = _make_button("RESUME", _close_pause, pause_overlay)
	_style_button(resume_button, Color("3aaa63"), 18)
	pause_logo = _make_logo(pause_overlay)
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
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _make_button(caption: String, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_font_override("font", PIXEL_FONT)
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

func _style_upgrade_input(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color.TRANSPARENT)

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
	preview_rect = Rect2(Vector2(width - preview_size - 18, 129), Vector2.ONE * preview_size)
	enemy_label.position = Vector2(width - 173, 39)
	enemy_label.size = Vector2(35, 30)
	coin_label.position = Vector2(width - 77, 46)
	coin_label.size = Vector2(56, 32)
	level_label.position = Vector2(19, 107)
	level_label.size = Vector2(88, 25)
	menu_button.position = Vector2(18, 143)
	menu_button.size = Vector2(68, 37)
	scout_button.position = Vector2(112, 189)
	scout_button.size = Vector2(75, 23)
	preview_button.position = Vector2(preview_rect.position.x - 59, 167)
	preview_button.size = Vector2(51, 43)
	var main_top := maxf(preview_rect.end.y + 55, height * 0.31)
	var main_bottom := height - 198
	var available := maxf(180.0, main_bottom - main_top)
	var grid_px := maxf(180.0, minf(width - 40, available))
	cell_size = floorf(grid_px / battle.enemy_grid.grid_size)
	grid_px = cell_size * battle.enemy_grid.grid_size
	grid_rect = Rect2(Vector2(floorf((width - grid_px) / 2.0), floorf(main_top + (available - grid_px) / 2.0)), Vector2.ONE * grid_px)
	view_label.position = Vector2((width - 226) / 2.0, grid_rect.position.y - 38)
	view_label.size = Vector2(226, 30)
	hint_label.position = Vector2(12, height - 194)
	hint_label.size = Vector2(width - 24, 24)
	player_label.position = Vector2(width - 89, height - 143)
	player_label.size = Vector2(69, 27)
	var button_width := (width - 38) / 3.0
	var button_y := height - 100
	damage_button.position = Vector2(12, button_y)
	damage_button.size = Vector2(button_width, 79)
	speed_button.position = Vector2(19 + button_width, button_y)
	speed_button.size = Vector2(button_width, 79)
	repair_button.position = Vector2(26 + button_width * 2.0, button_y)
	repair_button.size = Vector2(button_width, 79)
	pause_overlay.position = Vector2.ZERO
	pause_overlay.size = size
	var pause_title: Label = pause_overlay.get_child(0)
	pause_title.position = Vector2(16, height * 0.225)
	pause_title.size = Vector2(width - 32, 48)
	pause_logo.position = Vector2((width - 148) / 2.0, height * 0.045)
	pause_logo.size = Vector2(148, 148)
	for index in 4:
		var pause_button: Button = [resume_button, restart_button, levels_button, settings_button][index]
		pause_button.position = Vector2(34, height * 0.34 + index * 72)
		pause_button.size = Vector2(width - 68, 58)
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
		battle.set_paused((level_overlay != null and level_overlay.visible) or (settings_overlay != null and settings_overlay.visible) or (pause_overlay != null and pause_overlay.visible))
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
	if level_overlay.visible or result_overlay.visible or settings_overlay.visible or pause_overlay.visible:
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
	elif battle.player_knowledge.is_revealed(cell):
		hint_label.text = "Already charted - choose hidden waters"
	elif battle.player_send_scout(cell):
		pass
	elif battle.player_scouts.launch_remaining > 0.0:
		hint_label.text = "Scout launch ready in %.1fs" % battle.player_scouts.launch_remaining
	elif battle.player_scouts.is_pending(cell):
		hint_label.text = "A scout is already scanning there"
	else:
		hint_label.text = "That route is recharging"
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
	hint_label.text = "Tap enemy waters to send a scout"
	result_overlay.visible = false
	result_overlay.modulate.a = 1.0
	level_overlay.visible = false
	pause_overlay.visible = false
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
	pause_overlay.visible = false
	level_overlay.visible = true
	_update_level_buttons()
	_update_hud()

func _open_settings() -> void:
	audio.unlock()
	battle.set_paused(true)
	pause_overlay.visible = false
	settings_overlay.visible = true
	_update_hud()

func _open_pause() -> void:
	battle.set_paused(true)
	pause_overlay.visible = true
	_update_hud()

func _close_pause() -> void:
	pause_overlay.visible = false
	battle.set_paused(false)
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

func _on_economy_changed(_by_player: bool) -> void:
	_update_hud()

func _on_ship_repaired(by_player: bool, restored_hp: int) -> void:
	if not by_player:
		hint_label.text = "Enemy repaired +%d HP - fire again!" % restored_hp
	_update_hud()
	queue_redraw()

func _on_scout_launched(by_player: bool, route: int, cells: Array[Vector2i]) -> void:
	if by_player:
		audio.play_sound("discover")
		hint_label.text = "%s scout searching %d tiles" % [ScoutFleet.ROUTE_NAMES[route].capitalize(), cells.size()]
	else:
		hint_label.text = "Enemy scout sent toward your waters"
	queue_redraw()

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
	level_label.text = "LEVEL %d" % (catalog.index_of(current_level.id) + 1)
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
	var scout_cost := upgrades.next_cost(UpgradeState.Kind.SCOUT)
	scout_button.text = "MAX" if scout_cost < 0 else "SCOUT %d" % scout_cost
	scout_button.disabled = not upgrades.can_purchase(UpgradeState.Kind.SCOUT, running)

func _draw() -> void:
	draw_texture_rect(OCEAN_BACKGROUND, Rect2(Vector2.ZERO, size), false)
	if battle == null or cell_size <= 0.0:
		return
	_draw_wood_panel(Rect2(14, 21, size.x - 146, 75))
	_draw_wood_panel(Rect2(size.x - 121, 21, 108, 75))
	_draw_sprite(SHIP_V2, Rect2(10, 0, 99, 99))
	draw_string(PIXEL_FONT, Vector2(106, 48), "ENEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe3a1"))
	_draw_heart(Vector2(113, 74), 11)
	_draw_hp_bar(Vector2(133, 65), size.x - 308, battle.enemy_grid.ship.get_total_hp(), battle.enemy_grid.ship.get_max_hp(), Color("f34c4a"))
	draw_texture_rect(COIN_SPRITE, Rect2(size.x - 112, 44, 32, 32), false)
	_draw_wood_panel(Rect2(18, 106, 88, 26), true)
	_draw_wood_panel(Rect2(preview_rect.position.x - 6, preview_rect.position.y - 31, preview_rect.size.x + 12, 28), true)
	draw_string(PIXEL_FONT, Vector2(preview_rect.position.x, preview_rect.position.y - 10), "YOUR WATERS" if showing_enemy else "ENEMY WATERS", HORIZONTAL_ALIGNMENT_CENTER, preview_rect.size.x, 15, Color("372615"))
	_draw_wood_panel(Rect2(view_label.position.x - 8, view_label.position.y - 4, view_label.size.x + 16, 34), true)
	_draw_grid_frame(grid_rect, false)
	_draw_grid(grid_rect, showing_enemy)
	_draw_grid_frame(preview_rect, true)
	_draw_grid(preview_rect, not showing_enemy)
	_draw_scout_status()
	_draw_chamfer(Rect2(25, hint_label.position.y - 3, size.x - 50, 26), Color(0.02, 0.16, 0.25, 0.84), 5)
	_draw_wood_panel(Rect2(14, size.y - 169, size.x - 28, 66))
	_draw_sprite(SHIP_V2, Rect2(11, size.y - 189, 99, 99))
	draw_string(PIXEL_FONT, Vector2(106, size.y - 145), "YOUR SHIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffe3a1"))
	_draw_heart(Vector2(114, size.y - 125), 11)
	_draw_hp_bar(Vector2(134, size.y - 135), size.x - 238, battle.player_grid.ship.get_total_hp(), battle.player_grid.ship.get_max_hp(), Color("6de94a"))
	_draw_upgrade_card(damage_button.get_rect(), Color("ed4741"), Color("a81f31"), "DAMAGE +", battle.player_upgrades.next_cost(UpgradeState.Kind.DAMAGE), CANNONBALL_ICON, damage_button)
	_draw_upgrade_card(speed_button.get_rect(), Color("8d51dc"), Color("593098"), "SPEED +", battle.player_upgrades.next_cost(UpgradeState.Kind.SPEED), STOPWATCH_ICON, speed_button)
	_draw_upgrade_card(repair_button.get_rect(), Color("67c44b"), Color("31813e"), "REPAIR", battle.player_upgrades.next_cost(UpgradeState.Kind.REPAIR), REPAIR_ICON, repair_button)

func _draw_chamfer(rect: Rect2, fill: Color, cut: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		rect.position + Vector2(cut, 0), rect.position + Vector2(rect.size.x - cut, 0),
		rect.position + Vector2(rect.size.x, cut), rect.end - Vector2(0, cut),
		rect.end - Vector2(cut, 0), rect.position + Vector2(cut, rect.size.y),
		rect.position + Vector2(0, rect.size.y - cut), rect.position + Vector2(0, cut)
	]), fill)

func _draw_wood_panel(rect: Rect2, parchment: bool = false) -> void:
	_draw_chamfer(Rect2(rect.position + Vector2(0, 5), rect.size), Color(0.04, 0.10, 0.18, 0.75), 8)
	_draw_chamfer(rect.grow(3), INK, 9)
	_draw_chamfer(rect, Color("f5cf85") if parchment else Color("a65f35"), 7)
	_draw_chamfer(rect.grow(-4), Color("e8b96e") if parchment else PLANK, 5)
	draw_rect(Rect2(rect.position + Vector2(8, 5), Vector2(rect.size.x - 16, 3)), Color("ffe1a1") if parchment else Color("d99551"))
	if not parchment:
		draw_rect(Rect2(rect.position + Vector2(9, rect.size.y - 11), Vector2(rect.size.x - 18, 2)), Color("492b24", 0.65))
	for x in [rect.position.x + 8, rect.end.x - 12]:
		draw_rect(Rect2(x, rect.position.y + 12, 4, 4), Color("6f3a25"))

func _draw_upgrade_card(rect: Rect2, fill: Color, dark: Color, title: String, cost: int, icon: Texture2D, button: Button) -> void:
	_draw_chamfer(Rect2(rect.position + Vector2(0, 5), rect.size), Color("13263c"), 8)
	_draw_chamfer(rect, INK, 8)
	_draw_chamfer(rect.grow(-3), fill.lightened(0.10) if button.is_hovered() else fill, 6)
	draw_rect(Rect2(rect.position + Vector2(7, 6), Vector2(rect.size.x - 14, 4)), fill.lightened(0.36))
	draw_rect(Rect2(rect.position + Vector2(5, rect.size.y - 11), Vector2(rect.size.x - 10, 5)), dark)
	draw_rect(Rect2(rect.position + Vector2(7, 18), Vector2(37, 43)), dark)
	draw_texture_rect(icon, Rect2(rect.position + Vector2(8, 20), Vector2(35, 38)), false)
	draw_string(PIXEL_FONT, rect.position + Vector2(46, 31), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_rect(Rect2(rect.position + Vector2(47, 40), Vector2(rect.size.x - 55, 27)), Color(0.09, 0.13, 0.23, 0.58))
	draw_texture_rect(COIN_SPRITE, Rect2(rect.position + Vector2(49, 45), Vector2(18, 18)), false)
	draw_string(PIXEL_FONT, rect.position + Vector2(67, 61), "MAX" if cost < 0 else "%d" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffedaa") if not button.disabled else Color("ffe4a0"))

func _draw_scout_status() -> void:
	var panel := Rect2(17, 184, 174, 77)
	_draw_chamfer(panel.grow(2), INK, 7)
	_draw_chamfer(panel, Color("173c59"), 5)
	draw_string(PIXEL_FONT, panel.position + Vector2(9, 17), "SCOUTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffde97"))
	var colors := [Color("ffcd64"), Color("6ce9ef"), Color("ff9873")]
	for route in ScoutFleet.ROUTE_NAMES.size():
		var rows := battle.player_scouts.route_rows(route)
		var ready := battle.player_scouts.cooldowns[route] <= 0.0
		var caption := "%s  %d-%d  %s" % [ScoutFleet.ROUTE_NAMES[route].substr(0, 1), rows.x + 1, rows.y + 1, "READY" if ready else "%.0fs" % ceilf(battle.player_scouts.cooldowns[route])]
		var y := panel.position.y + 35 + route * 14
		draw_rect(Rect2(panel.position.x + 8, y - 9, 5, 9), colors[route])
		draw_string(PIXEL_FONT, Vector2(panel.position.x + 18, y), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e6f8ff") if ready else Color("a2b9c8"))
	if battle.player_scouts.launch_remaining > 0.0:
		var progress := 1.0 - battle.player_scouts.launch_remaining / battle.player_scouts.launch_interval
		draw_rect(Rect2(panel.position.x + 7, panel.end.y - 4, (panel.size.x - 14) * progress, 3), Color("ffd76c"))

func _draw_heart(center: Vector2, radius: float) -> void:
	var red := Color("ff5d58")
	draw_circle(center + Vector2(-radius * 0.45, -radius * 0.25), radius * 0.52, INK)
	draw_circle(center + Vector2(radius * 0.45, -radius * 0.25), radius * 0.52, INK)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, -radius * 0.1), center + Vector2(radius, -radius * 0.1), center + Vector2(0, radius)]), INK)
	draw_circle(center + Vector2(-radius * 0.42, -radius * 0.25), radius * 0.38, red)
	draw_circle(center + Vector2(radius * 0.42, -radius * 0.25), radius * 0.38, red)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-radius * 0.78, -radius * 0.1), center + Vector2(radius * 0.78, -radius * 0.1), center + Vector2(0, radius * 0.75)]), red)

func _draw_grid_frame(area: Rect2, small: bool) -> void:
	var margin := 10.0 if not small else 7.0
	_draw_chamfer(area.grow(margin + 4), Color("092b4d"), 14 if not small else 7)
	_draw_chamfer(area.grow(margin), Color("096b9f"), 12 if not small else 5)
	draw_rect(area.grow(5 if not small else 3), Color("28d9ef"), false, 2.0)
	if not small:
		for point in [area.position + Vector2(-8, -8), Vector2(area.end.x + 4, area.position.y - 8), area.end + Vector2(4, 4), Vector2(area.position.x - 8, area.end.y + 4)]:
			draw_rect(Rect2(point, Vector2(5, 5)), Color("b2faff"))

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
			draw_rect(rect.grow(-inset), Color("38e4f6"))
			draw_rect(rect.grow(-inset - 2), Color("07517f") if hidden else Color("0b92ca"))
			draw_rect(Rect2(rect.position + Vector2(inset + 3, inset + 3), Vector2(tile - inset * 2 - 6, 2 if area == grid_rect else 1)), Color("57b9d6") if hidden else Color("7ef5ff"))
			if area == grid_rect:
				draw_rect(Rect2(rect.position + Vector2(inset + 3, inset + 5), Vector2(2, tile - inset * 2 - 10)), Color("2788b0") if hidden else Color("52d2e8"))
			if hidden and area == grid_rect:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.14, tile * 0.18), Vector2(tile * 0.24, 2)), Color("146c99"))
				draw_rect(Rect2(rect.position + Vector2(tile * 0.64, tile * 0.77), Vector2(tile * 0.17, 2)), Color("146c99"))
			if not hidden:
				draw_rect(Rect2(rect.position + Vector2(tile * 0.11, tile * 0.12), Vector2(tile * 0.72, 2)), Color("60dfff", 0.45))
			if kind == GridModel.TileKind.HIDDEN and not own_ship:
				if area == grid_rect:
					draw_string(PIXEL_FONT, rect.position + Vector2(0, tile * 0.70), "?", HORIZONTAL_ALIGNMENT_CENTER, tile, int(tile * 0.53), Color("7bc9e8"))
			elif kind == GridModel.TileKind.WATER:
				var center := rect.get_center()
				var cross := tile * 0.19
				draw_line(center + Vector2(-cross, -cross), center + Vector2(cross, cross), Color.WHITE, maxf(2, tile * 0.065))
				draw_line(center + Vector2(cross, -cross), center + Vector2(-cross, cross), Color.WHITE, maxf(2, tile * 0.065))
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

	_draw_scan_orders(area, enemy_waters)

func _draw_scan_orders(area: Rect2, enemy_waters: bool) -> void:
	var fleet := battle.player_scouts if enemy_waters else battle.enemy_scouts
	var tile := area.size.x / battle.rules.grid_size
	for mission in fleet.pending:
		var cells: Array = mission["cells"]
		var low: Vector2i = cells[0]
		var high: Vector2i = cells[0]
		for cell: Vector2i in cells:
			low = Vector2i(mini(low.x, cell.x), mini(low.y, cell.y))
			high = Vector2i(maxi(high.x, cell.x), maxi(high.y, cell.y))
		var zone := Rect2(area.position + Vector2(low) * tile, Vector2(high - low + Vector2i.ONE) * tile)
		var tint := Color("ffe275") if enemy_waters else Color("ff8a76")
		draw_rect(zone.grow(-3), Color(tint, 0.12))
		draw_rect(zone.grow(-3), tint, false, 3.0 if area == grid_rect else 1.5)
		var progress := 1.0 - float(mission["remaining"]) / fleet.travel_time
		draw_rect(Rect2(zone.position + Vector2(5, 5), Vector2((zone.size.x - 10) * progress, 4)), tint)

func _draw_sprite(texture: Texture2D, destination: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(texture, destination, sprite_regions[texture], tint)
