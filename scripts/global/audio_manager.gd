extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var is_muted: bool = false

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

func play_sfx_click() -> void:
	# 轻快点击音效
	pass

func set_channel_volumes(music: float, effects: float) -> void:
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = linear_to_db(maxf(0.0001, music))
		bgm_player.stream_paused = music <= 0.0
	if is_instance_valid(sfx_player):
		sfx_player.volume_db = linear_to_db(maxf(0.0001, effects))
		sfx_player.stream_paused = effects <= 0.0

func play_sfx_card_play() -> void:
	# 出牌音效
	pass

func play_sfx_hit() -> void:
	# 击中音效
	pass

func play_sfx_shield() -> void:
	# 防护罩音效
	pass

func play_sfx_victory() -> void:
	# 胜利音效
	pass
