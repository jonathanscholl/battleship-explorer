class_name LevelProgress
extends RefCounted

const SCHEMA_VERSION := 1
const DEFAULT_PATH := "user://battleship_progress.json"

var catalog: LevelCatalog
var save_path: String
var completed: Array[String] = []
var unlocked: Array[String] = []

func _init(level_catalog: LevelCatalog, path: String = DEFAULT_PATH) -> void:
	catalog = level_catalog
	save_path = path
	_reset()
	load_save()

func _reset() -> void:
	completed.clear()
	unlocked.clear()
	if not catalog.levels.is_empty():
		unlocked.append(catalog.levels[0].id)

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func complete(id: String) -> bool:
	if not is_unlocked(id) or catalog.index_of(id) < 0:
		return false
	if not completed.has(id):
		completed.append(id)
	var next := catalog.next_id(id)
	if not next.is_empty() and not unlocked.has(next):
		unlocked.append(next)
	return save()

func load_save() -> void:
	_reset()
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var parsed: Variant = json.data
	if not parsed is Dictionary or parsed.get("version") != SCHEMA_VERSION:
		return
	var saved_completed: Variant = parsed.get("completed")
	var saved_unlocked: Variant = parsed.get("unlocked")
	if not saved_completed is Array or not saved_unlocked is Array:
		return
	for id in saved_completed:
		if id is String and catalog.index_of(id) >= 0 and not completed.has(id):
			completed.append(id)
	for id in saved_unlocked:
		if id is String and catalog.index_of(id) >= 0 and not unlocked.has(id):
			unlocked.append(id)
	# Never lock a level already completed or the immediate next level.
	for id in completed:
		if not unlocked.has(id):
			unlocked.append(id)
		var next := catalog.next_id(id)
		if not next.is_empty() and not unlocked.has(next):
			unlocked.append(next)

func save() -> bool:
	var absolute := ProjectSettings.globalize_path(save_path)
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SCHEMA_VERSION, "completed": completed, "unlocked": unlocked}))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(temporary, absolute) == OK
