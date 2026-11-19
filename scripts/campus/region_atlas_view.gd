class_name RegionAtlasView
extends Control

signal region_requested(region_id: String)
signal entry_requested(region_id: String)
signal close_requested
const TOUR_ORDER := ["university_arete","university_nomos","university_techne","university_agora","region_failed_alliance","region_iga_church"]
var refs: Dictionary = {}

class TourRouteOverlay:
	extends Control
	var points: Array[Vector2] = []
	var leg_one_ready := false
	var _phase := 0.0
	var _orb_t := 0.0
	func _process(delta: float) -> void:
		if bool(SaveManager.settings.get("reduced_motion", false)):
			if _phase != 0.0:
				_phase = 0.0
				queue_redraw()
			return
		_phase = fmod(_phase + delta * 0.45, 1.0)
		_orb_t = fmod(_orb_t + delta * 0.34, 1.0)
		queue_redraw()
	func _quad_pt(a: Vector2, mid: Vector2, b: Vector2, t: float) -> Vector2:
		return a.lerp(mid, t).lerp(mid.lerp(b, t), t)
	func _draw() -> void:
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var mid := (a + b) * 0.5 + Vector2(0, -52.0 if i % 2 == 0 else 44.0)
			var active_leg := (i == 0 and leg_one_ready)
			var halo_col := Color("#4C2B18", 0.80) if active_leg else Color("#1D2940", 0.68)
			var core_col := Color("#FFCC66", 0.98) if active_leg else Color("#FFF8E7", 0.92)
			var steps := 18
			for s in steps:
				var t0: float
				var t1: float
				if active_leg:
					t0 = float(s) / float(steps)
					t1 = float(s + 1) / float(steps)
				else:
					if s % 2 == 1: continue
					var shift := 0.0 if bool(SaveManager.settings.get("reduced_motion", false)) else _phase * (2.0 / float(steps))
					t0 = clampf(float(s) / float(steps) + shift, 0.0, 1.0)
					t1 = clampf(float(s + 1) / float(steps) + shift, 0.0, 1.0)
					if t1 <= t0 + 0.005: continue
				var p0 := _quad_pt(a, mid, b, t0)
				var p1 := _quad_pt(a, mid, b, t1)
				draw_line(p0, p1, halo_col, 8.0 if active_leg else 5.5, true)
				draw_line(p0, p1, core_col, 4.0 if active_leg else 2.6, true)
			if active_leg and not bool(SaveManager.settings.get("reduced_motion", false)):
				var orb := _quad_pt(a, mid, b, _orb_t)
				draw_circle(orb, 11.0, Color("#FFE08A", 0.38))
				draw_circle(orb, 6.0, Color("#FFF9DB", 0.96))
		for idx in points.size():
			var pt := points[idx]
			var dot_col := Color("#FFBE4D") if (idx == 0 or (idx == 1 and leg_one_ready)) else Color("#6C82A3")
			draw_circle(pt, 14.0, Color("#1D2940", 0.92))
			draw_circle(pt, 10.5, Color("#FFF9ED"))
			draw_circle(pt, 7.5, dot_col)

func _ready() -> void:
	size = Vector2(1920,1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var wide_world := SceneDesignCatalog.ROOT+"maps/world_wide.png"
	if ResourceLoader.exists(wide_world):
		var wide_bg := SchoolObjectUI.art(self,"WideWorldBackground",wide_world,Rect2(-210,0,2340,1080))
		wide_bg.stretch_mode = TextureRect.STRETCH_SCALE
		wide_bg.z_index = -3
	var background := SchoolObjectUI.art(self,"TravelConcept",SceneDesignCatalog.ROOT+"maps/world.png")
	background.stretch_mode = TextureRect.STRETCH_SCALE
	if ResourceLoader.exists(wide_world): background.self_modulate = Color(1,1,1,0)
	var route_layer := TourRouteOverlay.new()
	route_layer.name = "TourRouteOverlay"
	route_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_layer.size = Vector2(1920, 1080)
	route_layer.leg_one_ready = bool(GameState.story_flags.get("arete_qualifier_completed", false))
	for tid in TOUR_ORDER:
		if SceneDesignCatalog.WORLD.has(tid):
			var tr := SceneDesignCatalog.rect(SceneDesignCatalog.WORLD[tid]["tag"])
			var pt := tr.position * SceneDesignCatalog.DESIGN / SceneDesignCatalog.NATIVE + Vector2(-16.0, 39.0)
			route_layer.points.append(pt)
	add_child(route_layer)
	refs["route_layer"] = route_layer
	if not route_layer.points.is_empty():
		DynamicUI.create_pulse_ring(self, "StationPulse_0", route_layer.points[0], 34.0, Color("#4BB8E8"))
	var atlas_header := SchoolObjectUI.slab(self, "HeaderBacking", Rect2(54, 32, 476, 124), Color("#FFFDF8", 0.96))
	if not DynamicUI.apply_nine_slice_panel(atlas_header, DynamicUI.THEME_PAPER_MODAL, Vector4(72, 56, 44, 44), Color(1.0, 0.99, 0.96, 0.97)):
		var ahbox := atlas_header.get_theme_stylebox("panel") as StyleBoxFlat
		ahbox.border_color = Color("#368BD2", 0.92)
		ahbox.set_border_width_all(2)
		ahbox.set_corner_radius_all(10)
	atlas_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SchoolObjectUI.text(self, "LocationTitle", "六地区巡回总图", Rect2(90, 36, 430, 62), 42, Color("#15253D"))
	SchoolObjectUI.text(self, "DayTime", GameState.get_detailed_time_string(), Rect2(92, 102, 430, 34), 21, Color("#2A3D58"))
	var back := SchoolObjectUI.hit(self,"BackToLocal",Rect2(1570,42,280,74),"返回地区地图 ×",24)
	DynamicUI.make_cel_button(back, Color("#FFFDF8", 0.94), Color("#21324B"), Color("#CA5443"), 25, 14)
	DynamicUI.slide_in(back, Vector2(0, -10), 0.18, 0.04)
	back.pressed.connect(func(): close_requested.emit())
	refs["back"] = back
	refs["regions"] = {}
	refs["legacy"] = {}
	for raw_id in WorldRegionContent.REGIONS:
		var id := str(raw_id)
		var spec: Dictionary = SceneDesignCatalog.WORLD[id]
		var open_region := func(): region_requested.emit(id)
		var landmark := HomeObjectButton.new()
		landmark.name = "Landmark_" + id
		add_child(landmark)
		landmark.configure_registered(background.texture, SceneDesignCatalog.polygon(spec["polygon"], background.texture.get_size()), SceneDesignCatalog.DESIGN / background.texture.get_size())
		landmark.focus_mode = Control.FOCUS_NONE
		landmark.set_meta("display_label", str(WorldRegionContent.REGIONS[id]["title"]))
		var tag := SceneDesignCatalog.rect(spec["tag"])
		var point := tag.position * SceneDesignCatalog.DESIGN / SceneDesignCatalog.NATIVE
		var card := SchoolObjectUI.hit(self, "RegionCard_" + id, Rect2(point, Vector2(286, 78)), "", 22)
		card.pressed.connect(open_region)
		landmark.pressed.connect(open_region)
		landmark.label_plate = card
		var stop_idx := TOUR_ORDER.find(id) + 1
		var num_badge := Panel.new()
		num_badge.name = "StopBadge"
		num_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_box := StyleBoxFlat.new()
		badge_box.bg_color = Color("#2F8CC9")
		badge_box.set_corner_radius_all(18)
		num_badge.add_theme_stylebox_override("panel", badge_box)
		card.add_child(num_badge)
		DaylightUI.place(num_badge, 14, 21, 36, 36)
		var num_lbl := SchoolObjectUI.text(num_badge, "StopNum", "%02d" % stop_idx, Rect2(0, 0, 36, 36), 15, Color("#FFFDF8"), true)
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title_lbl := SchoolObjectUI.text(card, "CardTitle", str(WorldRegionContent.REGIONS[id]["title"]), Rect2(60, 10, 214, 34), 23, Color("#15253D"), false)
		title_lbl.add_theme_font_override("font", DaylightUI.bold_font())
		title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sub_lbl := SchoolObjectUI.text(card, "CardStatus", "", Rect2(60, 43, 214, 24), 16, Color("#3B5576"), false)
		sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		refs["regions"][id] = {"card": card, "landmark": landmark, "num_badge": num_badge, "num_lbl": num_lbl, "title_lbl": title_lbl, "sub_lbl": sub_lbl}
		for hover_ctrl in [card, landmark]:
			hover_ctrl.mouse_entered.connect(func():
				landmark.hovered = true
				landmark._refresh()
				_show_region_preview(id)
			)
			hover_ctrl.mouse_exited.connect(func():
				landmark.hovered = false
				landmark._refresh()
				_show_region_preview("")
			)
		card.focus_entered.connect(func():
			landmark.hovered = true
			landmark._refresh()
			_show_region_preview(id)
		)
		card.focus_exited.connect(func():
			landmark.hovered = false
			landmark._refresh()
			_show_region_preview("")
		)
	var legend_slab := SchoolObjectUI.slab(self,"LegendBacking",Rect2(54,179,690,46),Color(0.18,0.24,0.37,0.90))
	if not DynamicUI.apply_nine_slice_panel(legend_slab,DynamicUI.THEME_FABRIC_RIBBON,Vector4(56,26,56,26)):
		var legend_box := legend_slab.get_theme_stylebox("panel") as StyleBoxFlat
		legend_box.set_corner_radius_all(8)
		legend_box.border_color = Color("#56C5D0", 0.72)
		legend_box.set_border_width_all(2)
	legend_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var legend := SchoolObjectUI.text(self,"Legend","阿瑞忒学园篇开放中 · 其余巡回学园与灰区随正式章节推进解锁",Rect2(92,184,614,36),20,Color("#FFF8EC"))
	legend.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legend.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	legend.add_theme_constant_override("shadow_offset_y",1)
	var preview_slab := SchoolObjectUI.slab(self,"AtlasPreviewBacking",Rect2(54,978,1812,72),Color(0.18,0.24,0.37,0.90))
	if not DynamicUI.apply_nine_slice_panel(preview_slab,DynamicUI.THEME_FABRIC_RIBBON,Vector4(56,26,56,26)):
		var preview_box := preview_slab.get_theme_stylebox("panel") as StyleBoxFlat
		preview_box.set_corner_radius_all(10)
		preview_box.border_color = Color("#56C5D0", 0.75)
		preview_box.set_border_width_all(2)
	preview_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview_lbl := SchoolObjectUI.text(self,"AtlasPreviewText",_default_atlas_preview(),Rect2(102,986,1716,56),22,Color("#FFF8EC"))
	preview_lbl.add_theme_font_override("font", DaylightUI.bold_font())
	preview_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_lbl.clip_text = true
	refs["preview_text"] = preview_lbl
	GameState.story_flag_updated.connect(_refresh_unlocks)
	SceneSurfaceUI.finish_layering(self,background)
	_refresh_unlocks("",null)
	for rid in refs["regions"]:
		var idx_s := maxi(TOUR_ORDER.find(str(rid)), 0)
		DynamicUI.slide_in(refs["regions"][rid]["card"], Vector2(0, 10), 0.20, float(idx_s) * 0.03)
	back.grab_focus.call_deferred()

func _default_atlas_preview() -> String:
	if bool(GameState.story_flags.get("arete_qualifier_completed", false)):
		return "巡回进度：第 1 站「阿瑞忒」代表选拔赛已全胜制霸！· 下一站：第 2 站「诺莫斯（第二章待开）」· 悬停任意地区查看详情"
	return "巡回进度：第 1 站「阿瑞忒」开放中 · 赢得校内代表选拔赛即可点亮前往「诺莫斯」的巡回航线 · 悬停任意地区查看详情"

func _show_region_preview(rid: String) -> void:
	var lbl := refs.get("preview_text") as Label
	if not is_instance_valid(lbl): return
	if rid == "" or not WorldRegionContent.REGIONS.has(rid):
		lbl.text = _default_atlas_preview()
		return
	var info: Dictionary = WorldRegionContent.REGIONS[rid]
	var stop_idx := TOUR_ORDER.find(rid) + 1
	var title := str(info.get("title", rid))
	var subtitle := str(info.get("subtitle", ""))
	var home_kind := "含专属据点 Home" if str(info.get("home", "")) != "" else "纯剧情探索地区（无 Home）"
	if RegionCatalog.is_unlocked(rid):
		lbl.text = "第 %d 站 · %s（%s）｜ %s ｜ 已开放，点击卡片打开地区地图" % [stop_idx, title, subtitle, home_kind]
	elif rid == "university_nomos" and bool(GameState.story_flags.get("arete_qualifier_completed", false)):
		lbl.text = "第 %d 站 · %s（%s）｜ %s ｜ ✓ 已持有「阿瑞忒代表通行章」，第二章正式剧情筹备中" % [stop_idx, title, subtitle, home_kind]
	else:
		lbl.text = "第 %d 站 · %s（%s）｜ %s ｜ 随后续正式巡回章节推进解锁" % [stop_idx, title, subtitle, home_kind]

func _exit_tree() -> void:
	if GameState.story_flag_updated.is_connected(_refresh_unlocks):
		GameState.story_flag_updated.disconnect(_refresh_unlocks)

func _refresh_unlocks(_flag: String, _value: Variant) -> void:
	var route_layer := refs.get("route_layer") as TourRouteOverlay
	if is_instance_valid(route_layer):
		route_layer.leg_one_ready = bool(GameState.story_flags.get("arete_qualifier_completed", false))
		route_layer.queue_redraw()
	_show_region_preview("")
	var order: Array = [refs["back"]]
	for raw_id in refs["regions"]:
		var id := str(raw_id)
		var available := RegionCatalog.is_unlocked(id)
		var visited := CampusLife.has_visited_region(id)
		var is_next := (not available and id == "university_nomos" and bool(GameState.story_flags.get("arete_qualifier_completed", false)))
		var pair: Dictionary = refs["regions"][id]
		var card: Button = pair["card"]
		var landmark: HomeObjectButton = pair["landmark"]
		var num_badge: Panel = pair["num_badge"]
		var title_lbl: Label = pair["title_lbl"]
		var sub_lbl: Label = pair["sub_lbl"]
		card.disabled = not available
		landmark.disabled = not available
		var mode := "open" if available else ("next" if is_next else "locked")
		DynamicUI.apply_world_card_style(card, mode)
		var bstyle := num_badge.get_theme_stylebox("panel") as StyleBoxFlat
		if available:
			bstyle.bg_color = Color("#2F8CC9")
			title_lbl.add_theme_color_override("font_color", Color("#15253D"))
			sub_lbl.add_theme_color_override("font_color", Color("#226280"))
			sub_lbl.text = "已开放 · 查看地图" if visited else "首次抵达 · 查看地图"
		elif is_next:
			bstyle.bg_color = Color("#DE8A2B")
			title_lbl.add_theme_color_override("font_color", Color("#3E2712"))
			sub_lbl.add_theme_color_override("font_color", Color("#874E15"))
			sub_lbl.text = "第二章待开 · 通行章已备"
		else:
			bstyle.bg_color = Color("#8BA0BD")
			title_lbl.add_theme_color_override("font_color", Color("#4B5E78"))
			sub_lbl.add_theme_color_override("font_color", Color("#5D6E87"))
			sub_lbl.text = "巡回待解锁"
		if mode in ["open", "next"] and not card.has_node("SheenOverlay"):
			var sheen_tint := Color("#FFE8B0", 0.34) if mode == "next" else Color(1, 1, 1, 0.32)
			DynamicUI.attach_sheen(card, sheen_tint, 16)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
		if available: order.append(card)
	for id in refs["legacy"]:
		var button: Button = refs["legacy"][id]
		button.disabled = not RegionCatalog.is_unlocked(str(id))
		if not button.disabled: order.append(button)
	for i in order.size():
		var button: Button = order[i]
		button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
		button.focus_next = button.get_path_to(order[(i+1)%order.size()])
		button.focus_neighbor_top = button.focus_previous
		button.focus_neighbor_left = button.focus_previous
		button.focus_neighbor_bottom = button.focus_next
		button.focus_neighbor_right = button.focus_next
