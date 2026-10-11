class_name BattleEffects
extends Control

signal impact_landed

const SPLASH := preload("res://assets/sprites/splash.svg")
const IMPACT := preload("res://assets/sprites/impact.svg")
const CANNONBALL := preload("res://assets/sprites/cannonball.svg")
const COIN := preload("res://assets/sprites/coin.svg")

var generation := 0
var active_tweens: Array[Tween] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear_effects() -> void:
	generation += 1
	for tween in active_tweens:
		if tween.is_running():
			tween.kill()
	active_tweens.clear()
	for child in get_children():
		child.hide()
		child.queue_free()

func spawn_discovery(center: Vector2, kind: int, reward: int = 0) -> void:
	var icon := _sprite(SPLASH if kind == GridModel.TileKind.WATER else IMPACT, center, 30.0)
	icon.modulate = Color("a5e7da") if kind == GridModel.TileKind.WATER else Color.WHITE
	var tween := _new_tween()
	icon.scale = Vector2(0.35, 0.35)
	tween.tween_property(icon, "scale", Vector2.ONE * 1.25, 0.20)
	tween.parallel().tween_property(icon, "modulate:a", 0.0, 0.30)
	tween.finished.connect(func() -> void: if is_instance_valid(icon): icon.queue_free())
	if reward > 0:
		_spawn_float(center + Vector2(0, -12), "+%d" % reward, Color("ffd166"))
		var coin := _sprite(COIN, center + Vector2(12, -12), 16.0)
		var rise := _new_tween()
		rise.tween_property(coin, "position:y", coin.position.y - 22.0, 0.45)
		rise.parallel().tween_property(coin, "modulate:a", 0.0, 0.45)
		rise.finished.connect(func() -> void: if is_instance_valid(coin): coin.queue_free())

func spawn_shot(origin: Vector2, destination: Vector2, damage: int) -> void:
	var ticket := generation
	var flash := _sprite(IMPACT, origin, 27.0)
	var flash_tween := _new_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.16)
	flash_tween.finished.connect(func() -> void: if is_instance_valid(flash): flash.queue_free())
	var ball := _sprite(CANNONBALL, origin, 16.0)
	var travel := _new_tween()
	travel.tween_property(ball, "position", destination - ball.size * 0.5, 0.24)
	travel.finished.connect(func() -> void:
		if not is_instance_valid(ball):
			return
		ball.queue_free()
		if ticket != generation:
			return
		impact_landed.emit()
		var impact := _sprite(IMPACT, destination, 34.0)
		var fade := _new_tween()
		fade.tween_property(impact, "modulate:a", 0.0, 0.30)
		fade.finished.connect(func() -> void: if is_instance_valid(impact): impact.queue_free())
		_spawn_float(destination, "-%d" % damage, Color("fff0bf"))
	)

func spawn_sink(center: Vector2) -> void:
	var splash := _sprite(SPLASH, center, 54.0)
	var tween := _new_tween()
	tween.tween_property(splash, "position:y", splash.position.y + 30.0, 0.42)
	tween.parallel().tween_property(splash, "modulate:a", 0.0, 0.42)
	tween.finished.connect(func() -> void: if is_instance_valid(splash): splash.queue_free())

func _sprite(texture: Texture2D, center: Vector2, side: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2.ONE * side
	icon.position = center - icon.size * 0.5
	icon.pivot_offset = icon.size * 0.5
	add_child(icon)
	return icon

func _spawn_float(center: Vector2, caption: String, color: Color) -> void:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(64, 24)
	label.position = center - Vector2(32, 12)
	add_child(label)
	var tween := _new_tween()
	tween.tween_property(label, "position:y", label.position.y - 25.0, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.finished.connect(func() -> void: if is_instance_valid(label): label.queue_free())

func _new_tween() -> Tween:
	var tween := create_tween()
	active_tweens.append(tween)
	tween.finished.connect(_release_tween.bind(tween))
	return tween

func _release_tween(tween: Tween) -> void:
	active_tweens.erase(tween)
