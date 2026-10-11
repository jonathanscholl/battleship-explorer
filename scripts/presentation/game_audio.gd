class_name GameAudio
extends Node

const SOUNDS := {
	"discover": preload("res://assets/audio/discover.wav"),
	"splash": preload("res://assets/audio/splash.wav"),
	"ship_found": preload("res://assets/audio/ship_found.wav"),
	"cannon": preload("res://assets/audio/cannon.wav"),
	"impact": preload("res://assets/audio/impact.wav"),
	"treasure": preload("res://assets/audio/treasure.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"purchase": preload("res://assets/audio/purchase.wav"),
	"sink": preload("res://assets/audio/sink.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"defeat": preload("res://assets/audio/defeat.wav"),
}

var unlocked := false
var music_volume := 0.18
var sound_volume := 0.65
var music_player: AudioStreamPlayer
var sound_players: Array[AudioStreamPlayer] = []
var next_player := 0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.stream = preload("res://assets/audio/music.wav")
	music_player.finished.connect(_restart_music)
	add_child(music_player)
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		sound_players.append(player)
	_apply_volumes()

func _exit_tree() -> void:
	music_player.stop()
	music_player.stream = null
	for player in sound_players:
		player.stop()
		player.stream = null

func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	if music_volume > 0.0:
		music_player.play()

func play_sound(name: String) -> void:
	if not unlocked or sound_volume <= 0.0 or not SOUNDS.has(name):
		return
	var player := sound_players[next_player]
	next_player = (next_player + 1) % sound_players.size()
	player.stop()
	player.stream = SOUNDS[name]
	player.play()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	if not unlocked:
		return
	if music_volume == 0.0:
		music_player.stop()
	elif not music_player.playing:
		music_player.play()

func set_sound_volume(value: float) -> void:
	sound_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()

func _restart_music() -> void:
	if unlocked and music_volume > 0.0:
		music_player.play()

func _apply_volumes() -> void:
	if music_player != null:
		music_player.volume_db = -80.0 if music_volume <= 0.0 else linear_to_db(music_volume)
	for player in sound_players:
		player.volume_db = -80.0 if sound_volume <= 0.0 else linear_to_db(sound_volume)
