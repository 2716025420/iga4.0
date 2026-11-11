extends Node

# 内部卡牌 ID 保留兼容，所有可见内容由二阶段校园文案替换。

signal player_stats_changed
signal deck_changed
signal materials_changed
signal game_time_changed(day: int, hour: int, minute: int, weekday: String)
signal companion_favor_changed(companion_id: String, new_favor: int)
signal story_flag_updated(flag_name: String, value: Variant)

# 玩家基础属性
var player_max_hp: int = 120
var player_current_hp: int = 120
var scrap_metal: int = 20       # 练习点数
var energy_crystals: int = 320   # 校园零用钱
var energy_drinks: int = 3       # 饮品补给

# 游戏内置时间系统 (非现实时间，可由剧情/探索/交互推进或预设)
var game_day: int = 1            # 内部累计日；第 1 日对应 10 月 1 日，界面统一显示月日
var game_hour: int = 7          # 小时 0-23
var game_minute: int = 35        # 分钟 0-59
var game_weekday: String = "星期三" # 星期/周期名称

# 卡牌数据缓存 (key: id -> CardData)
var all_cards: Dictionary = {}

# 玩家已解锁的卡牌 ID 列表
var unlocked_card_ids: Array[String] = [
	"wrench_smash",
	"scrap_shield",
	"icy_soda",
	"overclock_torch"
]

# 默认只装备一张攻击卡；所有装备变更都必须保留至少一张攻击卡。
var equipped_card_ids: Array[String] = ["wrench_smash"]

# 卡牌等级映射 (card_id -> int)
var card_levels: Dictionary = {
	"wrench_smash": 1,
	"scrap_shield": 1,
	"icy_soda": 1,
	"overclock_torch": 1,
	"fake_cheque": 1,
	"steel_barricade": 1
}

# 伙伴好感度与招募状态
var companions: Dictionary = {
	"yang_zi_ying": {"name":"杨子英","title":"总有新计划的同学","bio":"热心、行动快，喜欢摄影和橘子汽水。想拍下上学路最漂亮的夕阳，也不愿把朋友留在危险里。","unlocked":true,"favor":20,"avatar_key":"yang_zi_ying"},
	"liu_yu_long": {"name":"柳宇龙","title":"不服输的同班同学","bio":"爱开玩笑，也很在意别人是否认真看待自己。一次光明正大的胜利，比嘴上占便宜更重要。","unlocked":false,"favor":0,"avatar_key":"liu_yu_long"},
	"jiang_zi": {"name":"姜梓","title":"认真负责的校园事务员","bio":"负责整理校园事务与值日表。嘴上嫌麻烦，遇到问题总会先把信息核对清楚，让大家少走弯路。","unlocked":false,"favor":0,"avatar_key":"jiang_zi"}
}

# 剧情标志位
var story_flags: Dictionary = {
	"prologue_completed": false,
	"chapter_1_unlocked": true,
	"chapter_1_completed": false,
	"school_gate_done": false,
	"school_affairs_done": false,
	"yang_rescued_player": false,
	"principal_stopped": false,
	"principal_briefing_done": false,
	"first_battle_hint_dismissed": false
}

# 当前正在进行的探索节点与关卡状态
var current_chapter_id: String = "chapter_1"
var current_node_id: String = ""
var visited_node_ids: Array[String] = []
var pending_combat_data: Dictionary = {}
var pending_dialogue_id: String = ""
var phase_two_checkpoint: Dictionary = {}
var phase_two_combat_checkpoint: Dictionary = {}
var phase_two_stream_active: bool = false

# Material exploration has its own route, combat snapshot and reward ledger.
signal exploration_changed
var exploration_active: bool = false
var exploration_state: Dictionary = {}
var exploration_checkpoint: Dictionary = {}
var exploration_materials: Dictionary = {"common": 3, "fine": 0, "rare": 0}
var exploration_run_counter: int = 0
var exploration_return_hp: int = -1

# Persistent optional experience data; old saves receive empty defaults.
const DECK_RULE_MESSAGE := "卡组至少保留一张攻击卡"
var player_profile: Dictionary = {"loadouts": [{"name":"方案1","card_ids":["wrench_smash"]}], "active_loadout_index": 0, "milestone_claims": {}, "exploration_log": [], "last_activity": "story"}
# Read-only memories are a viewing context, never saved as story progress.
var archive_dialogue_id: String = ""
var archive_return_tab: String = ""

signal profile_changed
signal rewards_received(rewards: Dictionary)
signal inventory_changed
var inventory_items: Dictionary = {}
var inventory_reward_ledger: Dictionary = {}
var inventory_acquired: Dictionary = {}
var _initial_progress: Dictionary = {}
const PERSISTED_FIELDS := ["player_max_hp", "player_current_hp", "scrap_metal", "energy_crystals", "energy_drinks", "game_day", "game_hour", "game_minute", "game_weekday", "unlocked_card_ids", "equipped_card_ids", "card_levels", "companions", "story_flags", "current_chapter_id", "current_node_id", "visited_node_ids", "pending_combat_data", "pending_dialogue_id", "phase_two_checkpoint", "phase_two_combat_checkpoint", "phase_two_stream_active", "exploration_active", "exploration_state", "exploration_checkpoint", "exploration_materials", "exploration_run_counter", "exploration_return_hp", "inventory_items", "inventory_reward_ledger", "inventory_acquired", "player_profile"]

func get_inventory_quantity(item_id: String) -> int:
	var item := ItemCatalog.definition(item_id)
	if item.is_empty(): return 0
	var source: String = str(item.get("source", ""))
	if source == "drinks": return energy_drinks
	if source != "": return int(exploration_materials.get(source, 0))
	return int(inventory_items.get(item_id, 0))

func get_inventory_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	var totals := {"all": 0, "material": 0, "quest": 0, "item": 0}
	for item_id in ItemCatalog.ITEMS:
		var quantity := get_inventory_quantity(str(item_id))
		if quantity <= 0: continue
		var item := ItemCatalog.definition(str(item_id))
		item["id"] = item_id
		item["quantity"] = quantity
		item["acquired"] = inventory_acquired.get(item_id, {}).duplicate(true)
		entries.append(item)
		totals["all"] += 1
		totals[item["category"]] += 1
	return {"items": entries, "totals": totals, "categories": ItemCatalog.CATEGORIES.duplicate()}

func add_inventory_item(item_id: String, quantity: int, show_notification: bool = true) -> bool:
	var item := ItemCatalog.definition(item_id)
	if item.is_empty() or quantity <= 0 or get_inventory_quantity(item_id) > 999999 - quantity: return false
	var source: String = str(item.get("source", ""))
	if source == "drinks": energy_drinks += quantity
	elif source != "": exploration_materials[source] = get_inventory_quantity(item_id) + quantity
	else: inventory_items[item_id] = get_inventory_quantity(item_id) + quantity
	_record_inventory_acquisition(item_id)
	notify_rewards({item_id:quantity},show_notification)
	inventory_changed.emit()
	materials_changed.emit()
	return true

func _record_inventory_acquisition(item_id: String) -> void:
	var sequence: int = 0
	for entry in inventory_acquired.values(): sequence = maxi(sequence, int(entry.get("order", 0)))
	inventory_acquired[item_id] = {"order": sequence + 1, "day": game_day, "hour": game_hour, "minute": game_minute}

func remove_inventory_item(item_id: String, quantity: int) -> bool:
	var item := ItemCatalog.definition(item_id)
	var current := get_inventory_quantity(item_id)
	if item.is_empty() or quantity <= 0 or current < quantity: return false
	var source: String = str(item.get("source", ""))
	if source == "drinks": energy_drinks -= quantity
	elif source != "": exploration_materials[source] = current - quantity
	elif current == quantity: inventory_items.erase(item_id)
	else: inventory_items[item_id] = current - quantity
	inventory_changed.emit()
	materials_changed.emit()
	return true

func grant_inventory_reward(reward_id: String, rewards: Dictionary, show_notification: bool = true) -> bool:
	if reward_id.strip_edges() == "" or inventory_reward_ledger.has(reward_id) or rewards.is_empty(): return false
	for item_id in rewards:
		var quantity: Variant = rewards[item_id]
		if not _whole_number(quantity) or int(quantity) <= 0 or ItemCatalog.definition(str(item_id)).is_empty() or get_inventory_quantity(str(item_id)) > 999999 - int(quantity): return false
	inventory_reward_ledger[reward_id] = true
	for item_id in rewards: add_inventory_item(str(item_id), int(rewards[item_id]),show_notification)
	return true

func _whole_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floorf(float(value))

func export_progress(normalize_exploration: bool = true) -> Dictionary:
	var progress := {}
	for field in PERSISTED_FIELDS:
		var value: Variant = get(field)
		progress[field] = value.duplicate(true) if value is Dictionary or value is Array else value
	if normalize_exploration and exploration_active:
		progress["exploration_state"]["hp"] = player_current_hp
		progress["exploration_state"]["status"] = "paused"
		progress["exploration_active"] = false
		progress["player_current_hp"] = exploration_return_hp if exploration_return_hp >= 0 else player_current_hp
		progress["exploration_return_hp"] = -1
	return progress

func validate_progress(progress: Dictionary) -> bool:
	if _initial_progress.is_empty(): return false
	for field in PERSISTED_FIELDS:
		# Saves created before acquisition tracking remain valid; unknown dates stay unknown.
		if field in ["inventory_acquired", "player_profile"] and not progress.has(field): continue
		if not progress.has(field): return false
		var value: Variant = progress[field]
		var initial: Variant = _initial_progress[field]
		if typeof(initial) == TYPE_INT:
			if not _whole_number(value): return false
		elif typeof(value) != typeof(initial): return false
	if int(progress["player_max_hp"]) < 1 or int(progress["player_max_hp"]) > 999999 or int(progress["player_current_hp"]) < 0 or int(progress["player_current_hp"]) > int(progress["player_max_hp"]): return false
	for field in ["scrap_metal", "energy_crystals", "energy_drinks", "exploration_run_counter"]:
		if int(progress[field]) < 0 or int(progress[field]) > 999999: return false
	if int(progress["game_day"]) < 1 or int(progress["game_hour"]) not in range(24) or int(progress["game_minute"]) not in range(60): return false
	for field in ["unlocked_card_ids", "equipped_card_ids", "visited_node_ids"]:
		for value in progress[field]:
			if not value is String: return false
	if progress["equipped_card_ids"].size() > 5: return false
	var equipped_unique := {}
	for card_id in progress["equipped_card_ids"]:
		if equipped_unique.has(card_id) or not all_cards.has(card_id) or not progress["unlocked_card_ids"].has(card_id): return false
		equipped_unique[card_id] = true
	for card_id in progress["card_levels"]:
		if not all_cards.has(card_id) or not _whole_number(progress["card_levels"][card_id]) or int(progress["card_levels"][card_id]) not in range(1, 4): return false
	for item_id in progress["inventory_items"]:
		var item := ItemCatalog.definition(str(item_id))
		var quantity: Variant = progress["inventory_items"][item_id]
		if item.is_empty() or item.has("source") or not _whole_number(quantity) or int(quantity) <= 0 or int(quantity) > 999999: return false
	var acquired: Variant = progress.get("inventory_acquired", {})
	if not acquired is Dictionary: return false
	for item_id in acquired:
		if ItemCatalog.definition(str(item_id)).is_empty() or not acquired[item_id] is Dictionary: return false
		var entry: Dictionary = acquired[item_id]
		for key in ["order", "day", "hour", "minute"]:
			if not _whole_number(entry.get(key)): return false
		if int(entry["order"]) < 1 or int(entry["day"]) < 1 or int(entry["hour"]) not in range(24) or int(entry["minute"]) not in range(60): return false
	for quality in ["common", "fine", "rare"]:
		var amount: Variant = progress["exploration_materials"].get(quality, -1)
		if not _whole_number(amount) or int(amount) < 0 or int(amount) > 999999: return false
	var exploration: Dictionary = progress["exploration_state"]
	if not exploration.is_empty():
		for field in ["nodes", "visited", "deck"]:
			if not exploration.get(field) is Array: return false
		for field in ["settled", "earned"]:
			if not exploration.get(field) is Dictionary: return false
		if not _whole_number(exploration.get("hp")) or not _whole_number(exploration.get("run_id")): return false
		for node in exploration["nodes"]:
			if not node is Dictionary or not node.get("id") is String or not node.get("next") is Array or not _whole_number(node.get("layer")) or not _whole_number(node.get("type")): return false
	if progress.has("player_profile") and not PlayerJourney.validate_profile(progress["player_profile"]): return false
	return true

func import_progress(progress: Dictionary) -> bool:
	if not validate_progress(progress): return false
	for field in PERSISTED_FIELDS:
		if field in ["inventory_acquired", "player_profile"] and not progress.has(field):
			set(field, _initial_progress[field].duplicate(true))
			continue
		var initial: Variant = _initial_progress[field]
		if field in ["unlocked_card_ids", "equipped_card_ids", "visited_node_ids"]:
			get(field).clear()
			get(field).append_array(progress[field])
		elif typeof(initial) == TYPE_INT: set(field, int(progress[field]))
		elif initial is Dictionary or initial is Array: set(field, progress[field].duplicate(true))
		else: set(field, progress[field])
	for card_id in card_levels: card_levels[card_id] = int(card_levels[card_id])
	for item_id in inventory_items: inventory_items[item_id] = int(inventory_items[item_id])
	for quality in exploration_materials: exploration_materials[quality] = int(exploration_materials[quality])
	for card_id in all_cards: all_cards[card_id].level = int(card_levels.get(card_id, 1))
	# Repair legacy equipment at the equipment-loading boundary, never at combat entry.
	if not PlayerJourney.deck_summary(equipped_card_ids)["ready"]:
		if not unlocked_card_ids.has("wrench_smash"): unlocked_card_ids.append("wrench_smash")
		if equipped_card_ids.size() >= 5: equipped_card_ids[0] = "wrench_smash"
		else: equipped_card_ids.append("wrench_smash")
	if player_profile["loadouts"].is_empty():
		player_profile["loadouts"].append({"name":"方案1","card_ids":equipped_card_ids.duplicate()})
	# Old saves did not record identity: choose the first matching preset once.
	# An explicit -1 means a custom equipped deck, even if another preset matches.
	var entries: Array = player_profile["loadouts"]
	if not player_profile.has("active_loadout_index"):
		player_profile["active_loadout_index"] = -1
		for index in entries.size():
			if entries[index]["card_ids"] == equipped_card_ids:
				player_profile["active_loadout_index"] = index
				break
	var active_index := int(player_profile["active_loadout_index"])
	if active_index >= 0 and entries[active_index]["card_ids"] != equipped_card_ids: active_index = -1
	player_profile["active_loadout_index"] = active_index
	player_stats_changed.emit()
	deck_changed.emit()
	materials_changed.emit()
	inventory_changed.emit()
	exploration_changed.emit()
	return true

func new_game() -> bool:
	return import_progress(_initial_progress.duplicate(true))

func _request_progress_save() -> void:
	var service := get_node_or_null("/root/SaveManager")
	if service: service.call("request_autosave")


func reset_exploration_progress() -> void:
	current_node_id = ""
	visited_node_ids.clear()
	phase_two_checkpoint.clear()
	phase_two_combat_checkpoint.clear()
	phase_two_stream_active = false

func begin_phase_two_chapter() -> void:
	reset_exploration_progress()
	pending_combat_data.clear()
	pending_dialogue_id = ""
	for flag in ["prologue_completed", "chapter_1_completed", "school_gate_done", "school_affairs_done", "yang_rescued_player", "principal_stopped", "principal_briefing_done"]:
		set_story_flag(flag, false)
	companions["liu_yu_long"]["unlocked"] = false
	companions["jiang_zi"]["unlocked"] = false
	set_game_time(1, 7, 35, "星期三")
	reset_player_hp()

func mark_node_visited(nid: String) -> void:
	if nid != "" and not visited_node_ids.has(nid):
		visited_node_ids.append(nid)

func _ready() -> void:
	_init_default_cards()
	_record_inventory_acquisition("drink")
	_initial_progress = export_progress(false)

func _init_default_cards() -> void:
	# 1. 找准空隙
	var c1 = CardData.new()
	c1.id = "wrench_smash"
	c1.name = "找准空隙"
	c1.card_type = CardData.CardType.ATTACK
	c1.base_cooldown = 1
	c1.damage = 18
	c1.description = "对单个敌人造成 [color=#ff5555]18点[/color] 物理伤害。"
	c1.flavor_text = "先观察，再抓住对方动作之间的空隙。"
	all_cards[c1.id] = c1

	# 2. 书包格挡
	var c2 = CardData.new()
	c2.id = "scrap_shield"
	c2.name = "书包格挡"
	c2.card_type = CardData.CardType.DEFENSE
	c2.target_type = CardData.TargetType.SELF
	c2.base_cooldown = 1
	c2.shield = 14
	c2.description = "自身获得 [color=#55aaff]14点[/color] 护盾，持续 1 回合。"
	c2.flavor_text = "书包里的课本，偶尔也有另一种用途。"
	all_cards[c2.id] = c2

	# 3. 补充水分
	var c3 = CardData.new()
	c3.id = "icy_soda"
	c3.name = "补充水分"
	c3.card_type = CardData.CardType.RECOVERY
	c3.target_type = CardData.TargetType.SELF
	c3.base_cooldown = 3
	c3.heal = 24
	c3.description = "调整呼吸，恢复叶舟 [color=#55ff55]24点[/color] 体力，每场战斗最多使用2次。"
	c3.flavor_text = "喝口水，慢慢把呼吸调整回来。"
	all_cards[c3.id] = c3

	# 4. 连续牵制
	var c4 = CardData.new()
	c4.id = "overclock_torch"
	c4.name = "连续牵制"
	c4.card_type = CardData.CardType.ATTACK
	c4.base_cooldown = 3
	c4.damage = 24
	c4.burn_damage = 6
	c4.burn_duration = 2
	c4.description = "造成 [color=#ff5555]24点[/color] 伤害，并附加 2 回合“压制”(每回合6点)。"
	c4.flavor_text = "持续保持距离，让对方来不及组织下一步。"
	all_cards[c4.id] = c4

	# 5. 转移注意
	var c5 = CardData.new()
	c5.id = "fake_cheque"
	c5.name = "转移注意"
	c5.card_type = CardData.CardType.DEBUFF
	c5.target_type = CardData.TargetType.ALL_ENEMIES
	c5.base_cooldown = 3
	c5.attack_down_percent = 0.25
	c5.debuff_duration = 2
	c5.description = "转移敌方全体注意，使其造成的伤害降低 [color=#ffff55]25%[/color]，持续 2 回合。"
	c5.flavor_text = "把注意力引向别处，为同伴争取时间。"
	all_cards[c5.id] = c5

	# 6. 默契掩护
	var c6 = CardData.new()
	c6.id = "steel_barricade"
	c6.name = "默契掩护"
	c6.card_type = CardData.CardType.SPECIAL
	c6.target_type = CardData.TargetType.SELF
	c6.base_cooldown = 2
	c6.shield = 10
	c6.reflect_damage = 10
	c6.description = "获得 [color=#55aaff]10点[/color] 护盾，本次敌方行动中受击反弹 [color=#ff9955]10点[/color] 伤害，最多2次。"
	c6.flavor_text = "大家相互照应，总比一个人硬撑有效。"
	all_cards[c6.id] = c6

func get_card(card_id: String) -> CardData:
	if all_cards.has(card_id):
		var card = all_cards[card_id]
		card.level = card_levels.get(card_id, 1)
		return card
	return null

func unlock_card(card_id: String, show_notification: bool = true) -> void:
	if not unlocked_card_ids.has(card_id):
		unlocked_card_ids.append(card_id)
		notify_rewards({"card:" + card_id:1},show_notification)
		deck_changed.emit()

func apply_equipped_deck(ids: Array, loadout_index: int = -1) -> bool:
	for id in ids:
		if not id is String: return false
	if not PlayerJourney.deck_summary(ids)["ready"]: return false
	var entries: Array = player_profile["loadouts"]
	if loadout_index < -1 or loadout_index >= entries.size(): return false
	if loadout_index >= 0 and entries[loadout_index]["card_ids"] != ids: return false
	# A no-op equipment edit keeps its preset; applying an identical preset changes identity.
	if loadout_index == -1 and ids == equipped_card_ids: return true
	var previous_index := int(player_profile.get("active_loadout_index",-1))
	equipped_card_ids.assign(ids)
	player_profile["active_loadout_index"] = loadout_index
	deck_changed.emit()
	if previous_index != loadout_index: profile_changed.emit()
	return true

func equip_card(card_id: String, slot_index: int) -> bool:
	if not all_cards.has(card_id) or not unlocked_card_ids.has(card_id) or slot_index < 0 or slot_index >= 5: return false
	var next: Array = equipped_card_ids.duplicate()
	if next.has(card_id):
		next.erase(card_id)
		next.insert(mini(slot_index,next.size()),card_id)
	elif slot_index < next.size(): next[slot_index] = card_id
	else: next.append(card_id)
	return apply_equipped_deck(next)

func unequip_card(card_id: String) -> bool:
	if not equipped_card_ids.has(card_id): return false
	var next: Array = equipped_card_ids.duplicate()
	next.erase(card_id)
	return apply_equipped_deck(next)

func unequip_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= equipped_card_ids.size(): return false
	return unequip_card(equipped_card_ids[slot_index])

func upgrade_card(card_id: String, quality: String = "common") -> bool:
	return PlayerJourney.train(card_id, quality)

func add_scrap(amount: int, show_notification: bool = true) -> void:
	scrap_metal += amount
	notify_rewards({"practice_points":amount},show_notification)
	materials_changed.emit()

func heal_player(amount: int) -> void:
	player_current_hp = min(player_max_hp, player_current_hp + amount)
	player_stats_changed.emit()

func damage_player(amount: int) -> void:
	player_current_hp = max(0, player_current_hp - amount)
	player_stats_changed.emit()

func reset_player_hp() -> void:
	player_current_hp = player_max_hp
	player_stats_changed.emit()

func add_companion_favor(companion_id: String, amount: int) -> void:
	if companions.has(companion_id):
		companions[companion_id]["favor"] += amount
		companion_favor_changed.emit(companion_id, companions[companion_id]["favor"])

func set_story_flag(flag_name: String, value: Variant) -> void:
	story_flags[flag_name] = value
	story_flag_updated.emit(flag_name, value)

func add_crystals(amount: int) -> void:
	energy_crystals = max(0, energy_crystals + amount)
	notify_rewards({"allowance":amount})
	materials_changed.emit()

func set_game_time(day: int, hour: int, minute: int, weekday: String = "") -> void:
	game_day = max(1, day)
	game_hour = clampi(hour, 0, 23)
	game_minute = clampi(minute, 0, 59)
	if weekday != "":
		game_weekday = weekday
	game_time_changed.emit(game_day, game_hour, game_minute, game_weekday)

func advance_story_time(hour: int, minute: int) -> void:
	# Story beats may move the current day forward, never rewind free-life progress.
	var target_minutes := clampi(hour, 0, 23) * 60 + clampi(minute, 0, 59)
	advance_game_time(maxi(0, target_minutes - game_hour * 60 - game_minute))

func advance_game_time(add_minutes: int, add_hours: int = 0, add_days: int = 0) -> void:
	var total_mins = game_minute + add_minutes
	var carry_hours = total_mins / 60
	game_minute = total_mins % 60
	
	var total_hours = game_hour + add_hours + carry_hours
	var carry_days = total_hours / 24
	game_hour = total_hours % 24
	
	var days_to_add = add_days + carry_days
	game_day += days_to_add
	
	if days_to_add > 0:
		var weekdays = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
		var cur_idx = weekdays.find(game_weekday)
		if cur_idx >= 0:
			game_weekday = weekdays[(cur_idx + days_to_add) % 7]
	
	game_time_changed.emit(game_day, game_hour, game_minute, game_weekday)

func get_formatted_time() -> String:
	return DayCycleService.date_label(game_day,game_hour)

func get_detailed_time_string() -> String:
	return DayCycleService.date_label(game_day,game_hour)


func next_phase_two_node() -> String:
	for step in PhaseTwoContent.FLOW_STEPS:
		if not visited_node_ids.has(step["node"]):
			return step["node"]
	return ""

func start_story_from_home(restart: bool = false) -> void:
	if SceneManager.is_transitioning:
		return
	if restart:
		begin_phase_two_chapter()
	if story_flags.get("chapter_1_completed", false):
		return
	if phase_two_combat_checkpoint.is_empty() and not PlayerJourney.deck_summary()["ready"]: return
	player_profile["last_activity"] = "story"
	profile_changed.emit()
	phase_two_stream_active = true
	_open_phase_two_node(next_phase_two_node())

func _open_phase_two_node(node_id: String) -> void:
	var step: Dictionary = PhaseTwoContent.step_for(node_id)
	if step.is_empty():
		return
	current_chapter_id = "chapter_1"
	current_node_id = node_id
	var combat_stage: bool = step.has("enemy") and (not step.has("dialogue") or story_flags.get("principal_briefing_done", false))
	if phase_two_checkpoint.get("node_id", "") != node_id:
		phase_two_checkpoint.clear()
		phase_two_combat_checkpoint.clear()
	if combat_stage:
		phase_two_checkpoint = {"node_id":node_id, "stage":"combat"}
		pending_dialogue_id = ""
		pending_combat_data = {"enemies":[step["enemy"]], "is_boss":node_id == "n5_boss"}
		SceneManager.change_scene(SceneManager.TargetScene.COMBAT)
	else:
		if phase_two_checkpoint.get("stage", "") != "dialogue":
			phase_two_checkpoint = {"node_id":node_id, "stage":"dialogue", "line_index":0}
		pending_dialogue_id = step.get("dialogue", "campus_morning")
		pending_combat_data.clear()
		SceneManager.change_scene(SceneManager.TargetScene.STORY)

func checkpoint_phase_two_dialogue(dialogue_id: String, line_index: int) -> void:
	var node_id: String = PhaseTwoContent.node_for_dialogue(dialogue_id)
	if node_id != "" and node_id == next_phase_two_node():
		current_node_id = node_id
		phase_two_checkpoint = {"node_id":node_id, "stage":"dialogue", "line_index":maxi(0,line_index)}
		_request_progress_save()

func pause_phase_two_chapter() -> void:
	if SceneManager.is_transitioning or get_tree().current_scene is CombatScreen:
		return
	pending_dialogue_id = ""
	pending_combat_data.clear()
	SceneManager.change_scene(SceneManager.TargetScene.HOME)

func complete_phase_two_step(node_id: String) -> bool:
	if node_id == "" or node_id != next_phase_two_node() or visited_node_ids.has(node_id):
		return false
	mark_node_visited(node_id)
	phase_two_checkpoint.clear()
	phase_two_combat_checkpoint.clear()
	pending_dialogue_id = ""
	pending_combat_data.clear()
	phase_two_stream_active = true
	var next_node: String = next_phase_two_node()
	if next_node == "":
		set_story_flag("chapter_1_completed", true)
		advance_story_time(18,0)
		current_node_id = ""
		phase_two_stream_active = false
		SceneManager.change_scene(SceneManager.TargetScene.HOME)
	else:
		_open_phase_two_node(next_node)
	return true


func _exploration_pending() -> bool:
	return not exploration_state.is_empty() and exploration_state.get("status", "") in ["running", "paused"]

func get_exploration_snapshot() -> Dictionary:
	var catalog: Array[Dictionary] = ExplorationContent.dungeon_catalog(story_flags, visited_node_ids)
	var pending: bool = _exploration_pending()
	for item in catalog:
		var same: bool = item["id"] == exploration_state.get("dungeon_id", "")
		item["resume"] = same and pending
		item["active"] = same and exploration_active
		if same and pending:
			item["status"] = exploration_state.get("status", "paused")
			item["unlocked"] = true
			item["lock_reason"] = ""
	return {"dungeons": catalog, "active": exploration_active, "resume": pending, "state": exploration_state.duplicate(true), "materials": exploration_materials.duplicate(true), "material_names": ExplorationContent.MATERIAL_NAMES.duplicate()}

func start_exploration(dungeon_id: String, run_seed: int = -1) -> bool:
	if SceneManager.is_transitioning or DayCycle.has_story(): return false
	if not _exploration_pending() and not DayCycle.can_act(): return false
	var catalog: Array[Dictionary] = ExplorationContent.dungeon_catalog(story_flags, visited_node_ids)
	var unlocked: bool = false
	for item in catalog:
		if item["id"] == dungeon_id: unlocked = bool(item["unlocked"])
	if not unlocked and not (_exploration_pending() and exploration_state.get("dungeon_id", "") == dungeon_id): return false
	if _exploration_pending():
		if exploration_state.get("dungeon_id", "") != dungeon_id: return false
		SchoolExplorationFlow.migrate_pending()
	else:
		if not PlayerJourney.deck_summary()["ready"]: return false
		var deck: Array[Dictionary] = []
		for card_id in equipped_card_ids:
			if get_card(card_id) != null: deck.append({"id": card_id, "level": int(card_levels.get(card_id, 1))})
		if deck.is_empty(): return false
		if not DayCycle.spend_action("training"): return false
		exploration_run_counter += 1
		var seed_value: int = run_seed if run_seed >= 0 else int(randi())
		exploration_state = {"layout_version": 2, "depth": 0, "boss_defeated": false, "dialogue_line": 0, "purchases": {}, "spent_points": 0, "run_id": exploration_run_counter, "dungeon_id": dungeon_id, "seed": seed_value, "nodes": SchoolExplorationRoutes.generate(dungeon_id, seed_value, exploration_run_counter), "visited": [], "settled": {}, "current_node_id": "", "stage": "map", "status": "running", "hp": player_max_hp, "deck": deck, "earned": {"scrap_metal": 0, "materials": {"common": 0, "fine": 0, "rare": 0}}, "last_result": {}}
		exploration_checkpoint.clear()
	if not exploration_active:
		exploration_return_hp = player_current_hp
		player_current_hp = clampi(int(exploration_state.get("hp", player_max_hp)), 0, player_max_hp)
		player_stats_changed.emit()
	player_profile["last_activity"] = "exploration"
	profile_changed.emit()
	exploration_active = true
	exploration_state["status"] = "running"
	exploration_changed.emit()
	var destination: int = SceneManager.TargetScene.EXPLORATION
	if is_exploration_combat(): destination = SceneManager.TargetScene.COMBAT
	elif SchoolExplorationFlow.enabled() and exploration_state.get("stage", "") == "dialogue": destination = SceneManager.TargetScene.STORY
	SceneManager.change_scene(destination)
	return true

func get_exploration_node(node_id: String) -> Dictionary:
	for node in exploration_state.get("nodes", []):
		if node.get("id", "") == node_id:
			return SchoolExplorationRoutes.normalize_support_node(node) if SchoolExplorationFlow.enabled() else node.duplicate(true)
	return {}

func get_exploration_available_nodes() -> Array[String]:
	if SchoolExplorationFlow.enabled(): return SchoolExplorationFlow.available_nodes()
	var available: Array[String] = []
	if not exploration_active or exploration_state.get("status", "") != "running" or exploration_state.get("stage", "") != "map": return available
	var visited: Array = exploration_state.get("visited", [])
	if visited.is_empty():
		for node in exploration_state.get("nodes", []):
			if int(node.get("layer", -1)) == 0: available.append(str(node["id"]))
	else:
		var previous := get_exploration_node(str(visited[-1]))
		for node_id in previous.get("next", []):
			if not visited.has(node_id): available.append(str(node_id))
	return available

func choose_exploration_node(node_id: String) -> bool:
	if SchoolExplorationFlow.enabled(): return SchoolExplorationFlow.choose_node(node_id)
	if SceneManager.is_transitioning or not get_exploration_available_nodes().has(node_id): return false
	var node := get_exploration_node(node_id)
	if node.is_empty(): return false
	exploration_state["current_node_id"] = node_id
	exploration_state["stage"] = "combat" if not node.get("enemy_keys", []).is_empty() else "event"
	exploration_state["hp"] = player_current_hp
	exploration_checkpoint.clear()
	exploration_changed.emit()
	if is_exploration_combat(): SceneManager.change_scene(SceneManager.TargetScene.COMBAT)
	return true

func is_exploration_combat() -> bool:
	if not exploration_active or exploration_state.get("status", "") != "running" or exploration_state.get("stage", "") != "combat": return false
	var node := get_exploration_node(str(exploration_state.get("current_node_id", "")))
	return not node.is_empty() and not node.get("enemy_keys", []).is_empty() and not exploration_state.get("settled", {}).has(node["id"])

func get_exploration_combat_data() -> Dictionary:
	if not is_exploration_combat(): return {}
	var node := get_exploration_node(str(exploration_state["current_node_id"]))
	var specs: Array[Dictionary] = ExplorationContent.enemy_specs(str(exploration_state["dungeon_id"]), node)
	var enemy_ids: Array[String] = []
	for spec in specs: enemy_ids.append(str(spec["id"]))
	return {"node_id": node["id"], "run_id": exploration_state["run_id"], "dungeon_id": exploration_state["dungeon_id"], "enemies": enemy_ids, "enemy_specs": specs, "is_boss": int(node["type"]) == MapNodeData.NodeType.BOSS, "reward": node["reward"].duplicate(true)}

func get_exploration_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for entry in exploration_state.get("deck", []):
		var original_card: CardData = get_card(str(entry.get("id", "")))
		if original_card != null:
			var card: CardData = original_card.duplicate(true) as CardData
			card.level = int(entry.get("level", 1))
			cards.append(card)
	return cards

func save_exploration_combat_checkpoint(snapshot: Dictionary) -> bool:
	if not is_exploration_combat(): return false
	exploration_checkpoint = snapshot.duplicate(true)
	exploration_checkpoint["node_id"] = exploration_state["current_node_id"]
	exploration_checkpoint["run_id"] = exploration_state["run_id"]
	exploration_checkpoint["player_hp"] = player_current_hp
	exploration_state["hp"] = player_current_hp
	exploration_changed.emit()
	return true

func get_exploration_combat_checkpoint() -> Dictionary:
	if exploration_checkpoint.get("run_id", -1) != exploration_state.get("run_id", -2) or exploration_checkpoint.get("node_id", "") != exploration_state.get("current_node_id", ""):
		return {}
	return exploration_checkpoint.duplicate(true)

func pause_exploration() -> bool:
	if get_tree().current_scene is CombatScreen: return false
	if SceneManager.is_transitioning or not exploration_active or not _exploration_pending(): return false
	exploration_state["status"] = "paused"
	_leave_exploration_context()
	exploration_changed.emit()
	CampusLife.return_from_training()
	return true

func _leave_exploration_context() -> void:
	if exploration_active: exploration_state["hp"] = player_current_hp
	exploration_active = false
	if exploration_return_hp >= 0:
		player_current_hp = clampi(exploration_return_hp, 0, player_max_hp)
		exploration_return_hp = -1
		player_stats_changed.emit()

func complete_exploration_node(node_id: String, outcome: String = "victory", show_notification: bool = true) -> bool:
	if SchoolExplorationFlow.enabled(): return SchoolExplorationFlow.settle(node_id, outcome, show_notification)
	if not exploration_active or exploration_state.get("status", "") != "running" or exploration_state.get("current_node_id", "") != node_id or exploration_state.get("settled", {}).has(node_id): return false
	var node := get_exploration_node(node_id)
	if node.is_empty() or exploration_state.get("stage", "") not in ["combat", "event"]: return false
	if outcome in ["defeat", "failed"]: return finish_exploration("defeat")
	var reward: Dictionary = node.get("reward", {}).duplicate(true)
	var healing: int = int(node.get("heal", 0))
	if int(node["type"]) == MapNodeData.NodeType.EVENT:
		var chosen: Dictionary = {}
		for choice in node.get("choices", []):
			if choice.get("id", "") == outcome or (outcome == "victory" and chosen.is_empty()): chosen = choice
		if chosen.is_empty(): return false
		reward = chosen.get("reward", {}).duplicate(true)
		healing = int(chosen.get("heal", 0))
	elif outcome != "victory": return false
	var ledger: Dictionary = exploration_state["settled"]
	ledger[node_id] = {"outcome": outcome, "reward": reward.duplicate(true)}
	var points: int = maxi(0, int(reward.get("scrap_metal", 0)))
	scrap_metal += points
	var earned: Dictionary = exploration_state["earned"]
	earned["scrap_metal"] = int(earned.get("scrap_metal", 0)) + points
	var materials: Dictionary = reward.get("materials", {})
	var received := {"practice_points":points}
	for quality in ["common", "fine", "rare"]:
		var amount: int = maxi(0, int(materials.get(quality, 0)))
		exploration_materials[quality] = int(exploration_materials.get(quality, 0)) + amount
		if amount > 0:
			_record_inventory_acquisition("material_" + quality)
			received["material_" + quality] = amount
		var earned_materials: Dictionary = earned["materials"]
		earned_materials[quality] = int(earned_materials.get(quality, 0)) + amount
	notify_rewards(received,show_notification)
	var visited: Array = exploration_state["visited"]
	visited.append(node_id)
	var previous_hp: int = player_current_hp
	if healing > 0: heal_player(healing)
	var restored_hp: int = player_current_hp - previous_hp
	exploration_state["hp"] = player_current_hp
	exploration_state["last_result"] = {"node_id": node_id, "outcome": outcome, "reward": reward.duplicate(true), "heal": restored_hp, "title": node["title"]}
	exploration_state["stage"] = "map"
	exploration_checkpoint.clear()
	materials_changed.emit()
	if int(node["type"]) == MapNodeData.NodeType.BOSS:
		finish_exploration("victory")
	else:
		exploration_state["current_node_id"] = ""
		exploration_changed.emit()
	return true

func finish_exploration(outcome: String = "victory") -> bool:
	if SchoolExplorationFlow.enabled(): return SchoolExplorationFlow.finish(outcome)
	if not _exploration_pending(): return false
	if outcome == "victory":
		var last_id: String = str(exploration_state.get("current_node_id", ""))
		var node := get_exploration_node(last_id)
		if node.is_empty() or int(node["type"]) != MapNodeData.NodeType.BOSS or not exploration_state.get("settled", {}).has(last_id): return false
	elif outcome not in ["defeat", "retreated"]: return false
	exploration_state["status"] = "completed" if outcome == "victory" else outcome
	exploration_state["stage"] = "finished"
	PlayerJourney.record_exploration()
	exploration_checkpoint.clear()
	_leave_exploration_context()
	exploration_changed.emit()
	return true

func retreat_exploration() -> bool:
	if get_tree().current_scene is CombatScreen: return false
	if SceneManager.is_transitioning or not _exploration_pending(): return false
	if not finish_exploration("retreated"): return false
	CampusLife.return_from_training()
	return true

func notify_rewards(rewards: Dictionary, show_notification: bool = true) -> void:
	if not show_notification: return
	var received := {}
	for id in rewards:
		if int(rewards[id]) > 0: received[str(id)] = int(rewards[id])
	if not received.is_empty(): rewards_received.emit(received)

func execute_shop_trade(product_id: String, quantity: Variant, mode: String, request_id: String) -> Dictionary:
	var quote := CampusShopCatalog.quote(product_id,quantity,mode)
	var receipts: Dictionary = player_profile.get("shop_receipts",{}).duplicate()
	if request_id.strip_edges() == "" or request_id.length() > 120 or receipts.has(request_id) or not CampusShopCatalog.valid_receipts(receipts):
		return {"ok":false,"message":"该交易已处理或编号无效"}
	if not quote["ok"]: return quote
	var product: Dictionary = quote["product"]
	var amount := int(quote["quantity"])
	var direction := 1 if mode == "buy" else -1
	# Commit all data before any signal; observers never see a half-paid transaction.
	energy_crystals -= direction*int(quote["total"])
	if product["kind"] == "card":
		unlocked_card_ids.append(product["ref"])
	else:
		var id := str(product["ref"])
		var item := ItemCatalog.definition(id)
		var source := str(item.get("source",""))
		var next := get_inventory_quantity(id)+direction*amount
		if source == "drinks": energy_drinks = next
		elif source != "": exploration_materials[source] = next
		elif next == 0: inventory_items.erase(id)
		else: inventory_items[id] = next
		if mode == "buy": _record_inventory_acquisition(id)
	if receipts.size() >= 128: receipts.erase(receipts.keys()[0])
	receipts[request_id] = true
	player_profile["shop_receipts"] = receipts
	profile_changed.emit()
	materials_changed.emit()
	inventory_changed.emit()
	if product["kind"] == "card": deck_changed.emit()
	return {"ok":true,"message":("已购买" if mode == "buy" else "已回收")+str(product["name"])+" ×"+str(amount),"total":quote["total"],"balance":energy_crystals}
