class_name LevelCatalog
extends RefCounted

const PATHS: Array[String] = [
	"res://resources/levels/first_encounter.tres",
	"res://resources/levels/pirate_scout.tres",
	"res://resources/levels/pirate_captain.tres",
]

var levels: Array[LevelDefinition] = []

func _init() -> void:
	for path in PATHS:
		var level := load(path) as LevelDefinition
		if level == null or not level.validate().is_empty():
			push_error("Invalid level: %s" % path)
			continue
		levels.append(level)

func index_of(id: String) -> int:
	for i in levels.size():
		if levels[i].id == id:
			return i
	return -1

func next_id(id: String) -> String:
	var index := index_of(id)
	return levels[index + 1].id if index >= 0 and index + 1 < levels.size() else ""
