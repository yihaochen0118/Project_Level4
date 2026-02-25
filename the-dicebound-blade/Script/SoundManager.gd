extends Node
class_name SoundManager

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

var sfx_enabled: bool = true
var bgm_enabled: bool = true
var current_bgm: AudioStream


func _ready():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)


# =========================
# 🎵 BGM
# =========================

func play_bgm(stream: AudioStream, loop := true):
	if not stream:
		return

	if bgm_player.stream == stream:
		return

	current_bgm = stream
	bgm_player.stream = stream
	bgm_player.stream.loop = loop
	bgm_player.play()

	_update_bgm_volume()


func set_bgm_enabled(enabled: bool):
	bgm_enabled = enabled
	_update_bgm_volume()


func set_bgm_volume(value: float):
	bgm_volume = clamp(value, 0.0, 1.0)
	_update_bgm_volume()


func _update_bgm_volume():
	if bgm_enabled:
		bgm_player.volume_db = linear_to_db(bgm_volume)
	else:
		bgm_player.volume_db = -80  # 静音


# =========================
# 🔊 SFX
# =========================

func play_sfx(stream: AudioStream):
	if not stream:
		return

	if not sfx_enabled:
		return

	sfx_player.stream = stream
	sfx_player.volume_db = linear_to_db(sfx_volume)
	sfx_player.play()


func set_sfx_enabled(enabled: bool):
	sfx_enabled = enabled


func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
