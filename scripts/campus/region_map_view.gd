class_name RegionMapView
extends Control

signal travel_requested(location_id: String)
signal atlas_requested
signal close_requested
var region_id := "campus"
var refs: Dictionary = {}
var _calendar_refresh_pending := false
var _fade_on_style := false

func _ready() -> void:
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()
	DayCycle.changed.connect(_calendar_changed)

func _exit_tree() -> void:
	if DayCycle.changed.is_connected(_calendar_changed):
		DayCycle.changed.disconnect(_calendar_changed)

func _calendar_changed() -> void:
	if _calendar_refresh_pending: return
	_calendar_refresh_pending = true
	_refresh_calendar.call_deferred()

func _refresh_calendar() -> void:
	_calendar_refresh_pending = false
	if not is_inside_tree(): return
	var focused := get_viewport().gui_get_focus_owner()
	refresh(str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else "")

func _restore_focus(node_name: String) -> void:
	if not is_inside_tree(): return
	var target := get_node_or_null(node_name) as Control
	if is_instance_valid(target) and target.is_inside_tree(): target.grab_focus()

func refresh(focus_name: String = "") -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	if SceneDesignCatalog.MAPS.has(region_id):
		_build_illustrated_map(focus_name)
		return
	if RegionCatalog.is_primary(region_id) and region_id != "university_arete":
		_build_test_map(focus_name)
		return
	var spec: Dictionary = RegionCatalog.REGIONS["campus" if region_id == "university_arete" else region_id]
	var campus := region_id in ["campus","university_arete"]
	var concept := CampusLife.map_concept()
	var visual: Dictionary = RegionCatalog.CONCEPTS[concept] if campus else spec
	var paper := Color(visual["paper"])
	var ink := Color(visual["ink"])
	var path := str(visual.get("path",""))
	var painted := campus and ResourceLoader.exists(path)
	var wide_path := path.replace(".png","_wide.png") if painted else ""
	var did_style_fade := _fade_on_style
	_fade_on_style = false
	if painted and ResourceLoader.exists(wide_path):
		var wide_bg := SchoolObjectUI.art(self,"WideMapBackground",wide_path,Rect2(-210,0,2340,1080))
		wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		wide_bg.z_index = -3
		if did_style_fade and not bool(SaveManager.settings.get("reduced_motion", false)):
			wide_bg.modulate.a = 0.42
			var fade_tw := wide_bg.create_tween()
			fade_tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			fade_tw.tween_property(wide_bg, "modulate:a", 1.0, 0.26)
	var mother: TextureRect
	if painted:
		mother = SchoolObjectUI.art(self,"ConceptMother",path)
		mother.z_index = -2
		mother.set_meta("layer_role","complete_unified_campus_composition")
		if ResourceLoader.exists(wide_path):
			mother.self_modulate = Color(1,1,1,0)
		elif did_style_fade and not bool(SaveManager.settings.get("reduced_motion", false)):
			mother.modulate.a = 0.42
			var fade_tw := mother.create_tween()
			fade_tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			fade_tw.tween_property(mother, "modulate:a", 1.0, 0.26)
	elif campus:
		var geometry := MapPageGeometry.new()
		add_child(geometry)
		ink = Color("#2D5059")
		paper = Color("#F2E7D6")
	else:
		var geometry := RegionGeometry.new()
		geometry.region_id = region_id
		add_child(geometry)
	var place_ids: Array = RegionCatalog.PAINTED_RECTS[concept].keys() if (painted and RegionCatalog.PAINTED_RECTS.has(concept)) else spec["places"]
	if mother != null and mother.texture != null:
		for id in place_ids:
			if not RegionCatalog.PAINTED_RECTS[concept].has(id): continue
			var rect: Rect2 = RegionCatalog.PAINTED_RECTS[concept][id]
			var crop := AtlasTexture.new()
			crop.atlas = mother.texture
			var ratio := mother.texture.get_size()/Vector2(1920,1080)
			crop.region = Rect2(rect.position*ratio,rect.size*ratio)
			crop.filter_clip = true
			var layer := SchoolObjectUI.art(self,"Landmark_"+id,"",rect)
			layer.z_index = -1
			layer.texture = crop
			layer.set_meta("layer_role","registered_landmark_crop")
	var dark_map := painted and concept == "indigo"
	if painted:
		var header_plate := MapPageUI.plate(self,"HeaderBacking",Rect2(60,30,504,126),Color("#1B263E",0.92) if dark_map else Color("#FFFDF8",0.96))
		header_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plate_mod := Color(0.24,0.29,0.40,0.96) if dark_map else Color(1.0,0.99,0.96,0.97)
		if not DynamicUI.apply_nine_slice_panel(header_plate,DynamicUI.THEME_PAPER_MODAL,Vector4(72,56,44,44),plate_mod):
			var hbox := header_plate.get_theme_stylebox("panel") as StyleBoxFlat
			hbox.border_color = Color("#72A6FF",0.92) if dark_map else Color("#359686",0.92)
			hbox.set_border_width_all(2)
			hbox.set_corner_radius_all(10)
	var plate_ink := (Color("#FFF7E5") if dark_map else Color("#1E314D")) if painted else ink
	var heading := SchoolObjectUI.text(self,"MapTitle",str(RegionCatalog.REGIONS[region_id]["title"])+"地图",Rect2(96,36,520,62),44,plate_ink)
	var calendar := SchoolObjectUI.text(self,"DayTime",GameState.get_detailed_time_string(),Rect2(98,104,520,34),21,Color(plate_ink,0.88))
	for label in [heading,calendar]:
		if not painted:
			label.add_theme_color_override("font_shadow_color",Color(paper,0.9))
			label.add_theme_constant_override("shadow_offset_y",1)
			label.add_theme_constant_override("shadow_outline_size",2)
	var can_advance := not DayCycle.has_story() and DayCycle.period() != "night"
	var period_copy := "进入下一时段" if can_advance else ("今夜宜回社团" if DayCycle.period() == "night" else "请先完成剧情")
	var top_ink := Color("#F3F6FD") if dark_map else Color("#21324B")
	var top_fill := Color("#23304C",0.92) if dark_map else Color("#FFFDF8",0.94)
	var period_btn := MapPageUI.button(self,"QuickPeriod",period_copy,Rect2(755,55,230,70),top_ink,top_fill,23)
	period_btn.disabled = not can_advance
	period_btn.pressed.connect(func():
		if DayCycle.rest():
			refresh("QuickPeriod")
	)
	var style_copy := "切至夜课星图" if concept == "vermilion" else "切至晴昼水彩"
	var style_btn := MapPageUI.button(self,"ToggleMapStyle",style_copy,Rect2(1010,55,230,70),top_ink,top_fill,23)
	style_btn.pressed.connect(func():
		_fade_on_style = true
		CampusLife.toggle_map_concept()
		refresh("ToggleMapStyle")
	)
	var atlas := MapPageUI.button(self,"OpenRegionAtlas","地区总图 →",Rect2(1270,55,265,70),top_ink,top_fill,24)
	atlas.pressed.connect(func(): atlas_requested.emit())
	var back := MapPageUI.button(self,"ReturnToPlace","返回地点 ×",Rect2(1570,55,270,70),top_ink,top_fill,24)
	back.pressed.connect(func(): close_requested.emit())
	if painted:
		var top_specs := [
			[period_btn, Color("#59C2B0") if dark_map else Color("#359686"), 23],
			[style_btn, Color("#7BA4FF") if dark_map else Color("#4675C6"), 23],
			[atlas, Color("#F0AB56") if dark_map else Color("#DB8930"), 24],
			[back, Color("#EF7D6D") if dark_map else Color("#CA5443"), 24]
		]
		for idx in top_specs.size():
			var item: Array = top_specs[idx]
			var btn: Button = item[0]
			var accent_col: Color = item[1]
			var fsize: int = item[2]
			DynamicUI.make_cel_button(btn, top_fill, top_ink, accent_col, fsize, 14)
			if not did_style_fade:
				DynamicUI.slide_in(btn, Vector2(0, -10), 0.18, float(idx) * 0.03)
	refs["period"] = period_btn
	refs["style"] = style_btn
	refs["atlas"] = atlas
	refs["back"] = back
	refs["locations"] = {}
	var current_loc := _active_place_id()
	var park_open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
	var pin_tex: Texture2D = load("res://assets/ui/region_maps/ui_map_pin_plates.png") if painted and ResourceLoader.exists("res://assets/ui/region_maps/ui_map_pin_plates.png") else null
	for raw_id in place_ids:
		var id := str(raw_id)
		var rect: Rect2 = RegionCatalog.PAINTED_RECTS[concept][id] if painted else RegionCatalog.MAP_RECTS[id]
		var is_locked := (id == "old_park" and not park_open)
		var button := MapPageUI.button(self,"Place_"+id,"",rect,Color("#FFFFFF") if painted else ink)
		button.disabled = is_locked
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not is_locked else Control.CURSOR_ARROW
		button.pressed.connect(func(): travel_requested.emit(str(id)))
		refs["locations"][id] = button
		var label_rect: Rect2 = (RegionCatalog.PAINTED_LABELS[concept][id] if painted else RegionCatalog.CAMPUS_LABELS[id]) if campus else Rect2(rect.position+Vector2(8,rect.size.y-75),Vector2(rect.size.x-16,70))
		var story_tag := _story_tag_for(id)
		var title := str(RegionCatalog.SHORT_NAMES.get(id,CampusPlaces.PLACES[id]["title"]))
		if is_locked: title = "旧公园（未开放）"
		if painted and pin_tex != null:
			var pill_wrap := Control.new()
			pill_wrap.name = "NamePillWrap_" + id
			pill_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(pill_wrap)
			DaylightUI.place(pill_wrap, label_rect.position.x, label_rect.position.y, label_rect.size.x, label_rect.size.y)
			pill_wrap.pivot_offset = label_rect.size * 0.5
			var plate_region := Rect2(693,134,299,90) if (story_tag != "" or id == "shop") else (Rect2(359,134,306,90) if id in ["gym","arete_coast_test","arete_beach_test"] else Rect2(32,134,300,91))
			var plate_crop := AtlasTexture.new()
			plate_crop.atlas = pin_tex
			plate_crop.region = plate_region
			var plate_art := SchoolObjectUI.art(pill_wrap,"NameBacking_"+id,"",Rect2(Vector2.ZERO,label_rect.size))
			plate_art.texture = plate_crop
			plate_art.stretch_mode = TextureRect.STRETCH_SCALE
			plate_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if is_locked: plate_art.modulate = Color(0.86,0.88,0.92,0.75)
			var text_rect := Rect2(Vector2(30, 12), Vector2(label_rect.size.x - 42, 34))
			var name_label := SchoolObjectUI.text(pill_wrap,"Name_"+id,title,text_rect,18 if is_locked else 21,Color("#4F5D73") if is_locked else Color("#24354F"),true)
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pop_pill := func(target_s: float):
				if not is_instance_valid(pill_wrap) or is_locked: return
				pill_wrap.pivot_offset = label_rect.size * 0.5
				if bool(SaveManager.settings.get("reduced_motion", false)):
					pill_wrap.scale = Vector2.ONE
					return
				if pill_wrap.has_meta("_pop_tw"):
					var old_tw: Tween = pill_wrap.get_meta("_pop_tw")
					if is_instance_valid(old_tw): old_tw.kill()
				var tw := pill_wrap.create_tween()
				tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(pill_wrap, "scale", Vector2.ONE * target_s, 0.14)
				pill_wrap.set_meta("_pop_tw", tw)
			var is_btn_hovered := false
			button.mouse_entered.connect(func():
				is_btn_hovered = true
				pop_pill.call(1.075)
			)
			button.mouse_exited.connect(func():
				is_btn_hovered = false
				pop_pill.call(1.0)
			)
			button.focus_entered.connect(func(): pop_pill.call(1.075))
			button.focus_exited.connect(func():
				if not is_btn_hovered: pop_pill.call(1.0)
			)
		else:
			var name_label := SchoolObjectUI.text(self,"Name_"+id,title,Rect2(label_rect.position,Vector2(label_rect.size.x,40)),28,Color.BLACK,true)
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_label.add_theme_color_override("font_shadow_color",Color(1,1,1,0.65))
			name_label.add_theme_constant_override("shadow_offset_x",1)
			name_label.add_theme_constant_override("shadow_offset_y",1)
			name_label.add_theme_constant_override("shadow_outline_size",2)
		var badge_dy := 62.0 if label_rect.position.y < 175.0 else -34.0
		if story_tag != "":
			_badge_pill(self, "StoryBadge_"+id, story_tag, Rect2(label_rect.position + Vector2(18, badge_dy), Vector2(174, 30)), Color("#D35342"), "story")
		if id == current_loc:
			var drop_below := (story_tag != "" and label_rect.position.x > 1400.0)
			var here_offset := Vector2(26, 62.0) if drop_below else Vector2(-144.0 if story_tag != "" else 26.0, badge_dy)
			var here_rect := Rect2(label_rect.position + here_offset, Vector2(154, 30))
			DynamicUI.create_pulse_ring(self, "HerePulse_"+id, here_rect.position + Vector2(22.0, here_rect.size.y * 0.5), 34.0, Color("#56C5D0") if dark_map else Color("#2F9B8E"))
			_badge_pill(self, "HereBadge_"+id, "当前所在", here_rect, Color("#367D6D"), "here")
	if campus and not painted:
		var extra_specs := [
			{"id": "old_park", "title": "旧公园" if park_open else "旧公园（未开放）", "enabled": park_open},
			{"id": "arete_coast_test", "title": "沿海公路", "enabled": true},
			{"id": "arete_beach_test", "title": "阿瑞忒海滩", "enabled": true}
		]
		for i in extra_specs.size():
			var item: Dictionary = extra_specs[i]
			var eid := str(item["id"])
			var bx := 840.0 + i * 340.0
			var b := MapPageUI.button(self,"Place_"+eid,str(item["title"]),Rect2(bx,990,320,62),ink,Color(paper,0.85),23)
			b.disabled = not bool(item["enabled"])
			b.pressed.connect(func(): travel_requested.emit(eid))
			refs["locations"][eid] = b
	var hint_bg := Color(0.11,0.14,0.21,0.84) if painted else Color(0.97,0.94,0.87,0.92)
	var hint_width := 940.0 if painted else 752.0
	var hint_slab := SchoolObjectUI.slab(self,"MapHintBacking",Rect2(62,962,hint_width,90),hint_bg)
	var has_ribbon := DynamicUI.apply_nine_slice_panel(hint_slab,DynamicUI.THEME_FABRIC_RIBBON,Vector4(56,26,56,26),Color(0.84,0.88,0.96,0.96) if dark_map else Color.WHITE)
	if not has_ribbon:
		var hint_style := hint_slab.get_theme_stylebox("panel") as StyleBoxFlat
		hint_style.set_corner_radius_all(10)
		if painted:
			hint_style.border_color = Color("#56C5D0", 0.72)
			hint_style.set_border_width_all(2)
	hint_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint_ink := Color("#FFF8EC") if (painted or has_ribbon) else ink
	var preview := SchoolObjectUI.text(self,"MapPreviewLine",_default_map_preview(),Rect2(102,970,hint_width - 80.0,40),20,Color(hint_ink))
	preview.add_theme_font_override("font", DaylightUI.bold_font())
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.clip_text = true
	preview.add_theme_color_override("font_shadow_color",Color(0,0,0,0.45))
	preview.add_theme_constant_override("shadow_offset_y",1)
	refs["preview_label"] = preview
	var hint := SchoolObjectUI.text(self,"MapHint","可安排 %d 次活动 · 悬停地点预览产出与人物 · Esc 返回" % DayCycle.remaining(),Rect2(102,1012,hint_width - 80.0,32),18,Color(hint_ink,0.88))
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color",Color(0,0,0,0.45))
	hint.add_theme_constant_override("shadow_offset_y",1)
	for loc_id in refs["locations"]:
		_bind_preview(refs["locations"][loc_id], _location_preview(str(loc_id)))
	_bind_preview(period_btn, "在校园地图上直接推进至下一时段并小幅恢复体力" if can_advance else ("已至夜晚，返回社团教室或宿舍即可结束今日休息至次晨" if DayCycle.period() == "night" else "当前有待触发的主线剧情，请前往高亮标注地点"))
	_bind_preview(style_btn, "切换手绘校园地图样式：放学暖阳 / 夜课星图")
	_bind_preview(atlas, "打开六地区巡回总图 · 查看各学园与灰区解锁路线")
	_bind_preview(back, "返回刚刚所在的地点（快捷键 Esc）")
	_restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")

func _active_place_id() -> String:
	var raw := CampusLife.current_location if CampusLife.current_location != "map" else str(CampusLife.snapshot().get("last_location", "club"))
	if raw in ["old_park", "arete_beach_test"] and RegionCatalog.PAINTED_RECTS.get("vermilion", {}).has("arete_coast_test"):
		return "arete_coast_test"
	return raw

func _bind_preview(control: Control, copy: String) -> void:
	if control == null: return
	control.mouse_entered.connect(func(): _set_preview(copy))
	control.focus_entered.connect(func(): _set_preview(copy))
	control.mouse_exited.connect(func(): _set_preview(_default_map_preview()))
	control.focus_exited.connect(func(): _set_preview(_default_map_preview()))

func _set_preview(copy: String) -> void:
	var preview := refs.get("preview_label") as Label
	if is_instance_valid(preview):
		preview.text = copy

func _default_map_preview() -> String:
	var next_node := GameState.next_phase_two_node()
	if not bool(GameState.story_flags.get("chapter_1_completed", false)):
		if next_node == "n_affairs" and PlayerJourney.act1_story_ready():
			return "主线推荐：前往「图书馆」与黄秋枫午后约见"
		if next_node == "n_dusk" and PlayerJourney.act2_combat_ready():
			return "主线推荐：前往「沿海公路」拐进「旧公园」赴黄秋枫的黄昏之约"
	elif not bool(GameState.story_flags.get("arete_qualifier_completed", false)):
		return "巡回挑战：前往「体育馆」参加 3 轮阿瑞忒代表选拔赛"
	var raw_loc := CampusLife.current_location if CampusLife.current_location != "map" else str(CampusLife.snapshot().get("last_location", "club"))
	return "当前所在：%s · 可自由探索校园各处" % str(CampusPlaces.PLACES.get(raw_loc, {}).get("title", "社团教室"))

func _location_preview(place_id: String) -> String:
	var badge := _story_tag_for(place_id)
	var prefix := ("%s · " % badge) if badge != "" else ""
	match place_id:
		"club": return "%s社团教室 · 卡牌整理 / 放映档案室盖章 / 同伴交流（在场：姜梓）" % prefix
		"library": return "%s图书馆 · 牌理研习(+35练习点/风物纪要) · 免费查阅纪要（在场：林知夏）" % prefix
		"shop": return "%s校园商店 · 店务兼职(+100零用钱) · 选购刻印卡与补给（在场：唐小满）" % prefix
		"gym": return "%s体育馆 · 模拟训练与校内代表选拔赛 3 轮挑战（在场：柳宇龙）" % prefix
		"rooftop":
			var roof_cid := CampusLife.rooftop_active_npc()
			var roof_npc := str(PhaseTwoContent.ACTORS.get(roof_cid, {}).get("name", "杨子英"))
			return "%s教学楼天台 · 战术复盘(回40体力/+20练习点/+12好感 · 当前在场：%s)" % [prefix, roof_npc]
		"dorm": return "%s学生宿舍 · 查看今日统计 · 过夜休息完全恢复体力并进入次日" % prefix
		"old_park":
			var open := bool(GameState.story_flags.get("school_affairs_done", false)) or GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("chapter_1_completed", false)) or SaveManager.test_session
			if not open:
				return "旧公园（未开放）· 先前往「图书馆」推进第一幕主线后解锁"
			return "%s旧公园 · 长椅追忆(回30体力/+30练习点) · 街角自动贩卖机" % prefix
		"arete_coast_test": return "%s沿海公路 · 散步(+15练习点/+15好感) · 内含「旧公园」与「阿瑞忒海滩」双入口" % prefix
		"arete_beach_test": return "%s阿瑞忒海滩 · 海边休整(回35体力/普通材料×2/+10同伴好感)" % prefix
	return str(CampusPlaces.PLACES.get(place_id, {}).get("title", place_id))

func _story_tag_for(place_id: String) -> String:
	if bool(GameState.story_flags.get("chapter_1_completed", false)):
		if place_id == "gym" and not bool(GameState.story_flags.get("arete_qualifier_completed", false)):
			return "代表选拔赛"
		return ""
	var next_node := GameState.next_phase_two_node()
	if place_id == "library" and next_node == "n_affairs" and PlayerJourney.act1_story_ready():
		return "主线剧情"
	if place_id in ["old_park", "arete_coast_test"] and next_node == "n_dusk" and PlayerJourney.act2_combat_ready():
		return "旧公园赴约"
	return ""

func _badge_pill(parent: Control, node_name: String, copy: String, rect: Rect2, fill: Color, badge_kind: String = "") -> void:
	var pill := SchoolObjectUI.slab(parent, node_name, rect, fill)
	var tag_fill := Color("#C85242") if badge_kind == "story" else Color("#367D6D")
	var tag_border := Color("#9E3B2E") if badge_kind == "story" else Color("#24594D")
	pill.add_theme_stylebox_override("panel", DynamicUI.make_paper_tag(tag_fill, tag_border, 6, 8.0, 2.0))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if badge_kind == "story":
		DynamicUI.attach_sheen(pill, Color("#FFF7D6", 0.38), 6)
		DynamicUI.attach_float_bob(pill, 3.5, 2.8)
	elif badge_kind == "here":
		DynamicUI.attach_float_bob(pill, 2.5, 2.2)
	var lbl := SchoolObjectUI.text(pill, "Copy", copy, Rect2(Vector2.ZERO, rect.size), 17, Color("#FFFBF2"), true)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_test_map(focus_name: String) -> void:
	var spec: Dictionary = RegionCatalog.REGIONS[region_id]
	var ink := Color("#E7EBED")
	SchoolObjectUI.slab(self,"TestBackground",Rect2(0,0,1920,1080),Color("#20262D"))
	SchoolObjectUI.text(self,"MapTitle",str(spec["title"])+" 地区地图",Rect2(95,45,1250,75),42,ink)
	SchoolObjectUI.text(self,"DayTime",GameState.get_detailed_time_string(),Rect2(100,125,1200,45),25,ink)
	SchoolObjectUI.text(self,"TestNotice","该地区正随主线章节推进筹备中 · 正式场景与探索内容敬请期待",Rect2(100,205,1700,50),26,ink)
	var atlas := MapPageUI.button(self,"OpenRegionAtlas","世界地图",Rect2(1300,55,230,70),ink,Color(1,1,1,0.06))
	atlas.pressed.connect(func(): atlas_requested.emit())
	var back := MapPageUI.button(self,"ReturnToPlace","返回出发地点",Rect2(1570,55,270,70),ink,Color(1,1,1,0.06))
	back.pressed.connect(func(): close_requested.emit())
	refs["atlas"] = atlas
	refs["back"] = back
	refs["locations"] = {}
	for i in spec["places"].size():
		var id: String = spec["places"][i]
		var b := MapPageUI.button(self,"Place_"+id,str(CampusPlaces.PLACES[id]["title"]),Rect2(100,330+i*130,1730,95),ink,Color(1,1,1,0.06),29)
		b.disabled = not RegionCatalog.is_unlocked(region_id)
		b.pressed.connect(func(): travel_requested.emit(id))
		refs["locations"][id] = b
	SchoolObjectUI.text(self,"MapHint","浏览不移动角色 · 选择已开放地点才旅行 · 无活动消耗",Rect2(100,990,1710,55),24,ink)
	_restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")

func _build_illustrated_map(focus_name: String) -> void:
	var spec: Dictionary = SceneDesignCatalog.MAPS[region_id]
	var map_file := SceneDesignCatalog.map_path(region_id)
	var wide_map := map_file.replace(".png","_wide.png")
	if ResourceLoader.exists(wide_map):
		var wide_bg := SchoolObjectUI.art(self,"WideMapBackground",wide_map,Rect2(-210,0,2340,1080))
		wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		wide_bg.z_index = -3
	var background := SchoolObjectUI.art(self,"ConceptMother",map_file)
	background.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(wide_map): background.self_modulate = Color(1,1,1,0)
	background.set_meta("layer_role","current_registered_district_concept")
	SceneSurfaceUI.heading(self,str(RegionCatalog.REGIONS[region_id]["title"])+"地图")
	get_node("LocationTitle").name = "MapTitle"
	var atlas := SceneSurfaceUI.button(self,"OpenRegionAtlas","世界地图",Rect2(1365,32,220,76),28)
	atlas.pressed.connect(func(): atlas_requested.emit())
	var back := SceneSurfaceUI.button(self,"ReturnToPlace","返回地点",Rect2(1610,32,240,76),28)
	back.pressed.connect(func(): close_requested.emit())
	refs["atlas"] = atlas
	refs["back"] = back
	refs["locations"] = {}
	refs["landmarks"] = {}
	for id in spec["locations"]:
		var item: Dictionary = spec["locations"][id]
		var activate := func(): travel_requested.emit(str(id))
		var pair := SceneSurfaceUI.landmark(self,"Place_"+id,background.texture,item["polygon"],item["tag"],str(item["label"]),activate)
		pair["label"].disabled = not RegionCatalog.is_unlocked(region_id)
		pair["image"].disabled = pair["label"].disabled
		refs["locations"][id] = pair["label"]
		refs["landmarks"][id] = pair["image"]
	var note := SchoolObjectUI.text(self,"MapHint","点击地图标注即可前往 · 浏览不消耗活动次数 · Esc 返回",Rect2(90,1009,1600,43),23,Color("#FFF7E5"))
	note.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
	note.add_theme_constant_override("shadow_offset_y",2)
	var order: Array = [back,atlas]+refs["locations"].values()
	for i in order.size():
		var button: Button = order[i]
		button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
		button.focus_next = button.get_path_to(order[(i+1)%order.size()])
		button.focus_neighbor_left = button.focus_previous
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_right = button.focus_next
		button.focus_neighbor_bottom = button.focus_next
	SceneSurfaceUI.finish_layering(self,background)
	_restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")
