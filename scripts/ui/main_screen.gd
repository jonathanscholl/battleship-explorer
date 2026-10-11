extends Control

const OCEAN := Color("198ca4")
const DEEP := Color("17667f")
const HIDDEN := Color("255e79")
const FOAM := Color("a5e7da")
const SAND := Color("f7dca1")
const WOOD := Color("ab694a")

var grid := GridModel.new()
var grid_rect := Rect2()
var cell_size := 0.0
var title_label: Label
var progress_label: Label
var hint_label: Label
var discovery_cooldown := 0.0
var last_result := "Tap the sea to explore"

func _ready() -> void:
	if not grid.generate():
		push_error("Could not place ship")
		return
	grid.tile_revealed.connect(_on_tile_revealed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label = _make_label("BATTLESHIP EXPLORER", 24, SAND)
	progress_label = _make_label("0 / 36 found", 16, FOAM)
	hint_label = _make_label(last_result, 17, SAND)
	resized.connect(_update_layout)
	_update_layout()

func _make_label(caption: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _update_layout() -> void:
	var width := size.x
	var height := size.y
	var top_margin := maxf(52.0, height * 0.065)
	var bottom_margin := maxf(50.0, height * 0.06)
	title_label.position = Vector2(16, top_margin)
	title_label.size = Vector2(width - 32, 36)
	progress_label.position = Vector2(16, top_margin + 43)
	progress_label.size = Vector2(width - 32, 28)
	hint_label.position = Vector2(16, height - bottom_margin - 48)
	hint_label.size = Vector2(width - 32, 32)
	var available_height := height - top_margin - bottom_margin - 148
	var grid_size_px := maxf(180.0, minf(width - 28, available_height))
	cell_size = floorf(grid_size_px / grid.grid_size)
	grid_size_px = cell_size * grid.grid_size
	grid_rect = Rect2(Vector2(floorf((width - grid_size_px) / 2.0), floorf((height - grid_size_px) / 2.0) + 16), Vector2(grid_size_px, grid_size_px))
	queue_redraw()

func _process(delta: float) -> void:
	discovery_cooldown = maxf(0.0, discovery_cooldown - delta)

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
	if not grid_rect.has_point(point) or discovery_cooldown > 0.0:
		return
	var local := point - grid_rect.position
	var cell := Vector2i(int(local.x / cell_size), int(local.y / cell_size))
	if grid.is_revealed(cell):
		return
	grid.reveal(cell)
	discovery_cooldown = 0.8
	accept_event()

func _on_tile_revealed(_cell: Vector2i, kind: int) -> void:
	last_result = "Ship spotted!" if kind == GridModel.TileKind.SHIP else "Just water... keep exploring"
	hint_label.text = last_result
	progress_label.text = "%d / %d found" % [grid.get_revealed_count(), grid.grid_size * grid.grid_size]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("104155"))
	if cell_size <= 0.0:
		return
	draw_rect(grid_rect.grow(5), DEEP)
	for y in grid.grid_size:
		for x in grid.grid_size:
			var cell := Vector2i(x, y)
			var rect := Rect2(grid_rect.position + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			draw_rect(rect.grow(-2), OCEAN)
			var kind := grid.visible_kind(cell)
			match kind:
				GridModel.TileKind.HIDDEN:
					draw_rect(rect.grow(-3), HIDDEN)
					draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(cell_size - 14, 4)), Color("467f94"))
					draw_string(ThemeDB.fallback_font, rect.position + Vector2(cell_size * 0.39, cell_size * 0.68), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell_size * 0.43), SAND)
				GridModel.TileKind.WATER:
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.17, cell_size * 0.46), Vector2(cell_size * 0.34, 3)), FOAM)
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.55, cell_size * 0.65), Vector2(cell_size * 0.22, 3)), FOAM)
				GridModel.TileKind.SHIP:
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.16, cell_size * 0.49), Vector2(cell_size * 0.68, cell_size * 0.27)), WOOD)
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.27, cell_size * 0.32), Vector2(cell_size * 0.46, cell_size * 0.19)), SAND)
					draw_rect(Rect2(rect.position + Vector2(cell_size * 0.48, cell_size * 0.18), Vector2(3, cell_size * 0.43)), Color("fff4d0"))
