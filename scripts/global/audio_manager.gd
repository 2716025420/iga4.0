extends Node

const SFX_ROOT := "res://assets/audio/sfx/"
const BGM_ROOT := "res://assets/audio/bgm/"
const SFX_POOL_SIZE := 8
const SFX_KEYS := {
	"ui_click": "sfx_ui_click",
	"ui_hover": "sfx_ui_hover",
	"page_flip": "sfx_page_flip",
	"modal_open": "sfx_modal_open",
	"save_chime": "sfx_save_chime",
	"shop_coin": "sfx_shop_coin",
	"card_play": "sfx_card_play",
	"shield_up": "sfx_shield_up",
	"heal": "sfx_heal",
	"debuff_glitch": "sfx_debuff_glitch",
	"counter_reflect": "sfx_counter_reflect",
	"hit_normal": "sfx_hit_normal",
	"hit_overclock": "sfx_hit_overclock",
	"cutin_slash": "sfx_cutin_slash",
	"pack_tear": "sfx_pack_tear",
	"zodiac_resonate": "sfx_zodiac_resonate",
	"victory": "sfx_victory",
}

var bgm_player: AudioStreamPlayer
var bgm_secondary: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _sfx_cache: Dictionary = {}
var _bgm_cache: Dictionary = {}
var _current_bgm_id: String = ""
var _bgm_tween: Tween
var _music_linear: float = 1.0
var _sfx_linear: float = 1.0
var _last_hover_msec: int = 0
var is_muted: bool = false


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

	bgm_secondary = AudioStreamPlayer.new()
	bgm_secondary.bus = "Master"
	add_child(bgm_secondary)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)
	sfx_player = _sfx_pool[0]


func _sfx_stream(key: String) -> AudioStream:
	var stem := str(SFX_KEYS.get(key, key))
	if _sfx_cache.has(stem):
		return _sfx_cache[stem] as AudioStream
	for ext in [".ogg", ".wav", ".mp3"]:
		var path := "%s%s%s" % [SFX_ROOT, stem, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				_sfx_cache[stem] = stream
				return stream
	return null


func _bgm_stream(track_id: String) -> AudioStream:
	if _bgm_cache.has(track_id):
		return _bgm_cache[track_id] as AudioStream
	for ext in [".ogg", ".mp3", ".wav"]:
		var path := "%s%s%s" % [BGM_ROOT, track_id, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				if "loop" in stream:
					stream.set("loop", track_id != "bgm_victory_stinger")
				_bgm_cache[track_id] = stream
				return stream
	return null


func set_channel_volumes(music: float, effects: float) -> void:
	_music_linear = clampf(music, 0.0, 1.0)
	_sfx_linear = clampf(effects, 0.0, 1.0)
	var music_db := linear_to_db(maxf(0.0001, _music_linear))
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = music_db
		bgm_player.stream_paused = _music_linear <= 0.0
	if is_instance_valid(bgm_secondary):
		bgm_secondary.stream_paused = _music_linear <= 0.0
	var sfx_db := linear_to_db(maxf(0.0001, _sfx_linear))
	for player in _sfx_pool:
		if is_instance_valid(player):
			player.volume_db = sfx_db


func play_sfx(key: String, pitch_jitter: float = 0.04, gain_db: float = 0.0) -> void:
	if is_muted or _sfx_linear <= 0.001 or _sfx_pool.is_empty():
		return
	var stream := _sfx_stream(key)
	if stream == null:
		return
	var player := _sfx_pool[_sfx_cursor % _sfx_pool.size()]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = linear_to_db(maxf(0.0001, _sfx_linear)) + gain_db
	player.pitch_scale = 1.0 if pitch_jitter <= 0.0 else randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	if AudioServer.get_driver_name() != "Dummy":
		player.play()


func play_bgm(track_id: String, fade_sec: float = 0.65) -> void:
	if track_id == "" or track_id == _current_bgm_id:
		return
	var next_stream := _bgm_stream(track_id)
	if next_stream == null:
		_current_bgm_id = track_id
		return
	_current_bgm_id = track_id
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
	var old_player := bgm_player
	var new_player := bgm_secondary
	bgm_player = new_player
	bgm_secondary = old_player
	var target_db := linear_to_db(maxf(0.0001, _music_linear))
	new_player.stream = next_stream
	new_player.volume_db = -40.0 if fade_sec > 0.0 else target_db
	new_player.stream_paused = _music_linear <= 0.0
	if AudioServer.get_driver_name() != "Dummy":
		new_player.play()
	if fade_sec <= 0.0:
		old_player.stop()
		return
	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	_bgm_tween.tween_property(new_player, "volume_db", target_db, fade_sec)
	if old_player.playing:
		_bgm_tween.tween_property(old_player, "volume_db", -42.0, fade_sec)
	_bgm_tween.chain().tween_callback(old_player.stop)


func play_bgm_for_scene(scene_type: int, overclock: bool = false, dialogue_id: String = "") -> void:
	match scene_type:
		SceneManager.TargetScene.TITLE:
			play_bgm("bgm_title_serene")
		SceneManager.TargetScene.COMBAT:
			play_bgm("bgm_redmoon_overclock" if overclock else "bgm_duel_practice", 0.45)
		SceneManager.TargetScene.STORY:
			if dialogue_id in ["yang_rescue", "principal_confrontation"]:
				play_bgm("bgm_redmoon_overclock", 0.55)
			elif dialogue_id in ["after_school", "find_yang"] or GameState.archive_dialogue_id != "":
				play_bgm("bgm_dusk_memory", 0.55)
			else:
				play_bgm("bgm_campus_daily", 0.55)
		SceneManager.TargetScene.CAMPUS_LIFE:
			var loc := CampusLife.current_location
			var redmoon := bool(GameState.story_flags.get("prologue_redmoon", false)) or (DayCycle.period() == "night" and GameState.next_phase_two_node() in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"])
			if loc == "shop":
				play_bgm("bgm_shop_breeze", 0.55)
			elif loc == "old_park" or redmoon:
				play_bgm("bgm_dusk_memory", 0.55)
			else:
				play_bgm("bgm_campus_daily", 0.65)
		_:
			play_bgm("bgm_campus_daily", 0.65)


func play_sfx_click() -> void:
	play_sfx("ui_click", 0.05)


func play_sfx_hover() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_hover_msec < 65:
		return
	_last_hover_msec = now
	play_sfx("ui_hover", 0.03, -6.0)


func play_sfx_page_flip() -> void:
	play_sfx("page_flip", 0.04)


func play_sfx_modal_open() -> void:
	play_sfx("modal_open", 0.03)


func play_sfx_save() -> void:
	play_sfx("save_chime", 0.0)


func play_sfx_shop_coin() -> void:
	play_sfx("shop_coin", 0.03)


func play_sfx_card_play() -> void:
	play_sfx("card_play", 0.05)


func play_sfx_hit(overclock: bool = false) -> void:
	play_sfx("hit_overclock" if overclock else "hit_normal", 0.06)


func play_sfx_shield() -> void:
	play_sfx("shield_up", 0.03)


func play_sfx_heal() -> void:
	play_sfx("heal", 0.02)


func play_sfx_debuff() -> void:
	play_sfx("debuff_glitch", 0.04)


func play_sfx_counter_reflect() -> void:
	play_sfx("counter_reflect", 0.04)


func play_sfx_cutin() -> void:
	play_sfx("cutin_slash", 0.03)


func play_sfx_pack_tear() -> void:
	play_sfx("pack_tear", 0.02)


func play_sfx_zodiac() -> void:
	play_sfx("zodiac_resonate", 0.0)


func play_sfx_victory() -> void:
	play_sfx("victory", 0.0)


func _exit_tree() -> void:
	if _bgm_tween != null and _bgm_tween.is_valid():
		_bgm_tween.kill()
		_bgm_tween = null
	for player in [bgm_player, bgm_secondary]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player in _sfx_pool:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_sfx_cache.clear()
	_bgm_cache.clear()
