class_name SceneObjectView
extends Control

signal action_requested(item: Dictionary)
signal map_requested
signal menu_requested
var location_id := ""
var config: Dictionary
var refs: Dictionary = {"actions":{}}
var objects: Dictionary = {}
var selected_id := ""
var clock: Label
var _actor_layer: Control

func _ready() -> void:
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	config = SceneDesignCatalog.place_config(location_id)
	var place_file := SceneDesignCatalog.place_path(location_id)
	var wide_place := place_file.replace(".png","_wide.png")
	if ResourceLoader.exists(wide_place):
		var wide_bg := SchoolObjectUI.art(self,"WidePlaceBackground",wide_place,Rect2(-210,0,2340,1080))
		wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		wide_bg.z_index = -3
	var background := SchoolObjectUI.art(self,"PlaceBackground",place_file)
	background.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(wide_place):
		background.self_modulate = Color(1,1,1,0)
	elif background.texture != null and background.texture.get_width() > 2100:
		var native_wide := SchoolObjectUI.art(self,"WidePlaceBackground",place_file,Rect2(-210,0,2340,1080))
		native_wide.stretch_mode = TextureRect.STRETCH_SCALE
		native_wide.z_index = -3
		background.self_modulate = Color(1,1,1,0)
	_build_resident_actors()
	SceneSurfaceUI.heading(self,str(config["title"]))
	clock = get_node("DayTime") as Label
	DayCycle.changed.connect(_on_day_changed)
	var map_button := SceneSurfaceUI.button(self,"OpenMap","地区地图",Rect2(1470,30,250,78),28)
	map_button.pressed.connect(func(): map_requested.emit())
	DynamicUI.attach_hover_pop(map_button, 1.04)
	refs["map_button"] = map_button
	var menu := SceneSurfaceUI.button(self,"OpenMenu","菜单",Rect2(1740,30,135,78),28)
	menu.pressed.connect(func(): menu_requested.emit())
	DynamicUI.attach_hover_pop(menu, 1.04)
	refs["menu"] = menu
	var park_open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
	var park_story := not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false)) and PlayerJourney.act2_combat_ready()
	for item in config["objects"]:
		var id := str(item["id"])
		var label_text := str(item["label"])
		if id == "enter_old_park":
			if not park_open:
				label_text = "旧公园（未开放）"
			elif park_story:
				label_text = "✦ 旧公园（黄昏之约）"
		var activate := func(): select_object(id); action_requested.emit(item)
		var pair := SceneSurfaceUI.landmark(self,"Action_"+id,background.texture,item["polygon"],item["tag"],label_text,activate)
		objects[id] = pair["image"]
		refs["actions"][id] = pair["label"]
		DynamicUI.attach_hover_pop(pair["label"], 1.045)
		if id == "enter_old_park" and park_story:
			DynamicUI.attach_float_bob(pair["label"], 3.5, 2.8)
			DynamicUI.attach_sheen(pair["label"], Color(1, 0.92, 0.72, 0.36), 10)
		_wire_hover_preview(pair["label"], _action_preview_text(id))
		_wire_hover_preview(pair["image"], _action_preview_text(id))
	if location_id == "library" and not GameState.visited_node_ids.has("n_affairs") and PlayerJourney.act1_story_ready():
		var story_btn := SceneSurfaceUI.button(self,"Action_story_act1","✦ 与黄秋枫交谈（主线）",Rect2(450,872,440,76),28)
		story_btn.pressed.connect(func(): action_requested.emit({"id":"story_act1","label":"✦ 与黄秋枫交谈（主线）"}))
		DynamicUI.attach_hover_pop(story_btn, 1.04)
		DynamicUI.attach_sheen(story_btn, Color(1, 0.92, 0.75, 0.34), 10)
		refs["actions"]["story_act1"] = story_btn
		_wire_hover_preview(story_btn, _action_preview_text("story_act1"))
	if config["objects"].is_empty(): _build_context()
	var hint_slab := SchoolObjectUI.slab(self,"ConceptStatusBacking",Rect2(56,1007,940,44),Color(0.11,0.14,0.21,0.76))
	(hint_slab.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(12)
	hint_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint := SchoolObjectUI.text(self,"ConceptStatus",_footer_hint_text(),Rect2(72,1011,908,36),21,Color("#FFF7E7"))
	hint.clip_text = true
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	hint.add_theme_constant_override("shadow_offset_y",1)
	SceneSurfaceUI.finish_layering(self,background)
	if is_instance_valid(_actor_layer):
		_actor_layer.z_index = -1
		var actor_index := background.get_index() + 1
		for child in get_children():
			if child is HomeObjectButton:
				actor_index = maxi(actor_index, child.get_index() + 1)
		move_child(_actor_layer, mini(actor_index, get_child_count() - 1))
	_wire_focus()
	map_button.grab_focus.call_deferred()

func _on_day_changed() -> void:
	if is_instance_valid(clock):
		clock.text = GameState.get_detailed_time_string()
	var status := get_node_or_null("ConceptStatus") as Label
	if is_instance_valid(status):
		status.text = _footer_hint_text()

func _exit_tree() -> void:
	if DayCycle.changed.is_connected(_on_day_changed):
		DayCycle.changed.disconnect(_on_day_changed)

func _footer_hint_text() -> String:
	return "%s · 点击亮点与人物互动 · Esc 返回地图" % DayCycle.activity_hint()

func _build_resident_actors() -> void:
	_actor_layer = Control.new()
	_actor_layer.name = "ResidentActors"
	_actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.size = Vector2(1920, 1080)
	_actor_layer.z_index = -1
	add_child(_actor_layer)
	match location_id:
		"library":
			_spawn_actor("ResidentLinZhiXia", "res://assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png", Rect2(1190, 270, 520, 810), false)
			if not GameState.visited_node_ids.has("n_affairs") and PlayerJourney.act1_story_ready():
				_spawn_actor("StoryHuangQiuFeng", "res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png", Rect2(410, 270, 520, 810), false)
		"shop":
			_spawn_actor("ResidentTangXiaoMan", "res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png", Rect2(1010, 270, 520, 810), false)
		"gym":
			if bool(GameState.companions.get("liu_yu_long", {}).get("unlocked", false)) or SaveManager.test_session:
				_spawn_actor("ResidentLiuYuLong", "res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png", Rect2(845, 250, 320, 720), true)
		"rooftop":
			if DayCycle.period() == "morning":
				_spawn_actor("ResidentYangZiYing", "res://assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png", Rect2(1290, 240, 320, 740), true)
			else:
				_spawn_actor("ResidentLiuYuLong", "res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png", Rect2(1290, 240, 320, 740), true)
		"old_park":
			if not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false)):
				_spawn_actor("StoryHuangQiuFeng", "res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png", Rect2(690, 270, 520, 810), false)

func _spawn_actor(node_name: String, path: String, rect: Rect2, with_shadow: bool) -> void:
	if not ResourceLoader.exists(path): return
	if with_shadow:
		DaylightUI.soft_ground_shadow(_actor_layer, node_name + "Shadow", Vector2(rect.position.x + rect.size.x * 0.5 - 105.0, rect.position.y + rect.size.y - 26.0), Vector2(210, 28))
	var actor := SchoolObjectUI.art(_actor_layer, node_name, path, rect)
	actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	actor.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_context() -> void:
	var place: Dictionary = CampusPlaces.PLACES[location_id]
	var actions: Array = []
	if location_id == "old_park" and not GameState.visited_node_ids.has("n_dusk") and not bool(GameState.story_flags.get("chapter_1_completed", false)):
		actions = [
			{"id": "story_act3", "label": "✦ 与黄秋枫赴约（主线）"},
			{"id": "park_vending", "label": "查看街角贩卖机"},
			{"id": "go", "target": "arete_coast_test", "label": "返回沿海公路"}
		]
	else:
		actions = place["actions"].filter(func(item): return item["id"] not in ["go","preview"])
		if actions.is_empty():
			actions = place["actions"].duplicate(true)
	var panel := Panel.new()
	panel.name = "PlaceContext"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",SceneSkin.style("dialogue_sheet",Vector4.ZERO))
	add_child(panel)
	DaylightUI.place(panel,72,707,1140,285)
	var description := SchoolObjectUI.text(panel,"LocationDescription",str(place["description"]),Rect2(42,30,1055,125),29,SceneSkin.INK)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.clip_text = true
	for i in mini(3, actions.size()):
		var item: Dictionary = actions[i]
		var id := str(item["id"])+str(i)
		var button := SceneSurfaceUI.button(panel,"Action_"+id,str(item["label"]),Rect2(40+i*355,184,335,71),25)
		button.pressed.connect(func(): action_requested.emit(item))
		refs["actions"][id] = button
		_wire_hover_preview(button, _action_preview_text(str(item["id"])))

func _wire_hover_preview(control: Control, copy: String) -> void:
	if control == null or copy == "": return
	var set_tip := func():
		var status := get_node_or_null("ConceptStatus") as Label
		if is_instance_valid(status): status.text = copy
	var reset_tip := func():
		var status := get_node_or_null("ConceptStatus") as Label
		if is_instance_valid(status): status.text = _footer_hint_text()
	control.mouse_entered.connect(set_tip)
	control.focus_entered.connect(set_tip)
	control.mouse_exited.connect(reset_tip)
	control.focus_exited.connect(reset_tip)

func _action_preview_text(action_id: String) -> String:
	match action_id:
		"story_act1": return "✦ 第一幕主线 · 与图书馆窗边的黄秋枫开启「红月之问」剧情"
		"story_act3": return "✦ 第二幕主线 · 与旧公园长椅旁的黄秋枫赴黄昏之约"
		"library_study", "study": return "牌理研习（1活动点）→ 获得 +35 练习点，并新收录 1 篇《风物纪要》"
		"read_notes": return "翻阅风物纪要（0活动点）→ 免费回顾已在图书馆解锁的校园档案"
		"shop_work": return "店务兼职（1活动点）→ 获得 +100 零用钱，每完成 2 次额外获赠能量饮品"
		"shop": return "查看商品柜台（0活动点）→ 购买战术刻印卡、练习素材与补给，或回收多余材料"
		"training": return "模拟训练（入场无消耗）→ 探索随机校园演练路线，提升卡匣实力与放映室记录"
		"qualifier": return "阿瑞忒代表选拔赛（0活动点开启）→ 迎战 3 轮校内切磋，赢取「阿瑞忒代表通行章」"
		"workshop": return "整理行动卡（0活动点）→ 编辑出战卡匣与强化卡牌等级"
		"rooftop_review": return "午后复盘（1活动点）→ 恢复 40 点体力 · +20 练习点 · +12 当前随行同伴好感"
		"coast_walk": return "海风漫步（1活动点）→ +15 练习点，与当前随行同伴提升 +15 默契好感"
		"beach_rest": return "海边休整（1活动点）→ 恢复 35 点体力 · 普通材料 ×2 · 同伴好感 +10"
		"park_reflect": return "长椅追忆（1活动点）→ 恢复 30 点体力 · +30 练习点 · 寻回旧公园细节记录"
		"enter_old_park":
			var open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			if not open:
				return "旧公园小径（尚未开放）· 需先前往「图书馆」推动第一幕主线剧情"
			return "沿树荫小径进入校外「旧公园」· 通往第二幕主线赴约与长椅追忆（0活动消耗）"
		"go":
			if location_id == "arete_coast_test":
				return "沿海石阶下行前往「阿瑞忒海滩」· 休息与拾取材料（0活动消耗）"
			return "沿原路返回上一处场景"
		"talk": return "同伴日常交谈（0活动点）→ 了解线索，每时段首次交谈额外提升 +8 好感度"
		"dorm_desk": return "查看今日统计（0活动点）→ 检查剩余活动与当前阿瑞忒收集进度"
		"sleep": return "回房过夜休息 → 恢复全部体力并推进至次日早晨"
	return _footer_hint_text()

func _wire_focus() -> void:
	var order: Array = [refs["menu"],refs["map_button"]]+refs["actions"].values()
	for i in order.size():
		var button: BaseButton = order[i]
		button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
		button.focus_next = button.get_path_to(order[(i+1)%order.size()])
		button.focus_neighbor_left = button.focus_previous
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_right = button.focus_next
		button.focus_neighbor_bottom = button.focus_next

func select_object(id: String = "") -> void:
	selected_id = id
	for key in objects: objects[key].set_selected(key == id)

func set_interactions_enabled(enabled: bool) -> void:
	get_node("ConceptStatus").visible = enabled
	var status_backing := get_node_or_null("ConceptStatusBacking") as CanvasItem
	if status_backing != null: status_backing.visible = enabled
	for image in objects.values(): image.disabled = not enabled
	for button in refs["actions"].values():
		button.disabled = not enabled
		button.visible = enabled
	refs["map_button"].disabled = not enabled
	refs["menu"].disabled = not enabled
