class_name HomePanels
extends RefCounted

const CLASSMATE_IDS: Array[String] = ["yang_zi_ying", "liu_yu_long", "jiang_zi"]
const ROUTE: Array[Dictionary] = [
	{"id": "n0", "title": "樱林解围", "summary": "替转校生黄秋枫挡下高年级生的刁难。"},
	{"id": "n_gate", "title": "运动会与初战", "summary": "留意秋枫异于常人的呼吸，与柳宇龙完成护盾热身切磋。"},
	{"id": "n_club_intro", "title": "入驻社团室", "summary": "接手阿瑞忒社团教室，开启校园日常与巡回整备。"},
	{"id": "n_affairs", "title": "书页与旧园之约", "summary": "图书馆约见黄秋枫与姜梓，察觉街区限幅异常记录。"},
	{"id": "n_dusk", "title": "黄昏轻吻", "summary": "旧公园分别转瞬，天空骤然响起红月警报。"},
	{"id": "n_guard", "title": "门岗封锁", "summary": "冲破被劫持的超限门禁，追向街角。"},
	{"id": "n_rescue", "title": "灰区奇袭", "summary": "目睹灰区女特工重创秋枫与露出的光纤电路。"},
	{"id": "n_robot", "title": "拦截机械", "summary": "与杨子英联手拦截超限重装机械。"},
	{"id": "n5_boss", "title": "红月超限", "summary": "全员卡匣协战同步，击退灰区猎杀机兵。"},
	{"id": "n_find_yang", "title": "白羊觉醒", "summary": "守住结晶核心，立下阿瑞忒选拔与六地区巡回赛之约。"}
]

static func content_snapshot(kind: String, selected_id: String = "") -> Dictionary:
	var exploration: Dictionary = {}
	if GameState.has_method("get_exploration_snapshot"):
		exploration = GameState.call("get_exploration_snapshot")
	var cards: Array[Dictionary] = []
	for cid in GameState.unlocked_card_ids:
		var card := GameState.get_card(cid)
		if card != null:
			cards.append({"id": cid, "name": card.name, "description": card.get_dynamic_description(card.level, false), "cooldown": card.get_current_cooldown(), "level": card.level, "max_level": card.max_level, "type": int(card.card_type), "equipped": GameState.equipped_card_ids.has(cid), "slot": GameState.equipped_card_ids.find(cid), "brief": _card_brief(card), "preview": _upgrade_summary(card), "upgrade_tooltip": card.get_upgrade_preview_text()})
	var selected: Dictionary = {}
	for card in cards:
		if card["id"] == selected_id:
			selected = card
	if selected.is_empty() and not cards.is_empty():
		selected = cards[0]
	var classmates: Array[Dictionary] = []
	for cid in CLASSMATE_IDS:
		var companion: Dictionary = GameState.companions.get(cid, {})
		var actor: Dictionary = PhaseTwoContent.ACTORS.get(cid, {})
		var short_bios := {"yang_zi_ying": "喜欢摄影和橘子汽水。\n每打出3张卡可发动「快门闪光支援」。", "liu_yu_long": "竞技台热血选手，讲究正大光明的切磋。\n每打出3张卡可发动「热血追击重扣」。", "jiang_zi": "学生会干事，把校园安全与赛事名录理得一清二楚。\n每打出3张卡可发动「战术统筹屏障」。"}
		classmates.append({"id": cid, "name": actor.get("name", "同学"), "subtitle": actor.get("title", "同班同学"), "bio": short_bios.get(cid, ""), "favor": companion.get("favor", 0), "unlocked": companion.get("unlocked", false), "portrait": DaylightUI.character_path(cid, true), "dialogue_id": {"yang_zi_ying": "chat_yang", "liu_yu_long": "chat_liu", "jiang_zi": "chat_jiang"}.get(cid, "chat_yang")})
	var cast: Array[Dictionary] = []
	for cid in ["ye_zhou", "huang_qiufeng", "yang_zi_ying", "liu_yu_long", "jiang_zi", "lin_zhi_xia", "tang_xiao_man"]:
		var actor: Dictionary = PhaseTwoContent.ACTORS[cid]
		var port_path := DaylightUI.character_path(cid, true)
		if cid in ["lin_zhi_xia", "tang_xiao_man"]:
			port_path = "res://assets/sprites/characters/phase_two/avatars/%s_neutral.png" % cid
		cast.append({"id": cid, "name": actor["name"], "subtitle": actor["title"], "portrait": port_path})
	var completed: bool = GameState.story_flags.get("chapter_1_completed", false)
	var current_step := clampi(GameState.visited_node_ids.size(), 0, ROUTE.size() - 1)
	var steps: Array[Dictionary] = []
	for index in ROUTE.size():
		var step: Dictionary = ROUTE[index].duplicate()
		step["state"] = "done" if GameState.visited_node_ids.has(step["id"]) else ("current" if index == current_step and not completed else "later")
		if step["state"] == "later":
			step["title"] = "待续"
			step["summary"] = ""
		elif step["state"] == "current":
			step["title"] = "现在的目标"
			step["summary"] = PhaseTwoContent.current_objective()
		steps.append(step)
	var upgrade_cost: int = int(selected.get("level", 1)) * 50
	return {
		"exploration": exploration, "dungeons": exploration.get("dungeons", []),
		"kind": kind, "title": {"lounge": "同学交流", "workshop": "卡牌整理", "records": "放映档案室", "quest": "模拟训练", "explore": "红月下的旧公园"}.get(kind, "校园生活"),
		"cards": cards, "selected_card": selected, "equipped_ids": GameState.equipped_card_ids.duplicate(), "classmates": classmates, "cast": cast,
		"practice_points": GameState.scrap_metal, "upgrade_cost": upgrade_cost,
		"can_upgrade": not selected.is_empty() and int(selected.get("level", 1)) < int(selected.get("max_level", 3)) and GameState.scrap_metal >= upgrade_cost,
		"steps": steps, "current_step": current_step, "current_title": PhaseTwoContent.current_objective(),
		"completed_count": GameState.visited_node_ids.size(), "total_steps": ROUTE.size(), "completed": completed, "time": GameState.get_formatted_time(),
		"chapter_description": "熟悉的阿瑞忒校园，突如其来的红月异常警报。\n追寻黄秋枫结晶真相，迈向六地区巡回锦标赛。",
		"chapter_action": "重新开始" if completed else ("开始今天的行程" if GameState.visited_node_ids.is_empty() else "继续今天的行程"),
		"chapter_restart": completed,
		"record_headline": "今天，一起站在了红月之下。" if completed else "校园里的小事，也值得记下来。",
		"record_summary": PhaseTwoContent.timeline_summary(),
		"record_anomaly": "反叛组织女特工使用盗取的早期母卡残钥劫持了街区限幅器并击伤编号04「黄秋枫」。\n创口露出的光纤证明她是月球计算中心派出的高阶拟真伪人。\n唯有赢得代表资格、集齐十二星座母卡与魔法师钥匙，方能申请唤醒她的深层数据。" if GameState.story_flags.get("principal_stopped", false) else ("校外街区安全限幅器侦测到未知外部高权限覆写。\n在前往旧公园赴约前，务必将随身卡匣整备妥当。" if (GameState.visited_node_ids.has("n_affairs") or GameState.visited_node_ids.has("n_dusk")) else "收好战术卡匣与巡回手记，准备出发。\n在阿瑞忒经历的一切都会被放映室一一留存。")
	}

static func _card_brief(card: CardData) -> String:
	match card.card_type:
		CardData.CardType.ATTACK:
			return "伤害 %d · 压制 %d 回合" % [card.get_scaled_damage(), card.burn_duration] if card.burn_duration > 0 else "造成 %d 点伤害" % card.get_scaled_damage()
		CardData.CardType.DEFENSE: return "获得 %d 点护盾" % card.get_scaled_shield()
		CardData.CardType.RECOVERY: return "恢复 %d 点体力" % card.get_scaled_heal()
		CardData.CardType.DEBUFF: return "敌方伤害降低 %d%%" % int(card.get_scaled_attack_down() * 100)
		_: return "护盾 %d · 反击 %d" % [card.get_scaled_shield(), card.get_scaled_reflect_damage()]

static func _upgrade_summary(card: CardData) -> String:
	if card.level >= card.max_level:
		return "已达到最高等级"
	var next_level := card.level + 1
	match card.card_type:
		CardData.CardType.ATTACK: return "下一等级：伤害 %d" % card.get_scaled_damage(next_level)
		CardData.CardType.DEFENSE: return "下一等级：护盾 %d" % card.get_scaled_shield(next_level)
		CardData.CardType.RECOVERY: return "下一等级：恢复 %d" % card.get_scaled_heal(next_level)
		CardData.CardType.DEBUFF: return "下一等级：减伤 %d%%" % int(card.get_scaled_attack_down(next_level) * 100)
		_: return "下一等级：反击 %d" % card.get_scaled_reflect_damage(next_level)

static func known_records() -> Array[Dictionary]:
	var source: Array[Dictionary] = [
		{"node": "n0", "title": "樱林 · 战术刻印解围", "copy": "替转校生黄秋枫挡下高年级生的刁难，两人交换名字。", "scene": "morning_road"},
		{"node": "n_gate", "title": "运动会 · 第四名的呼吸与初战", "copy": "秋枫跑完短跑仍呼吸平稳；与柳宇龙完成护盾裁决切磋。", "scene": "school_gate"},
		{"node": "n_club_intro", "title": "社团室 · 入驻与放映整备", "copy": "姜梓移交社团教室与放映档案室，全员确立阿瑞忒据点。", "scene": "school_room"},
		{"node": "n_affairs", "title": "图书馆 · 心意坦白与限幅异动", "copy": "窗边听见秋枫的心意并约下旧公园；姜梓示警街区限幅异常。", "scene": "school_room"},
		{"node": "n_dusk", "title": "黄昏 · 旧公园轻吻与警报", "copy": "秋枫突发轻吻后转身买汽水，红月警报骤然封锁通道。", "scene": "dusk_road"},
		{"node": "n_guard", "title": "门岗 · 突破超限封锁", "copy": "击退被超限指令锁死的门岗卫兵，抢通前往街角的路。", "scene": "school_gate"},
		{"node": "n_rescue", "title": "街角 · 光纤芯与灰区女特工", "copy": "目睹秋枫肩口露出的蓝色光纤；杨子英挺身护住叶舟。", "scene": "dusk_road"},
		{"node": "n_robot", "title": "路口 · 停下重装拦截机", "copy": "配合战术刻印卡挡下灰区重装机械的火力拦截。", "scene": "dusk_road"},
		{"node": "n5_boss", "title": "红月 · 全员协战共鸣", "copy": "姜梓同步卡匣防线、柳宇龙赶到支援，合力击败猎杀机兵。", "scene": "school_gate"},
		{"node": "n_find_yang", "title": "聚光 · 结晶核心与白羊座", "copy": "秋枫进入结晶休眠，#01 白羊座母卡觉醒，誓夺巡回代表资格。", "scene": "dusk_road"}
	]
	var happened: Array[Dictionary] = []
	for entry in source:
		if GameState.visited_node_ids.has(entry["node"]):
			happened.append(entry)
	return happened

class EquipSlot extends Button:
	signal move_requested(from_index: int, to_index: int)
	var slot_index: int = -1
	var card_id: String = ""
	var card_name: String = ""
	var drag_texture: Texture2D
	var drag_enabled: bool = true
	var deck_ids: Array = GameState.equipped_card_ids

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if card_id == "" or disabled or not drag_enabled:
			return null
		var preview := TextureRect.new()
		preview.name = "DraggedCardIcon"
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = drag_texture
		if preview.texture == null:
			var path := SceneSkin.card_illustration_path(card_id)
			if ResourceLoader.exists(path): preview.texture = SceneSkin.illustration_texture(path)
		preview.size = Vector2(104,86)
		preview.position = -preview.size * 0.5
		set_drag_preview(preview)
		return {"home_card_slot": slot_index, "card_id": card_id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if disabled or not drag_enabled or not data is Dictionary: return false
		var source := int(data.get("home_card_slot",-1))
		return data.has("card_id") and source >= 0 and source < deck_ids.size() and source != slot_index and str(data["card_id"]) == deck_ids[source]

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		move_requested.emit(int(data["home_card_slot"]), slot_index)
