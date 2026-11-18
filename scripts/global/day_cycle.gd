class_name DayCycleService
extends Node

signal changed
const ACTIONS_PER_PERIOD := 3
const START_MONTH := 10
const START_DAY := 1
const MONTH_LENGTHS := [31,28,31,30,31,30,31,31,30,31,30,31]
const DAYS_PER_YEAR := 365
const PERIODS := ["morning","afternoon","night"]
const PERIOD_NAMES := {"morning":"早晨","afternoon":"下午","night":"夜晚"}
const PERIOD_HOURS := [8,14,20]
const WEEKDAYS := ["星期一","星期二","星期三","星期四","星期五","星期六","星期日"]
var events: Array = CalendarContent.STORY_DATES.duplicate(true)
var suspended := false
var _poll := 0.0

func _ready() -> void:
	GameState.game_time_changed.connect(_clock_changed)

func _process(delta: float) -> void:
	_poll += delta
	if _poll < 0.2: return
	_poll = 0.0
	dispatch_due_event()

func _clock_changed(_day: int, _hour: int, _minute: int, _weekday: String) -> void:
	changed.emit()

static func weekday_for_day(day: int) -> String:
	return str(WEEKDAYS[posmod(day+1,7)])

static func period_for_hour(hour: int) -> String:
	if hour >= 18 or hour < 6: return "night"
	return "morning" if hour < 12 else "afternoon"

static func phase_index(phase: String) -> int:
	# Legacy day events are treated as morning; new content uses explicit periods.
	return maxi(0,PERIODS.find("morning" if phase == "day" else phase))

static func _days_before_month(month: int) -> int:
	var total := 0
	for index in range(month-1): total += int(MONTH_LENGTHS[index])
	return total

static func calendar_date(elapsed_day: int) -> Dictionary:
	# A yearless, common-year calendar; weekdays continue across the year boundary.
	var offset := posmod(maxi(1,elapsed_day)-1+_days_before_month(START_MONTH)+START_DAY-1,DAYS_PER_YEAR)
	for index in MONTH_LENGTHS.size():
		var length := int(MONTH_LENGTHS[index])
		if offset < length: return {"month":index+1,"day":offset+1}
		offset -= length
	return {"month":START_MONTH,"day":START_DAY}

static func day_for_date(month: int, day_of_month: int) -> int:
	if month not in range(1,13) or day_of_month < 1 or day_of_month > int(MONTH_LENGTHS[month-1]): return 0
	return posmod(_days_before_month(month)+day_of_month-_days_before_month(START_MONTH)-START_DAY,DAYS_PER_YEAR)+1

static func event_day(event: Dictionary) -> int:
	if not GameState._whole_number(event.get("day")): return 0
	if event.has("month"):
		if not GameState._whole_number(event["month"]): return 0
		return day_for_date(int(event["month"]),int(event["day"]))
	# Legacy ordinal events remain readable; new stories specify month and day.
	return int(event["day"]) if int(event["day"]) > 0 else 0

static func date_label(day: int, hour: int) -> String:
	var date := calendar_date(day)
	return "%d月%d日 · %s · %s" % [date["month"],date["day"],weekday_for_day(day),PERIOD_NAMES[period_for_hour(hour)]]

static func valid_calendar(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["day","remaining"]:
		if not GameState._whole_number(value.get(key)): return false
	if int(value["day"]) < 1 or int(value["remaining"]) not in range(ACTIONS_PER_PERIOD+1) or value.get("phase") not in ["morning","afternoon","night","day"]: return false
	if not value.get("completed") is Dictionary or value["completed"].size() > 512 or not value.get("pending") is Dictionary: return false
	for id in value["completed"]:
		if not id is String or id.length() > 120 or not value["completed"][id] is bool or value["completed"][id] != true: return false
	var pending: Dictionary = value["pending"]
	if pending.is_empty(): return true
	if not valid_event(pending) or not GameState._whole_number(pending.get("line_index")) or int(pending["line_index"]) < 0: return false
	return true

static func valid_event(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["id","location","dialogue"]:
		if not value.get(key) is String or str(value[key]).is_empty() or str(value[key]).length() > 120: return false
	if event_day(value) < 1 or value.get("phase","morning") not in ["morning","afternoon","night","day"]: return false
	if not CampusPlaces.PLACES.has(value["location"]) or not PhaseTwoContent.SCRIPTS.has(value["dialogue"]): return false
	for key in ["required_flags","flags"]:
		if value.has(key):
			if not value[key] is Dictionary or value[key].size() > 32: return false
			for flag in value[key]:
				if not flag is String or not value[key][flag] is bool: return false
	return true

func period() -> String:
	return period_for_hour(GameState.game_hour)

func snapshot() -> Dictionary:
	var data: Dictionary = GameState.player_profile.get("calendar",{}).duplicate(true)
	if data.is_empty(): data = {"day":GameState.game_day,"phase":period(),"remaining":ACTIONS_PER_PERIOD,"completed":{},"pending":{}}
	if data["phase"] == "day": data["phase"] = period()
	if int(data["day"]) != GameState.game_day or data["phase"] != period():
		data["day"] = GameState.game_day
		data["phase"] = period()
		data["remaining"] = ACTIONS_PER_PERIOD
	return data

func remaining() -> int:
	return int(snapshot()["remaining"])

func pending_event() -> Dictionary:
	return snapshot()["pending"].duplicate(true)

func due_event() -> Dictionary:
	var data := snapshot()
	var best: Dictionary = {}
	var score := 2147483647
	var now := GameState.game_day*PERIODS.size()+phase_index(period())
	for event in events:
		if not valid_event(event) or data["completed"].has(event["id"]): continue
		var when := event_day(event)*PERIODS.size()+phase_index(str(event.get("phase","morning")))
		if when > now or when >= score: continue
		if not RegionCatalog.is_unlocked(RegionCatalog.region_for_place(str(event["location"]))): continue
		var ready := true
		for flag in event.get("required_flags",{}):
			if GameState.story_flags.get(flag,false) != event["required_flags"][flag]: ready = false
		if ready: best = event.duplicate(true); score = when
	return best

func has_story() -> bool:
	return not pending_event().is_empty() or not due_event().is_empty()

func can_act() -> bool:
	return not SceneManager.is_transitioning and not GameState.exploration_active and GameState.archive_dialogue_id == "" and not has_story() and remaining() > 0

func block_reason() -> String:
	if has_story(): return "今天有重要的安排，先去完成这段故事吧。"
	if GameState.exploration_active: return "先完成或暂停当前训练。"
	return "这个时段已经安排满了，休息后再继续吧。"

func activity_hint() -> String:
	return "这个时段还可安排 %d 次活动" % remaining() if remaining() > 0 else "这个时段已结束，休息后继续"

func rest_label() -> String:
	return str({"morning":"休息到下午","afternoon":"休息到夜晚","night":"休息到次日早晨"}[period()])

func _commit(data: Dictionary) -> void:
	GameState.player_profile["calendar"] = data
	GameState.profile_changed.emit()
	changed.emit()

func spend_action(_kind: String) -> bool:
	if not can_act(): return false
	var data := snapshot()
	data["remaining"] = maxi(0,int(data["remaining"])-1)
	_commit(data)
	return true

func rest() -> bool:
	if has_story() or GameState.exploration_active or GameState.archive_dialogue_id != "" or SceneManager.is_transitioning: return false
	var host := get_tree().current_scene
	if not is_instance_valid(host) or not (host is HomeScreen or host is CampusScreen or host.get_meta("map_page",false)) or host.get_meta("campus_dialogue_open",false): return false
	var overnight := period() == "night"
	var next_day := GameState.game_day+(1 if overnight else 0)
	var next_period := (phase_index(period())+1)%PERIODS.size()
	GameState.set_game_time(next_day,int(PERIOD_HOURS[next_period]),0,weekday_for_day(next_day))
	GameState.heal_player(GameState.player_max_hp if overnight else 20)
	_commit(snapshot())
	return true

func _safe_host() -> bool:
	if suspended or not SaveManager.active_session or SceneManager.is_transitioning or GameState.exploration_active or GameState.archive_dialogue_id != "": return false
	var host := get_tree().current_scene
	if not is_instance_valid(host) or not (host is HomeScreen or host is CampusScreen or host.get_meta("map_page",false)): return false
	if host.get_meta("campus_dialogue_open",false) or host.get_meta("region_modal_open",false): return false
	if host is HomeScreen and (host.modals_layer.visible or is_instance_valid(host.system_menu)): return false
	if host is CampusScreen and (bool(host.get("_busy")) or bool(host.get("_sleep_confirm"))): return false
	return true

func dispatch_due_event() -> bool:
	if not _safe_host(): return false
	var data := snapshot()
	var event: Dictionary = data["pending"]
	if event.is_empty():
		event = due_event()
		if event.is_empty(): return false
		event["line_index"] = 0
		data["pending"] = event
		_commit(data)
	if CampusLife.current_location != event["location"]:
		return CampusLife.travel_to(str(event["location"]))
	GameState.pending_dialogue_id = str(event["dialogue"])
	SceneManager.change_scene(SceneManager.TargetScene.STORY)
	return true

func is_event_dialogue(dialogue_id: String) -> bool:
	var event := pending_event()
	return not event.is_empty() and event.get("dialogue","") == dialogue_id

func checkpoint_event(line_index: int) -> void:
	var data := snapshot()
	if data["pending"].is_empty(): return
	data["pending"]["line_index"] = maxi(0,line_index)
	_commit(data)

func complete_event() -> bool:
	var data := snapshot()
	var event: Dictionary = data["pending"]
	if event.is_empty() or data["completed"].has(event["id"]): return false
	data["completed"][event["id"]] = true
	data["pending"] = {}
	_commit(data)
	for flag in event.get("flags",{}): GameState.set_story_flag(str(flag),event["flags"][flag])
	GameState.pending_dialogue_id = ""
	CampusLife.travel_to(str(event["location"]))
	return true
