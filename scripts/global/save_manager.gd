class_name SaveService
extends Node

signal save_state_changed
const SAVE_VERSION := 1
var save_path: String = "user://saves/slot_1.json"
var settings_path: String = "user://settings.json"
var active_session: bool = false
var test_session: bool = false
const DEFAULT_SETTINGS := {"master_volume": 0.8, "music_volume": 0.8, "sfx_volume": 0.8, "fullscreen": false, "text_speed": 1, "reduced_motion": false}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var last_error: String = ""
var _pending: bool = false
var _saving: bool = false

func _ready() -> void:
	var saved := _read_json(settings_path)
	settings = _validated_settings(saved)
	_apply_settings()
	SceneManager.scene_transition_completed.connect(request_autosave)
	for signal_name in ["profile_changed", "materials_changed", "deck_changed", "inventory_changed", "exploration_changed", "story_flag_updated", "companion_favor_changed"]:
		GameState.connect(signal_name, request_autosave)

func request_autosave(_arg1: Variant = null, _arg2: Variant = null) -> void:
	if not active_session or _pending or _saving: return
	_pending = true
	_autosave.call_deferred()

func _autosave() -> void:
	_pending = false
	if not active_session or SceneManager.is_transitioning: return
	save_game()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 8388608: return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

func _valid_save(path: String) -> Dictionary:
	var data := _read_json(path)
	var version: Variant = data.get("version", -1)
	if not GameState._whole_number(version) or int(version) != SAVE_VERSION or not data.get("progress") is Dictionary: return {}
	return data if GameState.validate_progress(data["progress"]) else {}

func get_save_metadata(path: String = "") -> Dictionary:
	if path == "": path = save_path
	var data := _valid_save(path)
	var backup := false
	if data.is_empty():
		data = _valid_save(path + ".bak")
		backup = not data.is_empty()
	var progress: Dictionary = data.get("progress", {})
	return {"available": not data.is_empty(), "backup": backup, "saved_at": data.get("saved_at", 0), "day": progress.get("game_day", 1), "hour": progress.get("game_hour", 7), "minute": progress.get("game_minute", 35), "chapter": progress.get("current_chapter_id", ""), "hp": progress.get("player_current_hp", 0)}

func _write_json(path: String, data: Dictionary, backup: bool = false) -> bool:
	if not path.begins_with("user://") or path.contains(".."):
		last_error = "无法保存，请检查存储位置。"
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_error = "无法创建保存目录。"
		return false
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "保存失败，请重试。"
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if backup and not _valid_save(path).is_empty():
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			last_error = "无法保存进度备份。"
			DirAccess.remove_absolute(temporary)
			return false
	if DirAccess.rename_absolute(temporary, absolute) != OK:
		last_error = "保存失败，原进度已保留。"
		DirAccess.remove_absolute(temporary)
		return false
	return true

func save_game() -> bool:
	if not active_session or _saving: return false
	if test_session: return true
	var scene := get_tree().current_scene
	if scene is CombatScreen:
		if scene.result_modal.visible:
			if scene.get("_combat_outcome") != "defeat" or not scene.get("_defeat_settled"): return false
		elif scene.is_animating or not scene.is_player_turn: return false
	_saving = true
	if scene is CombatScreen and not scene.result_modal.visible: scene._save_combat_checkpoint()
	var progress := GameState.export_progress()
	var current := _valid_save(save_path)
	var success := GameState.validate_progress(progress)
	if not success: last_error = "进度校验失败，原有存档已保留。"
	# Compare both sides after JSON numeric normalization, preserving a meaningful backup.
	var normalized: Dictionary = JSON.parse_string(JSON.stringify(progress))
	if success and (current.is_empty() or current["progress"] != normalized):
		success = _write_json(save_path, {"version": SAVE_VERSION, "saved_at": int(Time.get_unix_time_from_system()), "progress": progress}, true)
	_saving = false
	if success: last_error = ""
	save_state_changed.emit()
	return success

func start_new_game() -> bool:
	if not GameState.new_game():
		last_error = "无法开始新游戏。"
		return false
	active_session = true
	test_session = false
	return save_game()

func continue_game() -> bool:
	var data := _valid_save(save_path)
	var recovered := false
	if data.is_empty():
		data = _valid_save(save_path + ".bak")
		recovered = not data.is_empty()
	if data.is_empty() or not GameState.import_progress(data["progress"]):
		last_error = "存档暂时无法读取，可以开始新游戏。"
		return false
	active_session = true
	test_session = false
	last_error = "已从备份恢复进度。" if recovered else ""
	return true

func manual_slot_path(slot: int) -> String:
	return save_path.get_base_dir().path_join("manual_%d.json" % slot) if slot in range(1, 4) else ""

func save_manual_slot(slot: int) -> bool:
	var path := manual_slot_path(slot)
	if path == "" or not active_session or _saving:
		last_error = "当前无法保存进度。"
		return false
	var progress := GameState.export_progress()
	if not GameState.validate_progress(progress):
		last_error = "进度校验失败，原有存档已保留。"
		return false
	var success := _write_json(path, {"version": SAVE_VERSION, "saved_at": int(Time.get_unix_time_from_system()), "progress": progress}, true)
	if success: last_error = ""
	save_state_changed.emit()
	return success

func load_manual_slot(slot: int) -> bool:
	var path := manual_slot_path(slot)
	if path == "": return false
	var data := _valid_save(path)
	var recovered := false
	if data.is_empty():
		data = _valid_save(path + ".bak")
		recovered = not data.is_empty()
	if data.is_empty():
		last_error = "这个存档暂时无法读取。"
		return false
	var was_active := active_session
	active_session = false
	var success := GameState.import_progress(data["progress"])
	active_session = true if success else was_active
	if success: test_session = false
	last_error = ("已从备份恢复进度。" if recovered else "") if success else "这个存档暂时无法读取。"
	return success

func _validated_settings(values: Dictionary) -> Dictionary:
	var result := DEFAULT_SETTINGS.duplicate()
	for key in ["master_volume", "music_volume", "sfx_volume"]:
		var value: Variant = values.get(key)
		if typeof(value) in [TYPE_FLOAT, TYPE_INT] and is_finite(float(value)):
			result[key] = clampf(float(value), 0.0, 1.0)
	for key in ["fullscreen", "reduced_motion"]:
		if values.get(key) is bool: result[key] = values[key]
	if GameState._whole_number(values.get("text_speed")):
		result["text_speed"] = clampi(int(values["text_speed"]), 0, 3)
	return result

func update_settings(values: Dictionary) -> bool:
	var candidate := _validated_settings(values)
	if not _write_json(settings_path, candidate): return false
	settings = candidate
	_apply_settings()
	last_error = ""
	return true

func apply_settings(volume: float, fullscreen: bool) -> bool:
	var candidate := settings.duplicate()
	candidate.merge({"master_volume": volume, "fullscreen": fullscreen}, true)
	return update_settings(candidate)

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(settings["master_volume"]))))
	AudioServer.set_bus_mute(0, float(settings["master_volume"]) <= 0.0)
	AudioManager.set_channel_volumes(float(settings["music_volume"]), float(settings["sfx_volume"]))
	get_window().mode = Window.MODE_FULLSCREEN if settings["fullscreen"] else Window.MODE_WINDOWED

static func build_test_progress() -> Dictionary:
	# Built-in immutable TEST preset: keeps new_game() clean and slot_1 untouched while exposing unlocked test features.
	var test_zodiacs: Array = ["hero", "everyperson", "jester", "caregiver", "ruler", "creator"]
	var test_events := {}
	for id in test_zodiacs:
		test_events["test_seed_" + str(id)] = str(id)
	return {
		"player_max_hp": 150,
		"player_current_hp": 150,
		"scrap_metal": 480,
		"energy_crystals": 1680,
		"energy_drinks": 5,
		"game_day": 3,
		"game_hour": 9,
		"game_minute": 0,
		"game_weekday": DayCycleService.weekday_for_day(3),
		"unlocked_card_ids": ["wrench_smash", "scrap_shield", "icy_soda", "overclock_torch", "fake_cheque", "steel_barricade"],
		"equipped_card_ids": ["wrench_smash", "scrap_shield", "icy_soda", "overclock_torch", "steel_barricade"],
		"card_levels": {"wrench_smash": 2, "scrap_shield": 2, "icy_soda": 1, "overclock_torch": 1, "fake_cheque": 1, "steel_barricade": 1},
		"companions": {
			"yang_zi_ying": {"name": PhaseTwoContent.ACTORS["yang_zi_ying"]["name"], "title": PhaseTwoContent.ACTORS["yang_zi_ying"]["title"], "bio": PhaseTwoContent.ACTORS["yang_zi_ying"]["bio"], "unlocked": true, "favor": 60, "avatar_key": "yang_zi_ying"},
			"liu_yu_long": {"name": PhaseTwoContent.ACTORS["liu_yu_long"]["name"], "title": PhaseTwoContent.ACTORS["liu_yu_long"]["title"], "bio": PhaseTwoContent.ACTORS["liu_yu_long"]["bio"], "unlocked": true, "favor": 40, "avatar_key": "liu_yu_long"},
			"jiang_zi": {"name": PhaseTwoContent.ACTORS["jiang_zi"]["name"], "title": PhaseTwoContent.ACTORS["jiang_zi"]["title"], "bio": PhaseTwoContent.ACTORS["jiang_zi"]["bio"], "unlocked": true, "favor": 45, "avatar_key": "jiang_zi"}
		},
		"story_flags": {
			"prologue_completed": true,
			"chapter_1_unlocked": true,
			"chapter_1_completed": true,
			"school_gate_done": true,
			"school_affairs_done": true,
			"yang_rescued_player": true,
			"principal_stopped": true,
			"principal_briefing_done": true,
			"first_battle_hint_dismissed": true,
			"region_nomos_unlocked": true,
			"region_agora_unlocked": true,
			"region_techne_unlocked": true,
			"region_failed_alliance_unlocked": true,
			"region_iga_church_unlocked": true
		},
		"current_chapter_id": "chapter_1",
		"current_node_id": "n_find_yang",
		"visited_node_ids": ["n0", "n_gate", "n_affairs", "n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss", "n_find_yang"],
		"pending_combat_data": {},
		"pending_dialogue_id": "",
		"phase_two_checkpoint": {},
		"phase_two_combat_checkpoint": {},
		"phase_two_stream_active": false,
		"exploration_active": false,
		"exploration_state": {},
		"exploration_checkpoint": {},
		"exploration_materials": {"common": 18, "fine": 8, "rare": 4},
		"exploration_run_counter": 1,
		"exploration_return_hp": -1,
		"inventory_items": {"quest_sample": 1, "sealed_note": 1, "practice_token": 2},
		"inventory_reward_ledger": {},
		"inventory_acquired": {"material_common": {"order": 1, "day": 1, "hour": 9, "minute": 0}},
		"player_profile": {
			"loadouts": [
				{"name": "方案1", "card_ids": ["wrench_smash", "scrap_shield", "icy_soda", "overclock_torch", "steel_barricade"]},
				{"name": "方案2", "card_ids": ["wrench_smash", "fake_cheque", "overclock_torch"]}
			],
			"active_loadout_index": 0,
			"milestone_claims": {},
			"exploration_log": [],
			"last_activity": "story",
			"campus_life": {
				"last_location": "club",
				"region_id": "university_arete",
				"visited": ["club", "library", "gym", "shop", "rooftop"],
				"notes": {},
				"npc_talks": {},
				"studied_on_day": 0,
				"last_sleep_day": 0,
				"region_visits": {
					"university_arete": "completed",
					"university_nomos": "completed",
					"university_agora": "completed",
					"university_techne": "completed",
					"region_failed_alliance": "completed",
					"region_iga_church": "completed"
				}
			},
			"calendar": {"day": 3, "phase": "morning", "remaining": DayCycleService.ACTIONS_PER_PERIOD, "completed": {}, "pending": {}},
			"zodiac_collection": {"collected": test_zodiacs, "events": test_events}
		}
	}

static func get_test_save_metadata() -> Dictionary:
	return {"available": true, "backup": false, "test": true, "saved_at": 0, "day": 3, "hour": 9, "minute": 0, "chapter": "chapter_1", "hp": 150}

func load_test_save() -> bool:
	var progress := build_test_progress()
	if not GameState.validate_progress(progress):
		last_error = "测试存档校验失败。"
		return false
	var was_active := active_session
	var was_test := test_session
	active_session = false
	var success := GameState.import_progress(progress)
	active_session = true if success else was_active
	test_session = true if success else was_test
	last_error = "" if success else "测试存档加载失败。"
	save_state_changed.emit()
	return success

func typing_interval() -> float:
	return [0.045, 0.025, 0.012, 0.0][int(settings["text_speed"])]

func motion_duration(duration: float) -> float:
	return 0.0 if bool(settings["reduced_motion"]) else duration

func get_applied_settings() -> Dictionary:
	return {"master_volume": db_to_linear(AudioServer.get_bus_volume_db(0)), "muted": AudioServer.is_bus_mute(0), "fullscreen": get_window().mode == Window.MODE_FULLSCREEN}
