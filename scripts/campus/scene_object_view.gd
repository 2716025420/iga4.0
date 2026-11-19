class_name SceneObjectView
extends Control

signal action_requested(item: Dictionary)
signal map_requested
signal menu_requested

var location_id := ""
var config: Dictionary
var refs: Dictionary = {"actions": {}}
var objects: Dictionary = {}
var selected_id := ""
var clock: Label
var stage_layers: SceneStageLayers
var hud_layout: SceneHUDLayout

var _actor_layer: Control
var _use_unified := false
var _rooftop_npc_id := ""


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	config = SceneDesignCatalog.place_config(location_id)
	_use_unified = SceneStageLayers.has_staged_blueprint(location_id) or bool(config.get("use_unified_hud", false))
	if _use_unified:
		_build_unified_scene()
	else:
		_build_legacy_scene()


func _exit_tree() -> void:
	if DayCycle.changed.is_connected(_on_day_changed):
		DayCycle.changed.disconnect(_on_day_changed)


func _build_unified_scene() -> void:
	if SceneStageLayers.has_staged_blueprint(location_id):
		stage_layers = SceneStageLayers.new()
		stage_layers.name = "StageLayers"
		stage_layers.configure(location_id, false)
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


func _populate_unified_actions_and_actors() -> void:
	var walk_cid := CampusLife.active_walk_companion()
	var walk_name := str(PhaseTwoContent.ACTORS.get(walk_cid, {}).get("name", "同伴"))
	var walk_unlocked := bool(GameState.companions.get(walk_cid, {}).get("unlocked", false)) or SaveManager.test_session

	match location_id:
		"shop":
			var talk_item := {"id": "talk", "label": "和唐小满聊聊", "npc": "tang_xiao_man"}
			if is_instance_valid(stage_layers):
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png",
					"和唐小满聊聊",
					func(): action_requested.emit(talk_item)
				)
			_add_dock_action({"id": "shop", "label": "查看商品采购"}, "free", "免费")
			_add_dock_action({"id": "shop_work", "label": "店务兼职"}, "activity", "1活动")
			_add_dock_action(talk_item, "free", "免费")
			hud_layout.add_npc_bubble(
				"Bubble_tang_xiao_man",
				SceneStageLayers.bubble_anchor("shop", "slot_a"),
				"唐小满",
				false,
				_action_preview_text("talk"),
				func(): action_requested.emit(talk_item)
			)

		"library":
			var act1_ready := not GameState.visited_node_ids.has("n_affairs") and PlayerJourney.act1_story_ready()
			var talk_lin := {"id": "talk", "label": "和林知夏聊聊", "npc": "lin_zhi_xia"}
			if is_instance_valid(stage_layers):
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png",
					"和林知夏聊聊",
					func(): action_requested.emit(talk_lin)
				)
				if act1_ready:
					var story_item := {"id": "story_act1", "label": "与黄秋枫交谈（主线）"}
					stage_layers.set_slot_actor(
						"slot_b",
						"res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png",
						"开启主线剧情",
						func(): action_requested.emit(story_item)
					)
			if act1_ready:
				var story_row := {"id": "story_act1", "label": "与黄秋枫交谈"}
				_add_dock_action(story_row, "story", "主线")
				hud_layout.add_npc_bubble(
					"Bubble_huang_qiufeng",
					SceneStageLayers.bubble_anchor("library", "slot_b"),
					"黄秋枫",
					true,
					_action_preview_text("story_act1"),
					func(): action_requested.emit(story_row)
				)
			_add_dock_action({"id": "library_study", "label": "牌理研习"}, "activity", "1活动")
			_add_dock_action({"id": "read_notes", "label": "翻阅风物纪要"}, "free", "免费")
			_add_dock_action(talk_lin, "free", "免费")
			hud_layout.add_npc_bubble(
				"Bubble_lin_zhi_xia",
				SceneStageLayers.bubble_anchor("library", "slot_a"),
				"林知夏",
				false,
				_action_preview_text("talk"),
				func(): action_requested.emit(talk_lin)
			)

		"gym":
			var liu_unlocked := bool(GameState.companions.get("liu_yu_long", {}).get("unlocked", false)) or SaveManager.test_session
			var ch1_done := bool(GameState.story_flags.get("chapter_1_completed", false))
			var qual_done := bool(GameState.story_flags.get("arete_qualifier_completed", false))
			var qual_kind := "story" if (ch1_done and not qual_done) else "free"
			_add_dock_action({"id": "qualifier", "label": "阿瑞忒代表选拔赛"}, qual_kind, "赛事")
			_add_dock_action({"id": "training", "label": "模拟训练"}, "free", "免费")
			_add_dock_action({"id": "workshop", "label": "整理行动卡"}, "free", "免费")
			if liu_unlocked:
				var talk_liu := {"id": "talk", "label": "和柳宇龙聊聊", "npc": "liu_yu_long"}
				if is_instance_valid(stage_layers):
					stage_layers.set_slot_actor(
						"slot_a",
						"res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png",
						"和柳宇龙聊聊",
						func(): action_requested.emit(talk_liu)
					)
				_add_dock_action(talk_liu, "free", "免费")
				hud_layout.add_npc_bubble(
					"Bubble_liu_yu_long",
					SceneStageLayers.bubble_anchor("gym", "slot_a"),
					"柳宇龙",
					false,
					_action_preview_text("talk"),
					func(): action_requested.emit(talk_liu)
				)

		"rooftop":
			_rooftop_npc_id = CampusLife.rooftop_active_npc()
			var roof_name := str(PhaseTwoContent.ACTORS.get(_rooftop_npc_id, {}).get("name", "同伴"))
			if is_instance_valid(stage_layers):
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/fullbody/%s.png" % _rooftop_npc_id,
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
			hud_layout.add_npc_bubble(
				"Bubble_rooftop_npc",
				SceneStageLayers.bubble_anchor("rooftop", "slot_a"),
				roof_name,
				false,
				_action_preview_text("talk"),
				func(): action_requested.emit({"id": "talk", "npc": CampusLife.rooftop_active_npc()})
			)

		"arete_coast_test":
			var park_open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			var park_story := not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false)) and PlayerJourney.act2_combat_ready()
			if walk_unlocked and is_instance_valid(stage_layers):
				var talk_walk := {"id": "talk", "label": "和%s聊聊" % walk_name, "npc": walk_cid}
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/fullbody/%s.png" % walk_cid,
					"和%s聊聊" % walk_name,
					func(): action_requested.emit(talk_walk)
				)
				hud_layout.add_npc_bubble(
					"Bubble_coast_npc",
					SceneStageLayers.bubble_anchor("arete_coast_test", "slot_a"),
					walk_name,
					false,
					_action_preview_text("talk"),
					func(): action_requested.emit(talk_walk)
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
			if act3_pending:
				var dusk_item := {"id": "story_act3", "label": "与黄秋枫赴约"}
				if is_instance_valid(stage_layers):
					stage_layers.set_slot_actor(
						"slot_b",
						"res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png",
						"赴黄昏之约",
						func(): action_requested.emit(dusk_item)
					)
				_add_dock_action(dusk_item, "story", "主线")
				hud_layout.add_npc_bubble(
					"Bubble_huang_qiufeng",
					SceneStageLayers.bubble_anchor("old_park", "slot_b"),
					"黄秋枫",
					true,
					_action_preview_text("story_act3"),
					func(): action_requested.emit(dusk_item)
				)
			elif walk_unlocked and is_instance_valid(stage_layers):
				var talk_park := {"id": "talk", "label": "和%s聊聊" % walk_name, "npc": walk_cid}
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/fullbody/%s.png" % walk_cid,
					"和%s聊聊" % walk_name,
					func(): action_requested.emit(talk_park)
				)
				hud_layout.add_npc_bubble(
					"Bubble_park_npc",
					SceneStageLayers.bubble_anchor("old_park", "slot_a"),
					walk_name,
					false,
					_action_preview_text("talk"),
					func(): action_requested.emit(talk_park)
				)
			_add_dock_action({"id": "park_reflect", "label": "长椅追忆"}, "activity", "1活动")
			_add_dock_action({"id": "park_vending", "label": "查看街角贩卖机"}, "free", "免费")

		"arete_beach_test":
			if walk_unlocked and is_instance_valid(stage_layers):
				var talk_beach := {"id": "talk", "label": "和%s聊聊" % walk_name, "npc": walk_cid}
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/fullbody/%s.png" % walk_cid,
					"和%s聊聊" % walk_name,
					func(): action_requested.emit(talk_beach)
				)
				hud_layout.add_npc_bubble(
					"Bubble_beach_npc",
					SceneStageLayers.bubble_anchor("arete_beach_test", "slot_a"),
					walk_name,
					false,
					_action_preview_text("talk"),
					func(): action_requested.emit(talk_beach)
				)
			_add_dock_action({"id": "beach_rest", "label": "海边休整"}, "activity", "1活动")
			_add_dock_action({"id": "beach_observe", "label": "远眺海平线"}, "free", "免费")

		"dorm":
			_add_dock_action({"id": "sleep", "label": DayCycle.rest_label()}, "activity", "时段")
			_add_dock_action({"id": "dorm_desk", "label": "书桌整理 · 今日小结"}, "free", "免费")
			_add_dock_action({"id": "dorm_note", "label": "阅读门边信笺"}, "free", "免费")


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


func _on_day_changed() -> void:
	if is_instance_valid(stage_layers):
		stage_layers.apply_period_lighting()
		if location_id == "rooftop":
			var next_npc := CampusLife.rooftop_active_npc()
			if next_npc != _rooftop_npc_id:
				_rooftop_npc_id = next_npc
				var next_name := str(PhaseTwoContent.ACTORS.get(next_npc, {}).get("name", "同伴"))
				stage_layers.set_slot_actor(
					"slot_a",
					"res://assets/sprites/characters/phase_two/fullbody/%s.png" % next_npc,
					"和%s聊聊" % next_name,
					func(): action_requested.emit({"id": "talk", "npc": CampusLife.rooftop_active_npc()})
				)
				var talk_btn := refs.get("actions", {}).get("talk") as Button
				if is_instance_valid(talk_btn):
					talk_btn.text = "和%s聊聊" % next_name
				if is_instance_valid(hud_layout):
					var bubble := hud_layout.find_child("Bubble_rooftop_npc", true, false) as Button
					if is_instance_valid(bubble):
						bubble.text = next_name
	if is_instance_valid(hud_layout):
		hud_layout.refresh_status()
		return
	if is_instance_valid(clock):
		clock.text = GameState.get_detailed_time_string()
	var status := get_node_or_null("ConceptStatus") as Label
	if is_instance_valid(status):
		status.text = _footer_hint_text()


func _build_legacy_scene() -> void:
	var place_file := SceneDesignCatalog.place_path(location_id)
	var wide_place := place_file.replace(".png", "_wide.png")
	if ResourceLoader.exists(wide_place):
		var wide_bg := SchoolObjectUI.art(self, "WidePlaceBackground", wide_place, Rect2(-210, 0, 2340, 1080))
		wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		wide_bg.z_index = -3
	var background := SchoolObjectUI.art(self, "PlaceBackground", place_file)
	background.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(wide_place):
		background.self_modulate = Color(1, 1, 1, 0)
	elif background.texture != null and background.texture.get_width() > 2100:
		var native_wide := SchoolObjectUI.art(self, "WidePlaceBackground", place_file, Rect2(-210, 0, 2340, 1080))
		native_wide.stretch_mode = TextureRect.STRETCH_SCALE
		native_wide.z_index = -3
		background.self_modulate = Color(1, 1, 1, 0)
	SceneSurfaceUI.heading(self, str(config["title"]))
	clock = get_node("DayTime") as Label
	DayCycle.changed.connect(_on_day_changed)
	var map_button := SceneSurfaceUI.button(self, "OpenMap", "地区地图", Rect2(1470, 30, 250, 78), 28)
	map_button.pressed.connect(func(): map_requested.emit())
	DynamicUI.attach_hover_pop(map_button, 1.04)
	refs["map_button"] = map_button
	var menu := SceneSurfaceUI.button(self, "OpenMenu", "菜单", Rect2(1740, 30, 135, 78), 28)
	menu.pressed.connect(func(): menu_requested.emit())
	DynamicUI.attach_hover_pop(menu, 1.04)
	refs["menu"] = menu
	for item in config["objects"]:
		var id := str(item["id"])
		var label_text := str(item["label"])
		var activate := func(): select_object(id); action_requested.emit(item)
		var pair := SceneSurfaceUI.landmark(self, "Action_" + id, background.texture, item["polygon"], item["tag"], label_text, activate)
		objects[id] = pair["image"]
		refs["actions"][id] = pair["label"]
		DynamicUI.attach_hover_pop(pair["label"], 1.045)
		_wire_hover_preview(pair["label"], _action_preview_text(id))
		_wire_hover_preview(pair["image"], _action_preview_text(id))
	if config["objects"].is_empty():
		_build_legacy_context()
	var hint_slab := SchoolObjectUI.slab(self, "ConceptStatusBacking", Rect2(56, 1007, 940, 44), Color(0.11, 0.14, 0.21, 0.76))
	(hint_slab.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(12)
	hint_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint := SchoolObjectUI.text(self, "ConceptStatus", _footer_hint_text(), Rect2(72, 1011, 908, 36), 21, Color("#FFF7E7"))
	hint.clip_text = true
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_offset_y", 1)
	SceneSurfaceUI.finish_layering(self, background)
	_wire_focus()
	map_button.grab_focus.call_deferred()


func _footer_hint_text() -> String:
	return "%s · 点击亮点与人物互动 · Esc 返回地图" % DayCycle.activity_hint()


func _build_legacy_context() -> void:
	var place: Dictionary = CampusPlaces.PLACES[location_id]
	var actions: Array = place["actions"].filter(func(item): return item["id"] not in ["go", "preview"])
	if actions.is_empty():
		actions = place["actions"].duplicate(true)
	var panel := Panel.new()
	panel.name = "PlaceContext"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", SceneSkin.style("dialogue_sheet", Vector4.ZERO))
	add_child(panel)
	DaylightUI.place(panel, 72, 707, 1140, 285)
	var description := SchoolObjectUI.text(panel, "LocationDescription", str(place["description"]), Rect2(42, 30, 1055, 125), 29, SceneSkin.INK)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.clip_text = true
	for i in mini(3, actions.size()):
		var item: Dictionary = actions[i]
		var id := str(item["id"]) + str(i)
		var button := SceneSurfaceUI.button(panel, "Action_" + id, str(item["label"]), Rect2(40 + i * 355, 184, 335, 71), 25)
		button.pressed.connect(func(): action_requested.emit(item))
		refs["actions"][id] = button
		_wire_hover_preview(button, _action_preview_text(str(item["id"])))


func _wire_hover_preview(control: Control, copy: String) -> void:
	if control == null or copy == "":
		return
	var set_tip := func():
		var status := get_node_or_null("ConceptStatus") as Label
		if is_instance_valid(status):
			status.text = copy
	var reset_tip := func():
		var status := get_node_or_null("ConceptStatus") as Label
		if is_instance_valid(status):
			status.text = _footer_hint_text()
	control.mouse_entered.connect(set_tip)
	control.focus_entered.connect(set_tip)
	control.mouse_exited.connect(reset_tip)
	control.focus_exited.connect(reset_tip)


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
	return _footer_hint_text()


func _wire_focus() -> void:
	var order: Array = [refs["menu"], refs["map_button"]] + refs["actions"].values()
	for i in order.size():
		var button: BaseButton = order[i]
		button.focus_previous = button.get_path_to(order[posmod(i - 1, order.size())])
		button.focus_next = button.get_path_to(order[(i + 1) % order.size()])
		button.focus_neighbor_left = button.focus_previous
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_right = button.focus_next
		button.focus_neighbor_bottom = button.focus_next


func select_object(id: String = "") -> void:
	selected_id = id
	for key in objects:
		objects[key].set_selected(key == id)


func set_interactions_enabled(enabled: bool) -> void:
	if _use_unified and is_instance_valid(hud_layout):
		hud_layout.set_interactions_enabled(enabled)
		if is_instance_valid(stage_layers):
			stage_layers.set_slot_hit_enabled(enabled)
		return
	get_node("ConceptStatus").visible = enabled
	var status_backing := get_node_or_null("ConceptStatusBacking") as CanvasItem
	if status_backing != null:
		status_backing.visible = enabled
	for image in objects.values():
		image.disabled = not enabled
	for button in refs["actions"].values():
		button.disabled = not enabled
		button.visible = enabled
	refs["map_button"].disabled = not enabled
	refs["menu"].disabled = not enabled
