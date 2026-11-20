class_name CampusScreen
extends Control

const DESIGN := Vector2(1920,1080)
var presentation: Control
var refs: Dictionary = {}
var location_id := "map"
var dialogue: CampusDialogueUI
var _sleep_confirm := false
var _busy := false
var _fade: ColorRect
var system_menu: GameMenu
var _workspace: Control
var _workspace_focus: Control
var object_home: RegionHomeView
var scene_objects: SceneObjectView
var _qualifier_backdrop: ColorRect
var _qualifier_modal: Panel
var _companion_backdrop: ColorRect
var _companion_modal: Panel
var _reward_toast: Panel
var _toast_tween: Tween
var _menu_return_focus: Control
var _modal_return_focus: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	location_id = CampusLife.current_location
	presentation = Control.new()
	presentation.name = "CampusPresentation"
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.size = DESIGN
	add_child(presentation)
	_build_place()
	if GameState.archive_return_tab != "" and RegionCatalog.is_home(location_id):
		_restore_records.call_deferred()
	GameState.game_time_changed.connect(_refresh_clock)
	AudioManager.play_bgm_for_scene(SceneManager.TargetScene.CAMPUS_LIFE)
	resized.connect(_layout)
	_layout()

func _exit_tree() -> void:
	if GameState.game_time_changed.is_connected(_refresh_clock):
		GameState.game_time_changed.disconnect(_refresh_clock)
	if is_instance_valid(_toast_tween):
		_toast_tween.kill()

func _layout() -> void:
	var background_tex: Texture2D = null
	var edge_color := Color("#242A32")
	var wide_shop := presentation.find_child("WideShopBackground",true,false) as TextureRect
	if wide_shop != null and wide_shop.visible and wide_shop.texture != null: background_tex = wide_shop.texture
	var wide_room := presentation.find_child("WideRoomBackground",true,false) as TextureRect
	if background_tex == null and wide_room != null and wide_room.texture != null: background_tex = wide_room.texture
	var wide_place := presentation.find_child("WidePlaceBackground",true,false) as TextureRect
	if background_tex == null and wide_place != null and wide_place.texture != null: background_tex = wide_place.texture
	if is_instance_valid(scene_objects) and is_instance_valid(scene_objects.stage_layers):
		if background_tex == null:
			background_tex = scene_objects.stage_layers.primary_wide_texture()
		edge_color = scene_objects.stage_layers.stage_edge_color()
	var place_bg := presentation.find_child("PlaceBackground",true,false) as TextureRect
	if background_tex == null and place_bg != null: background_tex = place_bg.texture
	var room_bg := presentation.find_child("RoomBackground",true,false) as TextureRect
	if background_tex == null and room_bg != null: background_tex = room_bg.texture
	Platform.fit_stage(self,presentation,edge_color,background_tex)

func _button(parent: Control, node_name: String, copy: String, rect: Rect2, primary: bool = false) -> Button:
	var button := SchoolObjectUI.hit(parent,node_name,rect,copy,27)
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
		var tint := Color.WHITE
		if state == "hover": tint = Color(1.08,1.04,0.95)
		elif state in ["pressed","hover_pressed"]: tint = Color(0.83,0.87,0.91)
		elif state == "disabled": tint = Color(0.72,0.73,0.76)
		button.add_theme_stylebox_override(state,SceneSkin.style("button_lavender" if primary else "button_plain",Vector4(24,10,24,10),tint))
	SchoolObjectUI.borderless(button)
	button.disabled = _busy
	return button

func _build_place() -> void:
	if not CampusPlaces.PLACES.has(location_id): _travel("map"); return
	var data: Dictionary = CampusPlaces.PLACES[location_id]
	if RegionHomeView.artwork_available(location_id):
		_build_object_home()
		return
	if not SceneDesignCatalog.place_config(location_id).is_empty():
		_build_scene_objects()
		return
	if data.get("test",false):
		_build_test_place(data)
		return
	if data.get("geometry",false): _build_geometry_place(data)
	else:
		var place_path := "res://assets/backgrounds/phase_two/%s.png" % str(data.get("background",""))
		var wide_path := place_path.replace(".png","_wide.png")
		if ResourceLoader.exists(wide_path):
			var wide_bg := SchoolObjectUI.art(presentation,"WidePlaceBackground",wide_path,Rect2(-210,0,2340,1080))
			wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		if ResourceLoader.exists(place_path):
			var place_bg := SchoolObjectUI.art(presentation,"PlaceBackground",place_path)
			if ResourceLoader.exists(wide_path): place_bg.self_modulate = Color(1,1,1,0)
	var npc_id := str(data.get("npc",""))
	if npc_id != "": _build_actor(npc_id)
	var title := _button(presentation,"LocationTitle",str(data["title"]),Rect2(62,28,600,87))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.focus_mode = Control.FOCUS_NONE
	title.add_theme_font_size_override("font_size",38)
	var time := SchoolObjectUI.text(presentation,"DayTime",GameState.get_detailed_time_string(),Rect2(690,45,620,55),25,Color("#FFF8E8"),true)
	if data.get("geometry",false):
		time.add_theme_color_override("font_color",Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]))
	time.add_theme_constant_override("outline_size",0 if data.get("geometry",false) else 3)
	time.add_theme_color_override("font_outline_color",Color("#3E4D6C"))
	var map_button := _button(presentation,"OpenMap",str(RegionCatalog.REGIONS[CampusLife.current_region]["title"])+"地图",Rect2(1560,30,285,80))
	map_button.pressed.connect(_travel.bind("map"))
	refs["map_button"] = map_button
	var menu := _button(presentation,"OpenMenu","菜单",Rect2(1350,30,180,80))
	menu.pressed.connect(_open_menu)
	var actions: Array = data["actions"]
	refs["actions"] = {}
	for index in actions.size():
		var item: Dictionary = actions[index]
		var button := _button(presentation,"Action_"+str(item["id"]),str(item["label"]),Rect2(105+index*580,963,550,76),index == 0)
		button.pressed.connect(_action.bind(item))
		refs["actions"][item["id"]] = button
	if data.get("geometry",false):
		var strip := SchoolObjectUI.slab(presentation,"DescriptionBacking",Rect2(95,869,1730,82),Color(0.12,0.17,0.22,0.88))
		strip.set_meta("role","readable_description")
	var intro := SchoolObjectUI.text(presentation,"LocationDescription",str(data["description"]),Rect2(112,884,1110,59),26,Color("#FFF8EB"))
	intro.add_theme_color_override("font_outline_color",Color("#374562"))
	intro.add_theme_constant_override("outline_size",3)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.clip_text = true

func _build_geometry_place(data: Dictionary) -> void:
	var geometry := RegionGeometry.new()
	geometry.name = "GeometricPlaceLayout"
	geometry.region_id = CampusLife.current_region
	geometry.place_id = location_id
	presentation.add_child(geometry)
	SchoolObjectUI.text(presentation,"GeometryCaption","体育馆 · 训练入口" if location_id == "gym" else "空间布局 · "+str(RegionCatalog.REGIONS[CampusLife.current_region]["title"]),Rect2(110,180,1100,70),40,Color(RegionCatalog.REGIONS[CampusLife.current_region]["accent"]))
	var zones: Array = RegionCatalog.PLACE_ZONES.get(location_id,["入口","主要功能区","交流区"])
	for i in zones.size():
		var plate := SchoolObjectUI.slab(presentation,"ZonePlate"+str(i),Rect2(560+i*330,540+(i%2)*80,290,82),Color(RegionCatalog.REGIONS[CampusLife.current_region]["paper"]))
		SchoolObjectUI.text(plate,"ZoneName",str(zones[i]),Rect2(8,14,274,55),25,Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]),true)
	var note := SchoolObjectUI.text(presentation,"PlacePurpose",str(data["description"]),Rect2(110,266,1450,70),28,Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _open_menu() -> void:
	if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(_workspace) or is_instance_valid(system_menu) or is_instance_valid(_qualifier_modal) or is_instance_valid(_companion_modal): return
	_menu_return_focus = get_viewport().gui_get_focus_owner()
	_set_actions_visible(false)
	system_menu = GameMenu.new()
	presentation.add_child(system_menu)
	set_meta("region_modal_open",true)
	system_menu.close_requested.connect(func():
		system_menu.queue_free()
		system_menu = null
		set_meta("region_modal_open",false)
		_set_actions_visible(true)
		if is_instance_valid(_menu_return_focus) and _menu_return_focus.is_inside_tree():
			_menu_return_focus.grab_focus()
		_menu_return_focus = null
	)

func _restore_records() -> void:
	if SceneManager.is_transitioning: await SceneManager.scene_transition_completed
	if not is_inside_tree(): return
	var tab := GameState.archive_return_tab
	GameState.archive_return_tab = ""
	_open_workspace("records",{"tab":tab})

func _open_workspace(kind: String, context: Dictionary = {}) -> void:
	if SceneManager.is_transitioning or is_instance_valid(_workspace) or is_instance_valid(dialogue) or is_instance_valid(system_menu): return
	if kind == "training" and location_id != "gym": return
	if is_instance_valid(object_home) and kind in ["workshop","records"]: object_home.select_object(kind)
	_workspace_focus = get_viewport().gui_get_focus_owner()
	if kind == "training": _workspace = CampusGuidePanel.create("quest",context)
	elif kind == "zodiac": _workspace = ZodiacAlbumPanel.create("zodiac",context)
	elif kind in ["records","warehouse"]:
		var records_context := context.duplicate(true)
		if kind == "warehouse" and not records_context.has("tab"): records_context["tab"] = "warehouse"
		_workspace = PlayerWorkspace.create("records",records_context)
	elif kind == "shop":
		if not CampusShopCatalog.is_shop_location(location_id): return
		var shop_panel := CampusShopPanel.create()
		_workspace = shop_panel
		if is_instance_valid(scene_objects):
			scene_objects.set_shop_split_mode(true)
			if is_instance_valid(scene_objects.stage_layers) and location_id == "shop":
				shop_panel.clerk_reacted.connect(_on_shop_clerk_reacted)
	else: _workspace = PlayerWorkspace.create("workshop",context)
	_workspace.name = "LocationWorkspace"
	if _workspace is PlayerWorkspace:
		add_child(_workspace)
		_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		presentation.add_child(_workspace)
	_layout()
	set_meta("region_modal_open",true)
	_workspace.close_requested.connect(_close_workspace)
	_workspace.action_requested.connect(_workspace_action)
	var close := _workspace.find_child("CloseButton",true,false) as Button
	if close != null:
		var focus_close := func():
			if is_instance_valid(close) and close.is_inside_tree(): close.grab_focus()
		focus_close.call_deferred()

func _on_shop_clerk_reacted(emotion: String, _line: String) -> void:
	if not is_instance_valid(scene_objects) or not is_instance_valid(scene_objects.stage_layers) or location_id != "shop":
		return
	if scene_objects.stage_layers.is_slot_staged("slot_a"):
		if emotion == "happy":
			scene_objects.stage_layers.pulse_slot_actor("slot_a")
		return
	var tex_path := "res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_%s.png" % ("happy" if emotion == "happy" else "neutral")
	scene_objects.stage_layers.set_slot_texture("slot_a", tex_path)

func _close_workspace() -> void:
	if not is_instance_valid(_workspace): return
	var panel := _workspace
	_workspace = null
	panel.hide()
	var panel_parent := panel.get_parent()
	if panel_parent != null: panel_parent.remove_child(panel)
	panel.queue_free()
	if is_instance_valid(scene_objects):
		scene_objects.set_shop_split_mode(false)
		if is_instance_valid(scene_objects.stage_layers) and location_id == "shop":
			scene_objects.stage_layers.set_slot_texture("slot_a", "res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png")
	_layout()
	set_meta("region_modal_open",false)
	if is_instance_valid(object_home): object_home.select_object()
	if is_instance_valid(scene_objects): scene_objects.select_object()
	if is_instance_valid(_workspace_focus) and _workspace_focus.is_inside_tree(): _workspace_focus.grab_focus()

func _workspace_action(action: String, payload: Dictionary) -> void:
	if SceneManager.is_transitioning or not is_instance_valid(_workspace): return
	var message := ""
	match action:
		"close": _close_workspace(); return
		"shop_talk":
			_close_workspace()
			_action({"id":"talk"})
			return
		"start_exploration":
			if location_id != "gym": return
			if GameState.start_exploration(str(payload.get("dungeon_id",""))): _close_workspace()
			else: _workspace.refresh({"message":"这条路线暂不可用，请先继续或结束当前训练。"})
			return
		"open_workshop": _close_workspace(); _open_workspace("workshop"); return
		"open_records": _close_workspace(); _open_workspace("records"); return
		"open_zodiac": _close_workspace(); _open_workspace("zodiac"); return
		"open_quest": _close_workspace(); _travel("map"); return
		"select_card": _workspace.refresh({"selected_card_id":str(payload.get("card_id",""))}); return
		"save_loadout","apply_loadout":
			var index := int(payload.get("index",0))
			var ok := PlayerJourney.save_loadout(index,payload.get("card_ids",GameState.equipped_card_ids)) if action == "save_loadout" else PlayerJourney.apply_loadout(index)
			message = ("卡组方案已保存" if action == "save_loadout" else "卡组方案已应用") if ok else "方案不可用，卡组至少保留一张攻击卡。"
		"upgrade_card":
			var id := str(payload.get("card_id",""))
			var quality := str(payload.get("quality","common"))
			message = "练习完成，行动卡已经提升" if GameState.upgrade_card(id,quality) else str(PlayerJourney.training_quote(id,quality)["reason"])
		"claim_milestone": message = "成长奖励已放入仓库" if PlayerJourney.claim_milestone(str(payload.get("id",""))) else "尚未达成或已经领取。"
		"use_drink": message = "已恢复体力" if PlayerJourney.use_drink() else "请在地区 Home 使用补给，并确认体力与库存。"
		"start_chapter":
			_close_workspace()
			CampusLife.travel_to("club")
			return
		"replay_memory":
			if PlayerJourney.open_memory(str(payload.get("dialogue_id",""))): _close_workspace()
			return
	_workspace.refresh({"message":message})

func _build_actor(npc_id: String) -> void:
	var spec: Dictionary = CampusPlaces.NPCS[npc_id]
	var actor := SchoolObjectUI.art(presentation,"ResidentNPC","",Rect2(-30,70,1920,1000))
	var tex_path := str(spec.get("path", ""))
	if tex_path != "" and ResourceLoader.exists(tex_path):
		actor.texture = load(tex_path)
		DaylightUI.place(actor,1130,130,620,880)
	actor.set_meta("npc_id",npc_id)
	refs["npc"] = actor

func _travel(target: String) -> void:
	if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(system_menu) or is_instance_valid(_workspace) or is_instance_valid(_qualifier_modal) or is_instance_valid(_companion_modal): return
	CampusLife.travel_to(target)

func _action(item: Dictionary) -> void:
	if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(_workspace) or is_instance_valid(system_menu) or is_instance_valid(_qualifier_modal) or is_instance_valid(_companion_modal): return
	match str(item["id"]):
		"story_act1": GameState.trigger_scene_story("n_affairs")
		"story_act3":
			if PlayerJourney.act2_combat_ready():
				GameState.trigger_scene_story("n_dusk")
			else:
				_show_dialogue([["叶舟","街区外围安全限幅器有些异常。赴黄秋枫之约前，先回卡牌工坊编满 5 张行动卡或将任意卡强化到 Lv.2 吧。"]])
		"qualifier": _open_qualifier_modal()
		"switch_companion": _open_companion_switcher()
		"library_study", "study": _run_activity(func(): return CampusLife.study_in_library())
		"read_notes": _show_dialogue(CampusLife.read_library_notes())
		"shop_work": _run_activity(func(): return CampusLife.work_in_shop())
		"rooftop_review": _run_activity(func(): return CampusLife.rooftop_review())
		"coast_walk": _run_activity(func(): return CampusLife.coast_walk())
		"beach_rest": _run_activity(func(): return CampusLife.beach_rest())
		"park_reflect": _run_activity(func(): return CampusLife.park_reflect())
		"dorm_desk":
			var acts := PlayerJourney.campus_activities_done()
			var notes_cnt: int = GameState.player_profile.get("reading_notes", []).size()
			_show_dialogue([["叶舟","%s。\n当前手头零用钱 %d · 练习点 %d · 已完成 %d 次校园活动 · 收录风物纪要 %d 篇。" % [GameState.get_detailed_time_string(), GameState.energy_crystals, GameState.scrap_metal, acts, notes_cnt]], ["叶舟","下一步目标：%s" % PhaseTwoContent.current_objective()]])
		"complete_visit": CampusLife.complete_first_visit()
		"partner_test": _show_dialogue([["旅途随行","当前正位于先导考察区域。同伴交流与正式章节将在后续地区篇开启。"]])
		"test_difficulty": _show_dialogue([["区域观察","前方区域的挑战规则将在后续章节进一步完善。"]])
		"go": _travel(str(item["target"]))
		"enter_old_park":
			var park_open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			if park_open:
				_travel("old_park")
			else:
				_show_dialogue([["叶舟","林荫小径另一侧通往校外旧公园，现在还是清晨校内时段。先回校园体验一下日常活动，并在图书馆找黄秋枫谈谈吧。"]])
		"talk":
			var explicit_npc := str(item.get("npc", ""))
			var npc_id := explicit_npc if explicit_npc != "" else _active_location_npc()
			_show_dialogue(CampusLife.npc_lines(npc_id), npc_id)
		"sleep": _confirm_sleep()
		"training": _open_workspace("training")
		"workshop": _open_workspace("workshop")
		"records": _open_workspace("records")
		"warehouse": _open_workspace("warehouse")
		"shop": _open_workspace("shop")
		"preview": _show_dialogue([["空间规划",str(CampusPlaces.PLACES[location_id]["description"])],["空间规划","地点已接入地区总图，正式剧情与专属系统将在这里补充。"]])
		_: _show_dialogue(CampusLife.inspect(str(item["id"])))

func _active_location_npc() -> String:
	if location_id == "rooftop":
		return CampusLife.rooftop_active_npc()
	if location_id in ["arete_coast_test", "arete_beach_test", "old_park"]:
		return CampusLife.active_walk_companion()
	return str(CampusPlaces.PLACES[location_id].get("npc", ""))

func _open_companion_switcher() -> void:
	_close_companion_switcher()
	_modal_return_focus = get_viewport().gui_get_focus_owner()
	set_meta("region_modal_open", true)
	_set_actions_visible(false)
	_companion_backdrop = ColorRect.new()
	_companion_backdrop.name = "CompanionBackdrop"
	_companion_backdrop.color = Color(0.14, 0.18, 0.27, 0.48)
	_companion_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_companion_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_companion_switcher()
	)
	presentation.add_child(_companion_backdrop)
	DaylightUI.place(_companion_backdrop, -600, -300, 3120, 1680)
	_companion_modal = Panel.new()
	_companion_modal.name = "CompanionSwitcherModal"
	if not DynamicUI.apply_nine_slice_panel(_companion_modal, DynamicUI.THEME_PAPER_MODAL, Vector4(72, 56, 44, 44)):
		var mstyle := StyleBoxFlat.new()
		mstyle.bg_color = Color("#FAF5E8")
		mstyle.border_color = Color("#C9B89B")
		mstyle.set_border_width_all(2)
		mstyle.set_corner_radius_all(12)
		mstyle.shadow_color = Color(0.10, 0.14, 0.22, 0.28)
		mstyle.shadow_size = 16
		_companion_modal.add_theme_stylebox_override("panel", mstyle)
	presentation.add_child(_companion_modal)
	DaylightUI.place(_companion_modal, 440, 180, 1040, 700)
	var title := SchoolObjectUI.text(_companion_modal, "SwitcherTitle", "切换随行协战同伴", Rect2(44, 30, 680, 50), 34, Color("#1E314D"))
	title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	SchoolObjectUI.text(_companion_modal, "SwitcherSub", "不消耗活动点 · 选定的同伴将在战斗中每 3 张卡触发协战，并陪同海岸与海滩散步。", Rect2(44, 82, 820, 34), 19, Color("#5A687D"))
	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "返回 ×"
	_companion_modal.add_child(close_btn)
	DaylightUI.place(close_btn, 864, 34, 136, 52)
	DynamicUI.make_cel_button(close_btn, Color("#FFFDF8"), Color("#1E314D"), Color("#4C75A6"), 20, 12)
	DaylightUI.bind_button_audio(close_btn)
	close_btn.pressed.connect(_close_companion_switcher)

	var active_cid := CampusLife.active_walk_companion()
	for i in PlayerJourney.COMPANION_ORDER.size():
		var cid := str(PlayerJourney.COMPANION_ORDER[i])
		var actor: Dictionary = PhaseTwoContent.ACTORS.get(cid, {})
		var comp_state: Dictionary = GameState.companions.get(cid, {})
		var unlocked := bool(comp_state.get("unlocked", false)) or SaveManager.test_session
		var favor := int(comp_state.get("favor", 0))
		var is_active := cid == active_cid
		var spec: Dictionary = PlayerJourney.companion_assist_spec(cid)
		var row := SchoolObjectUI.slab(_companion_modal, "CompanionRow_" + cid, Rect2(44, 138 + float(i) * 168.0, 952, 148), Color("#ECF7F5") if is_active else Color("#FFFDF8"))
		var comp_tint := Color(0.92, 0.97, 0.94, 1.0) if is_active else Color(1.0, 0.99, 0.96, 1.0)
		if not DynamicUI.apply_nine_slice_panel(row, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32), comp_tint):
			var rstyle := row.get_theme_stylebox("panel") as StyleBoxFlat
			rstyle.set_corner_radius_all(10)
			rstyle.border_color = Color("#359686") if is_active else Color("#D6CBB8")
			rstyle.set_border_width_all(2 if is_active else 1)
		var avatar_path := "res://assets/sprites/characters/phase_two/avatars/%s_neutral.png" % cid
		if not ResourceLoader.exists(avatar_path):
			avatar_path = "res://assets/sprites/characters/phase_two/portraits/%s.png" % cid
		SchoolObjectUI.art(row, "Avatar", avatar_path, Rect2(20, 16, 116, 116))
		SchoolObjectUI.text(row, "Name", "%s · 熟悉度 %d" % [str(actor.get("name", cid)), favor], Rect2(156, 16, 500, 38), 26, Color("#1E314D"))
		SchoolObjectUI.text(row, "Skill", "协战「%s」" % str(spec.get("skill", "")), Rect2(156, 56, 540, 32), 20, Color("#359686"))
		var summary_lbl := SchoolObjectUI.text(row, "Summary", str(spec.get("summary", "")) if unlocked else "继续推进主线结识同伴后即可邀请随行。", Rect2(156, 90, 560, 48), 18, Color("#5A687D"))
		summary_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		DaylightUI.place(summary_lbl, 156, 90, 560, 48)
		var pick_btn := Button.new()
		pick_btn.name = "SelectCompanion_" + cid
		pick_btn.text = "随行中 ✓" if is_active else ("设为随行" if unlocked else "待结识")
		pick_btn.disabled = (not unlocked) or is_active
		row.add_child(pick_btn)
		DaylightUI.place(pick_btn, 738, 42, 188, 64)
		DynamicUI.make_cel_button(pick_btn, Color("#359686") if is_active else Color("#FFFDF8"), Color("#FFFDF8") if is_active else Color("#1E314D"), Color("#359686"), 20, 12)
		DaylightUI.bind_button_audio(pick_btn)
		pick_btn.pressed.connect(func():
			if GameState.set_active_companion_id(cid) or SaveManager.test_session:
				GameState.player_profile["active_companion"] = cid
				GameState.profile_changed.emit()
				_close_companion_switcher()
				_show_toast_message("随行同伴已切换为「%s」" % str(actor.get("name", cid)))
		)
	close_btn.grab_focus.call_deferred()

func _close_companion_switcher() -> void:
	if is_instance_valid(_companion_modal):
		_companion_modal.queue_free()
		_companion_modal = null
	if is_instance_valid(_companion_backdrop):
		_companion_backdrop.queue_free()
		_companion_backdrop = null
	set_meta("region_modal_open", false)
	_set_actions_visible(true)
	if is_instance_valid(_modal_return_focus) and _modal_return_focus.is_inside_tree():
		_modal_return_focus.grab_focus()
	_modal_return_focus = null

func _open_qualifier_modal() -> void:
	if not bool(GameState.story_flags.get("chapter_1_completed", false)):
		_show_dialogue([["柳宇龙","选拔赛擂台正在筹备中！先去推完第一章《红月下的旧公园》，等明天社团晨会一开咱们就正式报名开打！"]])
		return
	_close_qualifier_modal()
	_modal_return_focus = get_viewport().gui_get_focus_owner()
	set_meta("region_modal_open", true)
	_set_actions_visible(false)
	_qualifier_backdrop = ColorRect.new()
	_qualifier_backdrop.name = "QualifierBackdrop"
	_qualifier_backdrop.color = Color(0.12, 0.16, 0.25, 0.56)
	_qualifier_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_qualifier_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_qualifier_modal()
	)
	presentation.add_child(_qualifier_backdrop)
	DaylightUI.place(_qualifier_backdrop, -600, -300, 3120, 1680)
	_qualifier_modal = Panel.new()
	_qualifier_modal.name = "QualifierModal"
	if not DynamicUI.apply_nine_slice_panel(_qualifier_modal, DynamicUI.THEME_PAPER_MODAL, Vector4(72, 56, 44, 44)):
		var qstyle := StyleBoxFlat.new()
		qstyle.bg_color = Color("#FAF5E8")
		qstyle.border_color = Color("#C9B89B")
		qstyle.set_border_width_all(2)
		qstyle.border_width_bottom = 5
		qstyle.set_corner_radius_all(12)
		qstyle.shadow_color = Color(0.10, 0.14, 0.22, 0.30)
		qstyle.shadow_size = 18
		_qualifier_modal.add_theme_stylebox_override("panel", qstyle)
	presentation.add_child(_qualifier_modal)
	DaylightUI.place(_qualifier_modal, 240, 130, 1440, 820)

	var title_lbl := SchoolObjectUI.text(_qualifier_modal, "QualifierTitle", "阿瑞忒巡回代表选拔赛", Rect2(44, 28, 720, 50), 38, Color("#1E314D"))
	title_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var done_all := bool(GameState.story_flags.get("arete_qualifier_completed", false))
	var subtitle_copy := "★ 已全胜赢得「阿瑞忒代表通行章」，可随时重温挑战或前往巡回总图预览诺莫斯。" if done_all else "按顺序赢得 3 轮非致命学园护盾裁决，赢取「阿瑞忒代表通行章」前往第二站诺莫斯。"
	SchoolObjectUI.text(_qualifier_modal, "QualifierSub", subtitle_copy, Rect2(44, 80, 960, 32), 20, Color("#5A687D"))
	if done_all:
		var atlas_btn := Button.new()
		atlas_btn.name = "AtlasPreviewButton"
		atlas_btn.text = "巡回总图 →"
		_qualifier_modal.add_child(atlas_btn)
		DaylightUI.place(atlas_btn, 1044, 30, 194, 56)
		DynamicUI.make_cel_button(atlas_btn, Color("#D48A30"), Color("#FFFDF8"), Color("#B8701E"), 20, 12)
		DaylightUI.bind_button_audio(atlas_btn)
		atlas_btn.pressed.connect(func():
			_close_qualifier_modal()
			CampusLife.open_region_atlas()
		)
	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "返回 ×"
	_qualifier_modal.add_child(close_btn)
	DaylightUI.place(close_btn, 1254, 30, 148, 56)
	DynamicUI.make_cel_button(close_btn, Color("#FFFDF8"), Color("#1E314D"), Color("#4C75A6"), 20, 12)
	DaylightUI.bind_button_audio(close_btn)
	close_btn.pressed.connect(_close_qualifier_modal)

	# Left Arena Status Column (watercolor index card)
	var left_col := SchoolObjectUI.slab(_qualifier_modal, "QualifierLeftCol", Rect2(40, 126, 404, 656), Color("#FFFDF8"))
	if not DynamicUI.apply_nine_slice_panel(left_col, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32), Color(1.0, 0.99, 0.97, 1.0)):
		var lc_style := left_col.get_theme_stylebox("panel") as StyleBoxFlat
		lc_style.border_color = Color("#D2C5AF")
		lc_style.set_border_width_all(2)
		lc_style.set_corner_radius_all(10)

	var yz_avatar := "res://assets/sprites/characters/phase_two/avatars/ye_zhou_%s.png" % ("happy" if done_all else "neutral")
	SchoolObjectUI.art(left_col, "PlayerAvatar", yz_avatar, Rect2(26, 24, 108, 108))
	var wins := 0
	for spec_chk in PlayerJourney.QUALIFIER_ROUNDS:
		if bool(GameState.story_flags.get(str(spec_chk["flag"]), false)):
			wins += 1
	SchoolObjectUI.text(left_col, "RepName", "叶舟", Rect2(150, 26, 230, 38), 28, Color("#1E314D"))
	SchoolObjectUI.text(left_col, "RepRank", "★ 阿瑞忒首席代表" if done_all else "代表资格进度 %d / 3 胜" % wins, Rect2(150, 68, 236, 30), 19, Color("#D45B49") if not done_all else Color("#359686"))
	SchoolObjectUI.text(left_col, "RepRule", "护盾裁决规则 · 非致命切磋", Rect2(150, 98, 236, 28), 17, Color("#5A687D"))
	SchoolObjectUI.rule(left_col, "LeftDiv1", Rect2(24, 152, 356, 2))

	var deck_info := PlayerJourney.deck_summary()
	var deck_ok := bool(deck_info["ready"])
	SchoolObjectUI.text(left_col, "DeckCap", "当前出战卡匣（%d / 5）" % int(deck_info["count"]), Rect2(26, 170, 352, 32), 21, Color("#1E314D"))
	SchoolObjectUI.text(left_col, "DeckText", str(deck_info["text"]), Rect2(26, 206, 352, 30), 18, Color("#359686") if deck_ok else Color("#D45B49"))

	var comp_id := CampusLife.active_walk_companion()
	var comp_name := str(PhaseTwoContent.ACTORS.get(comp_id, {}).get("name", "杨子英"))
	var comp_spec: Dictionary = PlayerJourney.companion_assist_spec(comp_id)
	SchoolObjectUI.text(left_col, "AssistCap", "随行协战：%s" % comp_name, Rect2(26, 258, 352, 30), 20, Color("#1E314D"))
	var assist_lbl := SchoolObjectUI.text(left_col, "AssistDesc", str(comp_spec.get("summary", "")), Rect2(26, 290, 352, 62), 17, Color("#5A687D"))
	assist_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	DaylightUI.place(assist_lbl, 26, 290, 352, 62)

	var z_id := GameState.get_active_zodiac_id()
	var z_spec: Dictionary = PlayerJourney.zodiac_resonance_spec(z_id)
	SchoolObjectUI.text(left_col, "ZodiacCap", "星座共鸣：%s" % str(z_spec.get("title", "尚未激活共鸣")), Rect2(26, 370, 352, 30), 20, Color("#1E314D"))
	var z_lbl := SchoolObjectUI.text(left_col, "ZodiacDesc", str(z_spec.get("summary", "可在社团星座图鉴切换白羊座共鸣。")), Rect2(26, 402, 352, 62), 17, Color("#5A687D"))
	z_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	DaylightUI.place(z_lbl, 26, 402, 352, 62)

	var workshop_btn := Button.new()
	workshop_btn.name = "GotoWorkshopBtn"
	workshop_btn.text = "整备行动卡匣 →"
	left_col.add_child(workshop_btn)
	DaylightUI.place(workshop_btn, 26, 566, 352, 62)
	DynamicUI.make_cel_button(workshop_btn, Color("#F3F6FA"), Color("#1E314D"), Color("#359686"), 21, 14)
	DaylightUI.bind_button_audio(workshop_btn)
	workshop_btn.pressed.connect(func():
		_close_qualifier_modal()
		_open_workspace("workshop")
	)

	# Right Column: 3 Opponent Schedule Cards
	for i in PlayerJourney.QUALIFIER_ROUNDS.size():
		var spec: Dictionary = PlayerJourney.QUALIFIER_ROUNDS[i]
		var r_idx := int(spec["round"])
		var won := bool(GameState.story_flags.get(str(spec["flag"]), false))
		var prev_won := r_idx == 1 or bool(GameState.story_flags.get("qualifier_r%d_won" % (r_idx - 1), false))
		var unlocked := prev_won and deck_ok
		var card_y := 126.0 + float(i) * 224.0
		var row := SchoolObjectUI.slab(_qualifier_modal, "RoundRow_%d" % r_idx, Rect2(464, card_y, 936, 206), Color("#EFF7F5") if won else Color("#FFFDF8"))
		var row_tint := Color(1.0, 0.95, 0.91, 1.0) if (prev_won and not won) else (Color(0.93, 0.97, 0.94, 1.0) if won else Color(1.0, 0.99, 0.97, 1.0))
		if not DynamicUI.apply_nine_slice_panel(row, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32), row_tint):
			var row_style := row.get_theme_stylebox("panel") as StyleBoxFlat
			row_style.border_color = Color("#D45B49") if (prev_won and not won) else (Color("#359686") if won else Color("#D0C3AD"))
			row_style.set_border_width_all(2 if (prev_won and not won) else 1)
			row_style.set_corner_radius_all(10)

		var enemy_list: Array = spec.get("enemies", ["duel_student_ace"])
		var lead_enemy := str(enemy_list[0])
		var enemy_path := "res://assets/sprites/characters/phase_two/portraits/liu_yu_long.png" if lead_enemy == "arena_tactician" else CombatSkin.enemy_combat_path(lead_enemy)
		var portrait_frame := SchoolObjectUI.slab(row, "EnemyFrame", Rect2(18, 18, 154, 170), Color("#F2ECE0"))
		(portrait_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(12)
		var enemy_art := SchoolObjectUI.art(portrait_frame, "EnemyPortrait", enemy_path, Rect2(6, 6, 142, 158))
		enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		var state_tag := "已通关 · 可再战" if won else ("可登台" if unlocked else ("需要先胜第%d战" % (r_idx - 1) if not prev_won else GameState.DECK_RULE_MESSAGE))
		var title_r := SchoolObjectUI.text(row, "Title", str(spec["title"]), Rect2(192, 20, 480, 40), 27, Color("#1E314D"))
		title_r.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		var sub_r := SchoolObjectUI.text(row, "Sub", str(spec["subtitle"]), Rect2(192, 66, 490, 56), 19, Color("#5A687D"))
		sub_r.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		DaylightUI.place(sub_r, 192, 66, 490, 56)
		var pass_note := " · 阿瑞忒代表通行章" if r_idx == 3 else ""
		SchoolObjectUI.text(row, "Reward", "奖励：零用钱 %d · 练习点 %d%s   |   %s" % [int(spec["money"]), int(spec["points"]), pass_note, state_tag], Rect2(192, 138, 500, 44), 18, Color("#D45B49") if not won else Color("#359686"))

		var challenge := Button.new()
		challenge.name = "Challenge_%d" % r_idx
		challenge.text = "再次切磋" if won else ("登台挑战" if unlocked else "待解锁")
		challenge.disabled = not unlocked
		row.add_child(challenge)
		DaylightUI.place(challenge, 704, 68, 208, 70)
		var c_fill := Color("#D45B49") if (prev_won and not won) else (Color("#359686") if won else Color("#DFDBD2"))
		var c_ink := Color("#FFFDF8") if unlocked else Color("#6A7485")
		DynamicUI.make_cel_button(challenge, c_fill, c_ink, c_fill, 21, 14)
		DaylightUI.bind_button_audio(challenge)
		challenge.pressed.connect(func():
			_close_qualifier_modal()
			GameState.start_qualifier_battle(r_idx)
		)
	close_btn.grab_focus.call_deferred()

func _close_qualifier_modal() -> void:
	if is_instance_valid(_qualifier_modal):
		_qualifier_modal.queue_free()
		_qualifier_modal = null
	if is_instance_valid(_qualifier_backdrop):
		_qualifier_backdrop.queue_free()
		_qualifier_backdrop = null
	set_meta("region_modal_open", false)
	_set_actions_visible(true)
	if is_instance_valid(_modal_return_focus) and _modal_return_focus.is_inside_tree():
		_modal_return_focus.grab_focus()
	_modal_return_focus = null

func _show_dialogue(lines: Array, npc_override: String = "") -> void:
	if lines.is_empty() or is_instance_valid(dialogue): return
	set_meta("campus_dialogue_open",true)
	var return_focus := get_viewport().gui_get_focus_owner()
	_set_actions_visible(false)
	dialogue = CampusDialogueUI.new()
	dialogue.lines = lines
	presentation.add_child(dialogue)
	dialogue.closed.connect(func():
		dialogue = null
		set_meta("campus_dialogue_open",false)
		_set_actions_visible(true)
		if is_instance_valid(object_home): object_home.select_object()
		if is_instance_valid(scene_objects): scene_objects.select_object()
		if is_instance_valid(return_focus) and return_focus.is_inside_tree(): return_focus.grab_focus()
	)
	var npc_id := npc_override if npc_override != "" else str(CampusPlaces.PLACES[location_id].get("npc",""))
	if npc_id == "rooftop" or npc_id == "":
		npc_id = _active_location_npc()
	var speaker := str(lines[0][0])
	if dialogue.portrait.texture == null and speaker != "我" and npc_id != "":
		var fallback_path := "res://assets/sprites/characters/phase_two/avatars/%s_neutral.png" % npc_id
		if not ResourceLoader.exists(fallback_path):
			fallback_path = "res://assets/sprites/characters/phase_two/portraits/%s.png" % npc_id
		if ResourceLoader.exists(fallback_path):
			dialogue.portrait.texture = load(fallback_path)
			dialogue.portrait.visible = true

func _confirm_sleep() -> void:
	if _sleep_confirm: return
	_sleep_confirm = true
	var curtain := ColorRect.new()
	curtain.name = "SleepConfirmation"
	curtain.color = Color(0.14,0.18,0.27,0.48)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	presentation.add_child(curtain)
	DaylightUI.place(curtain,0,0,1920,1080)
	var plate := Panel.new()
	plate.add_theme_stylebox_override("panel",SceneSkin.style("panel_frame",Vector4(30,25,30,25)))
	curtain.add_child(plate)
	DaylightUI.place(plate,540,340,840,360)
	SchoolObjectUI.text(plate,"SleepQuestion",DayCycle.rest_label()+"？",Rect2(65,40,710,85),38,SchoolObjectUI.INK,true)
	SchoolObjectUI.text(plate,"SleepDescription","休息会推进到下一个时段。",Rect2(70,135,700,55),27,SchoolObjectUI.MUTED,true)
	var cancel := _button(plate,"CancelSleep","再待一会儿",Rect2(55,235,340,78))
	cancel.pressed.connect(func(): _sleep_confirm = false; curtain.queue_free())
	var confirm := _button(plate,"ConfirmSleep",DayCycle.rest_label(),Rect2(445,235,340,78),true)
	confirm.pressed.connect(func():
		if _busy: return
		_busy = true
		curtain.queue_free()
		_sleep_confirm = false
		_sleep()
	)
	cancel.grab_focus()

func _sleep() -> void:
	_fade = ColorRect.new()
	_fade.name = "OvernightFade"
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.color = Color("#172337")
	_fade.modulate.a = 0.0
	presentation.add_child(_fade)
	DaylightUI.place(_fade,0,0,1920,1080)
	var tween := create_tween()
	tween.tween_property(_fade,"modulate:a",1.0,SaveManager.motion_duration(0.45))
	await tween.finished
	var lines: Array = CampusLife.sleep_to_morning()
	refs.clear()
	# Keep the transition above the rebuilt room until its new date is ready.
	for node in presentation.get_children():
		if node != _fade:
			presentation.remove_child(node)
			node.queue_free()
	_build_place()
	AudioManager.play_bgm_for_scene(SceneManager.TargetScene.CAMPUS_LIFE)
	presentation.move_child(_fade,-1)
	tween = create_tween()
	tween.tween_property(_fade,"modulate:a",0.0,SaveManager.motion_duration(0.5))
	await tween.finished
	_fade.queue_free()
	_fade = null
	_busy = false
	for button in presentation.find_children("*","Button",true,false): button.disabled = false
	_show_dialogue(lines)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_M:
		if not _busy and not _sleep_confirm and not is_instance_valid(dialogue) and not is_instance_valid(system_menu) and not is_instance_valid(_workspace) and not is_instance_valid(_qualifier_modal) and not is_instance_valid(_companion_modal):
			_travel("map")
			get_viewport().set_input_as_handled()
		return
	if event.keycode != KEY_ESCAPE: return
	if is_instance_valid(dialogue): return
	if is_instance_valid(system_menu):
		system_menu.go_back()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_companion_modal):
		_close_companion_switcher()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_qualifier_modal):
		_close_qualifier_modal()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_workspace):
		if not _workspace.has_method("cancel_pending") or not _workspace.call("cancel_pending"):
			_close_workspace()
		get_viewport().set_input_as_handled()
		return
	if _busy: get_viewport().set_input_as_handled(); return
	if _sleep_confirm:
		_sleep_confirm = false
		var confirmation := presentation.get_node_or_null("SleepConfirmation")
		if confirmation != null: confirmation.queue_free()
	else:
		_travel(str(CampusPlaces.PLACES[location_id]["parent"]))
	get_viewport().set_input_as_handled()

func _set_actions_visible(value: bool) -> void:
	if is_instance_valid(scene_objects):
		scene_objects.set_interactions_enabled(value)
		return
	if is_instance_valid(object_home):
		object_home.set_interactions_enabled(value)
		return
	for button in refs.get("actions",{}).values(): button.visible = value
	var description := presentation.get_node_or_null("LocationDescription")
	if description != null: description.visible = value

func _refresh_clock(_day: int, _hour: int, _minute: int, _weekday: String) -> void:
	var clock := presentation.get_node_or_null("DayTime") as Label
	if clock != null: clock.text = GameState.get_detailed_time_string()

func _run_activity(run_fn: Callable) -> void:
	var hp_before := GameState.player_current_hp
	var pts_before := GameState.scrap_metal
	var cash_before := GameState.energy_crystals
	var drinks_before := GameState.energy_drinks
	var mat_before := int(GameState.exploration_materials.get("material_common", 0))
	var lines: Array = run_fn.call()
	_show_dialogue(lines)
	var parts: Array[String] = []
	if GameState.player_current_hp > hp_before: parts.append("体力 +%d" % (GameState.player_current_hp - hp_before))
	if GameState.energy_crystals > cash_before: parts.append("零用钱 +%d" % (GameState.energy_crystals - cash_before))
	if GameState.scrap_metal > pts_before: parts.append("练习点 +%d" % (GameState.scrap_metal - pts_before))
	if GameState.energy_drinks > drinks_before: parts.append("饮品 +%d" % (GameState.energy_drinks - drinks_before))
	var mat_after := int(GameState.exploration_materials.get("material_common", 0))
	if mat_after > mat_before: parts.append("普通材料 +%d" % (mat_after - mat_before))
	if parts.is_empty() or not is_instance_valid(presentation): return
	_show_toast_message("收获：" + " · ".join(parts))

func _show_toast_message(copy: String) -> void:
	if copy == "" or not is_instance_valid(presentation): return
	if is_instance_valid(_toast_tween): _toast_tween.kill()
	if is_instance_valid(_reward_toast): _reward_toast.queue_free()
	_reward_toast = SchoolObjectUI.slab(presentation, "RewardToast", Rect2(1372, 92, 512, 48), Color("#FBF6EA"))
	if not DynamicUI.apply_nine_slice_panel(_reward_toast, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32)):
		var style := _reward_toast.get_theme_stylebox("panel") as StyleBoxFlat
		style.border_color = Color("#359686")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
	_reward_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := SchoolObjectUI.text(_reward_toast, "Text", copy, Rect2(16, 4, 480, 40), 19, SchoolObjectUI.INK)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	_reward_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(SaveManager.motion_duration(1.7))
	_toast_tween.tween_property(_reward_toast, "modulate:a", 0.0, SaveManager.motion_duration(0.45))
	_toast_tween.tween_callback(func():
		if is_instance_valid(_reward_toast):
			_reward_toast.queue_free()
			_reward_toast = null
	)


func _build_test_place(data: Dictionary) -> void:
	var ink := Color("#E7EBED")
	SchoolObjectUI.slab(presentation,"TestBackground",Rect2(0,0,1920,1080),Color("#20262D"))
	SchoolObjectUI.text(presentation,"LocationTitle",str(data["title"]),Rect2(95,40,1190,95),40,ink)
	SchoolObjectUI.text(presentation,"DayTime",GameState.get_detailed_time_string(),Rect2(100,150,1200,50),25,ink)
	SchoolObjectUI.text(presentation,"TestNotice","该地区正随主线章节推进筹备中 · 正式场景与专属剧情敬请期待",Rect2(100,260,1730,70),28,ink)
	var description := SchoolObjectUI.text(presentation,"LocationDescription",str(data["description"]),Rect2(100,380,1700,220),32,ink)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var map_copy := str(data.get("map_object_label",""))
	map_copy = map_copy+"\n地区地图" if map_copy != "" else "地区地图"
	var map_button := MapPageUI.button(presentation,"OpenMap",map_copy,Rect2(1560,45,280,75),ink,Color(1,1,1,0.06))
	map_button.pressed.connect(_travel.bind("map"))
	refs["map_button"] = map_button
	var menu := MapPageUI.button(presentation,"OpenMenu","菜单",Rect2(1330,45,190,75),ink,Color(1,1,1,0.06))
	menu.pressed.connect(_open_menu)
	refs["actions"] = {}
	var actions: Array = data["actions"]
	for i in actions.size():
		var item: Dictionary = actions[i]
		var copy := str(item.get("object_label",""))
		copy = copy+"\n"+str(item["label"]) if copy != "" else str(item["label"])
		var b := MapPageUI.button(presentation,"Action_"+str(item["id"])+str(i),copy,Rect2(100+i*580,860,550,90),ink,Color(1,1,1,0.06),27)
		b.pressed.connect(_action.bind(item))
		refs["actions"][str(item["id"])+str(i)] = b
	map_button.grab_focus.call_deferred()


func _build_object_home() -> void:
	object_home = RegionHomeView.new()
	object_home.home_id = location_id
	object_home.name = "RegionHomeObjects"
	presentation.add_child(object_home)
	refs = object_home.refs
	object_home.action_requested.connect(_action)
	object_home.map_requested.connect(_travel.bind("map"))
	object_home.menu_requested.connect(_open_menu)


func _build_scene_objects() -> void:
	scene_objects = SceneObjectView.new()
	scene_objects.location_id = location_id
	scene_objects.name = "SceneObjects"
	presentation.add_child(scene_objects)
	refs = scene_objects.refs
	scene_objects.action_requested.connect(_action)
	scene_objects.map_requested.connect(_travel.bind("map"))
	scene_objects.menu_requested.connect(_open_menu)
