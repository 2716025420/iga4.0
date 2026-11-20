class_name SceneObjectView
extends Control

signal action_requested(item: Dictionary)
signal map_requested
signal menu_requested

var location_id := ""
var stage_id := ""
var config: Dictionary
var refs: Dictionary = {"actions": {}}
var selected_id := ""
var clock: Label
var stage_layers: SceneStageLayers
var hud_layout: SceneHUDLayout

var _rooftop_npc_id := ""


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_id = "library" if location_id == "study" else ("shop" if location_id == "stockroom" else location_id)
	config = SceneDesignCatalog.place_config(location_id)
	_build_unified_scene()


func _exit_tree() -> void:
	if DayCycle.changed.is_connected(_on_day_changed):
		DayCycle.changed.disconnect(_on_day_changed)


func _build_unified_scene() -> void:
	if SceneStageLayers.has_staged_blueprint(stage_id):
		stage_layers = SceneStageLayers.new()
		stage_layers.name = "StageLayers"
		stage_layers.configure(stage_id, false)
		add_child(stage_layers)
		DaylightUI.place(stage_layers, 0.0, 0.0, 1920.0, 1080.0)
	else:
		var place_file := SceneDesignCatalog.place_path(location_id)
		var wide_place := place_file.replace(".png", "_wide.png")
		if ResourceLoader.exists(wide_place):
			var wide_bg := SchoolObjectUI.art(self, "WidePlaceBackground", wide_place, Rect2(-210, 0, 2340, 1080))
			wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
			wide_bg.z_index = -3
		var background := SchoolObjectUI.art(self, "PlaceBackground", place_file)
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.z_index = -2
		if ResourceLoader.exists(wide_place):
			background.self_modulate = Color(1, 1, 1, 0)

	var parent_id := str(CampusPlaces.PLACES.get(location_id, {}).get("parent", "map"))
	var back_copy := "← 返回社团教室" if parent_id == "club" else ("← 返回沿海公路" if parent_id == "arete_coast_test" else "← 返回校园地图")

	hud_layout = SceneHUDLayout.new()
	hud_layout.name = "SceneHUD"
	hud_layout.configure(location_id, str(config.get("title", "")), back_copy)
	add_child(hud_layout)
	DaylightUI.place(hud_layout, 0.0, 0.0, 1920.0, 1080.0)

	hud_layout.map_requested.connect(func(): map_requested.emit())
	hud_layout.menu_requested.connect(func(): menu_requested.emit())
	hud_layout.back_requested.connect(func():
		if parent_id == "map":
			map_requested.emit()
		else:
			action_requested.emit({"id": "go", "target": parent_id})
	)

	clock = hud_layout.time_label
	refs["map_button"] = hud_layout.map_button
	refs["menu"] = hud_layout.menu_button
	refs["actions"] = {}

	_populate_unified_actions_and_actors()
	DayCycle.changed.connect(_on_day_changed)
	_wire_unified_focus()
	var focus_target := hud_layout.focus_order()
	if not focus_target.is_empty():
		focus_target[0].grab_focus.call_deferred()


func _add_dock_action(item: Dictionary, kind: String, badge: String) -> void:
	var action_id := str(item["id"])
	var btn := hud_layout.add_action_row(
		item,
		kind,
		badge,
		_action_preview_text(action_id),
		func(): action_requested.emit(item)
	)
	refs["actions"][action_id] = btn


func _rooftop_variant_for(npc_id: String) -> String:
	match npc_id:
		"liu_yu_long":
			return "b"
		"jiang_zi":
			return "c"
		_:
			return "a"


func _beach_variant_for(npc_id: String) -> String:
	match npc_id:
		"yang_zi_ying":
			return "a"
		"liu_yu_long":
			return "b"
		_:
			return "c"


func _populate_unified_actions_and_actors() -> void:
	var walk_cid := CampusLife.active_walk_companion()
	var walk_name := str(PhaseTwoContent.ACTORS.get(walk_cid, {}).get("name", "同伴"))
	var walk_unlocked := bool(GameState.companions.get(walk_cid, {}).get("unlocked", false)) or SaveManager.test_session

	match stage_id:
		"shop":
			var talk_item := {"id": "talk", "label": "和唐小满聊聊", "npc": "tang_xiao_man"}
			if is_instance_valid(stage_layers):
				stage_layers.set_staged_variant(
					"slot_a",
					"a",
					"和唐小满聊聊",
					func(): action_requested.emit(talk_item)
				)
			_add_dock_action({"id": "shop", "label": "查看商品采购"}, "free", "免费")
			_add_dock_action({"id": "shop_work", "label": "店务兼职"}, "activity", "1活动")
			_add_dock_action(talk_item, "free", "免费")

		"library":
			var act1_ready := not GameState.visited_node_ids.has("n_affairs") and PlayerJourney.act1_story_ready()
			var lin_variant := "c" if act1_ready else "a"
			var talk_lin := {"id": "talk", "label": "和林知夏聊聊", "npc": "lin_zhi_xia"}
			if is_instance_valid(stage_layers):
				stage_layers.set_staged_variant(
					"slot_a",
					lin_variant,
					"和林知夏聊聊",
					func(): action_requested.emit(talk_lin)
				)
				if act1_ready:
					var story_item := {"id": "story_act1", "label": "与黄秋枫交谈（主线）"}
					stage_layers.set_staged_variant(
						"slot_b",
						"b",
						"开启主线剧情",
						func(): action_requested.emit(story_item)
					)
			if act1_ready:
				var story_row := {"id": "story_act1", "label": "与黄秋枫交谈"}
				_add_dock_action(story_row, "story", "主线")
			_add_dock_action({"id": "library_study", "label": "牌理研习"}, "activity", "1活动")
			_add_dock_action({"id": "read_notes", "label": "翻阅风物纪要"}, "free", "免费")
			_add_dock_action(talk_lin, "free", "免费")

		"gym":
			var liu_unlocked := bool(GameState.companions.get("liu_yu_long", {}).get("unlocked", false)) or SaveManager.test_session
			var ch1_done := bool(GameState.story_flags.get("chapter_1_completed", false))
			var qual_done := bool(GameState.story_flags.get("arete_qualifier_completed", false))
			var qual_active := ch1_done and not qual_done
			var qual_kind := "story" if qual_active else "free"
			var liu_variant := "b" if qual_active else "c"
			_add_dock_action({"id": "qualifier", "label": "代表选拔赛"}, qual_kind, "赛事")
			_add_dock_action({"id": "training", "label": "模拟训练"}, "free", "免费")
			_add_dock_action({"id": "workshop", "label": "整理行动卡"}, "free", "免费")
			if liu_unlocked:
				var talk_liu := {"id": "talk", "label": "和柳宇龙聊聊", "npc": "liu_yu_long"}
				if is_instance_valid(stage_layers):
					stage_layers.set_staged_variant(
						"slot_a",
						liu_variant,
						"和柳宇龙聊聊",
						func(): action_requested.emit(talk_liu)
					)
				_add_dock_action(talk_liu, "free", "免费")

		"rooftop":
			_rooftop_npc_id = CampusLife.rooftop_active_npc()
			var roof_name := str(PhaseTwoContent.ACTORS.get(_rooftop_npc_id, {}).get("name", "同伴"))
			var roof_variant := _rooftop_variant_for(_rooftop_npc_id)
			if is_instance_valid(stage_layers):
				stage_layers.set_staged_variant(
					"slot_a",
					roof_variant,
					"和%s聊聊" % roof_name,
					func(): action_requested.emit({"id": "talk", "npc": CampusLife.rooftop_active_npc()})
				)
			_add_dock_action({"id": "rooftop_review", "label": "午后复盘"}, "activity", "1活动")
			_add_dock_action({"id": "switch_companion", "label": "切换随行同伴"}, "free", "免费")
			var roof_talk_btn := hud_layout.add_action_row(
				{"id": "talk", "label": "和%s聊聊" % roof_name},
				"free",
				"免费",
				_action_preview_text("talk"),
				func(): action_requested.emit({"id": "talk", "npc": CampusLife.rooftop_active_npc()})
			)
			refs["actions"]["talk"] = roof_talk_btn
			_add_dock_action({"id": "rooftop_vending", "label": "查看饮料贩卖机"}, "free", "免费")

		"arete_coast_test":
			var park_open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			var park_story := not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false)) and PlayerJourney.act2_combat_ready()
			if is_instance_valid(stage_layers):
				var talk_coast := {"id": "talk", "label": "和黄秋枫聊聊", "npc": "huang_qiufeng"}
				stage_layers.set_staged_variant(
					"slot_a",
					"c",
					"和黄秋枫聊聊",
					func(): action_requested.emit(talk_coast)
				)
			var park_label := "旧公园（黄昏之约）" if park_story else ("拐进旧公园" if park_open else "旧公园（未开放）")
			var park_item := {"id": "enter_old_park", "target": "old_park", "label": park_label}
			if park_story:
				_add_dock_action(park_item, "story", "赴约")
			_add_dock_action({"id": "coast_walk", "label": "海风漫步"}, "activity", "1活动")
			_add_dock_action({"id": "coast_observe", "label": "吹吹海风"}, "free", "免费")
			if not park_story:
				_add_dock_action(park_item, "move" if park_open else "locked", "前往" if park_open else "锁定")
			_add_dock_action({"id": "go", "target": "arete_beach_test", "label": "走向海滩"}, "move", "前往")

		"old_park":
			var act3_pending := not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false))
			var park_action := {"id": "story_act3", "label": "与黄秋枫赴约"} if act3_pending else {"id": "talk", "label": "和黄秋枫聊聊", "npc": "huang_qiufeng"}
			if is_instance_valid(stage_layers):
				stage_layers.set_staged_variant(
					"slot_b",
					"c",
					"赴黄昏之约" if act3_pending else "和黄秋枫聊聊",
					func(): action_requested.emit(park_action)
				)
			if act3_pending:
				_add_dock_action(park_action, "story", "主线")
			_add_dock_action({"id": "park_reflect", "label": "长椅追忆"}, "activity", "1活动")
			_add_dock_action({"id": "park_vending", "label": "查看街角贩卖机"}, "free", "免费")

		"arete_beach_test":
			var beach_cid := walk_cid if walk_unlocked else "jiang_zi"
			var beach_variant := _beach_variant_for(beach_cid)
			var beach_name := str(PhaseTwoContent.ACTORS.get(beach_cid, {}).get("name", "姜梓"))
			if is_instance_valid(stage_layers):
				var talk_beach := {"id": "talk", "label": "和%s聊聊" % beach_name, "npc": beach_cid}
				stage_layers.set_staged_variant(
					"slot_a",
					beach_variant,
					"和%s聊聊" % beach_name,
					func(): action_requested.emit(talk_beach)
				)
			_add_dock_action({"id": "beach_rest", "label": "海边休整"}, "activity", "1活动")
			_add_dock_action({"id": "beach_observe", "label": "远眺海平线"}, "free", "免费")

		"dorm":
			var dorm_note_item := {"id": "dorm_note", "label": "阅读门边信笺"}
			if is_instance_valid(stage_layers):
				stage_layers.set_staged_variant(
					"slot_a",
					"c",
					"查看桌上的便签",
					func(): action_requested.emit(dorm_note_item)
				)
			_add_dock_action({"id": "sleep", "label": DayCycle.rest_label()}, "activity", "时段")
			_add_dock_action({"id": "dorm_desk", "label": "书桌整理 · 今日小结"}, "free", "免费")
			_add_dock_action(dorm_note_item, "free", "免费")

		_:
			for item in CampusPlaces.PLACES.get(location_id, {}).get("actions", []):
				if str(item.get("id", "")) == "go" and str(item.get("target", "")) == "map":
					continue
				_add_dock_action(item, "free", "免费")


func _wire_unified_focus() -> void:
	if not is_instance_valid(hud_layout):
		return
	var order: Array[BaseButton] = hud_layout.focus_order()
	for i in order.size():
		var button: BaseButton = order[i]
		button.focus_previous = button.get_path_to(order[posmod(i - 1, order.size())])
		button.focus_next = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.focus_previous
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_right = button.focus_next
		button.focus_neighbor_bottom = button.focus_next


func set_shop_split_mode(enabled: bool) -> void:
	if is_instance_valid(hud_layout):
		hud_layout.set_dock_visible(not enabled)
	if is_instance_valid(stage_layers):
		stage_layers.set_slot_hit_enabled(not enabled)
		if location_id == "shop":
			stage_layers.position.x = 150.0 if enabled else 0.0


func _on_day_changed() -> void:
	if is_instance_valid(stage_layers):
		stage_layers.apply_period_lighting()
		if location_id == "rooftop":
			var next_npc := CampusLife.rooftop_active_npc()
			if next_npc != _rooftop_npc_id:
				_rooftop_npc_id = next_npc
				var next_name := str(PhaseTwoContent.ACTORS.get(next_npc, {}).get("name", "同伴"))
				var next_variant := _rooftop_variant_for(next_npc)
				stage_layers.set_staged_variant(
					"slot_a",
					next_variant,
					"和%s聊聊" % next_name,
					func(): action_requested.emit({"id": "talk", "npc": CampusLife.rooftop_active_npc()})
				)
				var talk_btn := refs.get("actions", {}).get("talk") as Button
				if is_instance_valid(talk_btn):
					talk_btn.text = "和%s聊聊" % next_name
	if is_instance_valid(hud_layout):
		hud_layout.refresh_status()


func _action_preview_text(action_id: String) -> String:
	match action_id:
		"story_act1":
			return "✦ 第一幕主线 · 与图书馆窗边的黄秋枫开启「红月之问」剧情"
		"story_act3":
			return "✦ 第二幕主线 · 与旧公园长椅旁的黄秋枫赴黄昏之约"
		"library_study", "study":
			return "牌理研习（1活动点）→ 获得 +35 练习点，并新收录 1 篇《风物纪要》"
		"read_notes":
			return "翻阅风物纪要（0活动点）→ 免费回顾已在图书馆解锁的校园档案"
		"shop_work":
			return "店务兼职（1活动点）→ 获得 +100 零用钱，每完成 2 次额外获赠能量饮品"
		"shop":
			return "查看商品柜台（0活动点）→ 左栏选购战术刻印卡/素材/饮品，右侧与唐小满互动"
		"training":
			return "模拟训练（入场无消耗）→ 探索随机校园演练路线，提升卡匣实力与放映室记录"
		"qualifier":
			return "阿瑞忒代表选拔赛（0活动点开启）→ 迎战 3 轮校内切磋，赢取「阿瑞忒代表通行章」"
		"workshop":
			return "整理行动卡（0活动点）→ 编辑出战卡匣与强化卡牌等级"
		"rooftop_review":
			return "午后复盘（1活动点）→ 恢复 40 点体力 · +20 练习点 · +12 当前同伴好感"
		"switch_companion":
			return "切换随行同伴（0活动点）→ 更换作战协战同伴与沿海/海滩同行伙伴"
		"rooftop_vending":
			return "饮料贩卖机（0活动点）→ 看看天台角落社团常用的冷饮机"
		"coast_walk":
			return "海风漫步（1活动点）→ +15 练习点，与当前随行同伴提升 +15 默契好感"
		"coast_observe":
			return "吹吹海风（0活动点）→ 眺望阿瑞忒海湾与远处的白色灯塔"
		"beach_rest":
			return "海边休整（1活动点）→ 恢复 35 点体力 · 普通材料 ×2 · 同伴好感 +10"
		"beach_observe":
			return "远眺海平线（0活动点）→ 倾听海浪拍岸，放松身心"
		"park_reflect":
			return "长椅追忆（1活动点）→ 恢复 30 点体力 · +30 练习点 · 寻回旧公园细节记录"
		"park_vending":
			return "查看街角贩卖机（0活动点）→ 亮着暖橙灯箱的橘子汽水自动贩卖机"
		"enter_old_park":
			var open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			if not open:
				return "旧公园小径（尚未开放）· 需先前往「图书馆」推动第一幕主线剧情"
			return "沿树荫小径进入校外「旧公园」· 通往第二幕主线赴约与长椅追忆（0活动消耗）"
		"go":
			if location_id == "arete_coast_test":
				return "沿海石阶下行前往「阿瑞忒海滩」· 休息与拾取材料（0活动消耗）"
			return "沿原路返回上一处场景"
		"talk":
			return "同伴日常交谈（0活动点）→ 了解线索与近况"
		"dorm_desk":
			return "查看今日统计（0活动点）→ 检查剩余活动与当前阿瑞忒收集进度"
		"dorm_note":
			return "阅读门边信笺（0活动点）→ 翻看夹在书里的放学后便签"
		"sleep":
			return "回房休息 → 推进到下一时段并恢复体力"
	return ""


func select_object(id: String = "") -> void:
	selected_id = id


func set_interactions_enabled(enabled: bool) -> void:
	if is_instance_valid(hud_layout):
		hud_layout.set_interactions_enabled(enabled)
	if is_instance_valid(stage_layers):
		stage_layers.set_slot_hit_enabled(enabled)
