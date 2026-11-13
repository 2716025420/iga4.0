class_name SchoolRouteScreen
extends Control

const KINDS := {"battle":"练习对局", "elite":"强化挑战", "story":"校园遭遇", "npc":"校园遭遇", "merchant":"补给联络", "chest":"补给箱", "rest":"休息整备", "boss":"终点首领", "exit":"路线出口"}
const CTA_LABELS := {"battle":"开始对局", "elite":"迎接挑战", "story":"前往查看", "npc":"前往交流", "merchant":"前往联络", "chest":"打开补给", "rest":"歇一会儿", "boss":"开始首领战", "exit":"清点收获"}
const COLORS := {"battle":Color("#384A70"), "elite":Color("#7B5372"), "story":Color("#5B6F56"), "npc":Color("#4E6C88"), "merchant":Color("#9B6B40"), "chest":Color("#9B5B41"), "rest":Color("#4E7563"), "boss":Color("#8E4652"), "exit":Color("#4A6B69")}
const ATLAS_KINDS := ["battle", "story", "npc", "chest", "merchant", "rest", "boss", "exit"]
const WIDE_BACKDROP_PATH := "res://assets/ui/school_objects/route_station_wide.png"
const LEGACY_BACKDROP_PATH := "res://assets/ui/school_objects/route_station.png"
const RIBBON_PATH := "res://assets/ui_core/theme/ribbon_header_9slice.png"
const DUEL_FRAME_PATH := "res://assets/combat/card_frame_duel.png"

var presentation: Control
var content: Control
var refs: Dictionary = {}
var _refresh_pending := false
var _busy := false
var _confirm_retreat := false
var _feedback_node_id := ""
var _feedback_text := ""
var _atlas: Texture2D
var _backdrop: TextureRect
var _progress: ProgressTrack

class ProgressTrack extends Control:
	var depth := 0
	var boss_defeated := false

	func _draw() -> void:
		var arrow_col := Color(0.55, 0.44, 0.30, 0.65)
		var ring_col := Color("#8B6D46")
		for index in 6:
			var cx := 230.0 + index * 195.0
			var center := Vector2(cx, 155.0)
			var active := index == depth
			var done := index < depth
			if index < 5:
				var ax := cx + 38.0
				var bx := cx + 157.0
				draw_line(Vector2(ax, center.y), Vector2(bx, center.y), arrow_col, 2.2, true)
				draw_line(Vector2(bx - 10.0, center.y - 6.0), Vector2(bx, center.y), arrow_col, 2.2, true)
				draw_line(Vector2(bx - 10.0, center.y + 6.0), Vector2(bx, center.y), arrow_col, 2.2, true)
			if active:
				draw_circle(center, 31.0, Color(0.82, 0.56, 0.22, 0.22))
			var radius := 27.0 if active else 23.0
			var fill := Color("#78967B") if done else (Color("#B9792C") if active else Color("#F5EAD4"))
			draw_circle(center, radius, fill)
			draw_arc(center, radius, 0, TAU, 36, Color("#F9E1AD") if active else ring_col, 2.4 if active else 1.6, true)
			if active:
				draw_arc(center, radius - 4.0, 0, TAU, 36, Color("#FFF3D8"), 1.2, true)

		var ax_last := 230.0 + 5.0 * 195.0 + 38.0
		var bx_boss := 1344.0
		draw_line(Vector2(ax_last, 155.0), Vector2(bx_boss, 155.0), arrow_col, 2.2, true)
		draw_line(Vector2(bx_boss - 10.0, 149.0), Vector2(bx_boss, 155.0), arrow_col, 2.2, true)
		draw_line(Vector2(bx_boss - 10.0, 161.0), Vector2(bx_boss, 155.0), arrow_col, 2.2, true)

		var boss_rect := Rect2(1354.0, 129.0, 168.0, 52.0)
		var boss_fill := Color("#78967B") if boss_defeated else (Color("#A84B47") if depth >= 6 else Color("#EDE1CA"))
		draw_rect(boss_rect, boss_fill, true)
		draw_rect(boss_rect, Color("#D8B87E") if depth >= 6 else ring_col, false, 2.0)

		draw_line(Vector2(1532.0, 155.0), Vector2(1596.0, 155.0), arrow_col, 2.2, true)
		draw_line(Vector2(1586.0, 149.0), Vector2(1596.0, 155.0), arrow_col, 2.2, true)
		draw_line(Vector2(1586.0, 161.0), Vector2(1596.0, 155.0), arrow_col, 2.2, true)

		var exit_rect := Rect2(1606.0, 129.0, 146.0, 52.0)
		var exit_fill := Color("#547864") if boss_defeated else Color("#EDE1CA")
		draw_rect(exit_rect, exit_fill, true)
		draw_rect(exit_rect, Color("#D8B87E") if boss_defeated else ring_col, false, 2.0)

func _ready() -> void:
	# Old results belong to the previous visit; opening a route never replays them.
	_feedback_node_id = str(GameState.exploration_state.get("last_result", {}).get("node_id", ""))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = DaylightUI.get_theme()
	presentation = Control.new()
	presentation.name = "RoutePresentation"
	presentation.size = SchoolObjectUI.DESIGN
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presentation)

	var bg_path := WIDE_BACKDROP_PATH if ResourceLoader.exists(WIDE_BACKDROP_PATH) else LEGACY_BACKDROP_PATH
	var bg_rect := Rect2(-210, 0, 2340, 1080) if bg_path == WIDE_BACKDROP_PATH else Rect2(0, 0, 1920, 1080)
	_backdrop = SchoolObjectUI.art(presentation, "StationBackdrop", bg_path, bg_rect)
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE

	_build_header_ribbon()
	_build_progress_strip()

	content = Control.new()
	content.name = "EncounterArea"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(content)
	DaylightUI.place(content, 0, 214, 1920, 614)

	_build_bottom_shelf()

	if ResourceLoader.exists("res://assets/ui/school_objects/route_encounters.png"):
		_atlas = load("res://assets/ui/school_objects/route_encounters.png")
	GameState.exploration_changed.connect(_schedule_refresh)
	resized.connect(_layout_route)
	_layout_route()
	_refresh()

func _build_header_ribbon() -> void:
	var ribbon := Panel.new()
	ribbon.name = "TopHeaderRibbon"
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(RIBBON_PATH):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(RIBBON_PATH) as Texture2D
		atlas.region = Rect2(12, 14, 996, 98)
		atlas.filter_clip = true
		var tex_style := StyleBoxTexture.new()
		tex_style.texture = atlas
		tex_style.texture_margin_left = 56
		tex_style.texture_margin_right = 56
		tex_style.texture_margin_top = 18
		tex_style.texture_margin_bottom = 18
		ribbon.add_theme_stylebox_override("panel", tex_style)
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color("#242E46")
		flat.set_corner_radius_all(8)
		ribbon.add_theme_stylebox_override("panel", flat)
	presentation.add_child(ribbon)
	DaylightUI.place(ribbon, 24, 14, 1872, 82)

	var dungeon := SchoolObjectUI.text(presentation, "Dungeon", "", Rect2(92, 22, 740, 66), 34, Color("#FFF7E8"))
	dungeon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dungeon.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	refs["dungeon"] = dungeon

	var hp_pill := _pill_panel(presentation, "HPPill", Rect2(860, 29, 286, 52), Color("#FAF2E4"), Color("#CDB07E"))
	SchoolObjectUI.art(hp_pill, "HPIcon", "res://assets/ui/icon_heart.svg", Rect2(16, 10, 32, 32))
	var hp_label := SchoolObjectUI.text(hp_pill, "HP", "", Rect2(56, 4, 218, 44), 23, SchoolObjectUI.INK)
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	refs["hp"] = hp_label

	var pt_pill := _pill_panel(presentation, "PointsPill", Rect2(1162, 29, 252, 52), Color("#FAF2E4"), Color("#CDB07E"))
	SchoolObjectUI.art(pt_pill, "PointsIcon", "res://assets/ui_core/icons/economy/icon_practice_points.png", Rect2(14, 8, 36, 36))
	var pt_label := SchoolObjectUI.text(pt_pill, "Points", "", Rect2(56, 4, 184, 44), 23, SchoolObjectUI.INK)
	pt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	refs["points"] = pt_label

	refs["pause"] = _action(presentation, "Pause", Rect2(1442, 29, 172, 52), "Ⅱ 暂离", _pause, Color("#2C3752"), true)
	refs["retreat"] = _action(presentation, "Retreat", Rect2(1630, 29, 206, 52), "结束训练", _request_retreat, Color("#733D42"), true)

func _build_progress_strip() -> void:
	var strip := _pill_panel(presentation, "ProgressStrip", Rect2(100, 108, 1720, 94), Color(0.98, 0.95, 0.88, 0.95), Color("#C9AF82"))
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress = ProgressTrack.new()
	_progress.name = "ProgressTrack"
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(_progress)
	_progress.size = Vector2(1920, 220)
	for index in 6:
		var lbl := SchoolObjectUI.text(presentation, "Checkpoint_" + str(index), str(index + 1), Rect2(230.0 + index * 195.0 - 28.0, 130.0, 56.0, 50.0), 25, SchoolObjectUI.INK, true)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		refs["cp_" + str(index)] = lbl
	var boss_lbl := SchoolObjectUI.text(presentation, "Checkpoint_6", "终点首领", Rect2(1354, 129, 168, 52), 23, SchoolObjectUI.INK, true)
	boss_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	refs["cp_6"] = boss_lbl
	var exit_lbl := SchoolObjectUI.text(presentation, "Checkpoint_7", "出口", Rect2(1606, 129, 146, 52), 23, SchoolObjectUI.INK, true)
	exit_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exit_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	refs["cp_7"] = exit_lbl

func _build_bottom_shelf() -> void:
	var shelf := _pill_panel(presentation, "DeckDisplayShelf", Rect2(100, 842, 1230, 212), Color(0.95, 0.90, 0.80, 0.94), Color("#B89866"))
	var ledge := ColorRect.new()
	ledge.name = "WoodLedge"
	ledge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ledge.color = Color(0.56, 0.40, 0.25, 0.85)
	shelf.add_child(ledge)
	DaylightUI.place(ledge, 0, 198, 1230, 14)

	var deck_title := SchoolObjectUI.text(presentation, "DeckTitle", "本次\n携带卡组", Rect2(124, 888, 138, 118), 26, SchoolObjectUI.INK, true)
	deck_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	deck_title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))

	var deck := Control.new()
	deck.name = "RunDeck"
	deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(deck)
	refs["deck"] = deck

	var status_card := _pill_panel(presentation, "StatusStandee", Rect2(1366, 842, 454, 212), Color(0.98, 0.95, 0.89, 0.96), Color("#B89866"))
	var status_head := ColorRect.new()
	status_head.name = "StatusBanner"
	status_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_head.color = Color("#313E59")
	status_card.add_child(status_head)
	DaylightUI.place(status_head, 0, 0, 454, 44)
	var status_title := SchoolObjectUI.text(status_card, "StatusTitle", "本轮路线状态", Rect2(16, 4, 422, 36), 22, Color("#FFF7E8"), true)
	status_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))

	var stage := SchoolObjectUI.text(status_card, "StageTitle", "", Rect2(22, 54, 410, 40), 22, SchoolObjectUI.INK)
	stage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	refs["stage"] = stage
	var earned := SchoolObjectUI.text(status_card, "Earned", "", Rect2(22, 98, 410, 36), 21, Color("#4D6F57"))
	earned.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	refs["earned"] = earned
	var hint := SchoolObjectUI.text(status_card, "FooterHint", "每段只走一条路，暂离后可继续。", Rect2(22, 144, 410, 52), 19, SchoolObjectUI.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _pill_panel(parent: Control, node_name: String, rect: Rect2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.18, 0.14, 0.10, 0.14)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	DaylightUI.place(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return panel

func _layout_route() -> void:
	if not is_instance_valid(presentation): return
	var tex := _backdrop.texture if is_instance_valid(_backdrop) else null
	Platform.fit_stage(self, presentation, Color("#332927"), tex)

func _schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	_refresh.call_deferred()

func _clear(parent: Control) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	_refresh_pending = false
	_busy = false
	_clear(content)
	refs["card_buttons"] = {}
	refs["choice_buttons"] = {}
	refs["offer_buttons"] = {}
	var state := GameState.exploration_state
	if not GameState.exploration_active or not SchoolExplorationFlow.enabled():
		SchoolPaperSurface.create(content, "NoRunSurface", Rect2(420, 120, 1080, 340), Color(0.98, 0.95, 0.89, 0.96))
		SchoolObjectUI.text(content, "NoRun", "先到体育馆选择一条校园路线。", Rect2(460, 165, 1000, 90), 38, SchoolObjectUI.INK, true)
		_action(content, "ReturnHome", Rect2(760, 290, 400, 74), "返回体育馆", func(): CampusLife.return_from_training(), Color("#4A6B69"), true)
		return

	var definition := ExplorationContent.dungeon_definition(str(state["dungeon_id"]))
	var title_text := str(definition.get("title", "校园路线"))
	var diff_text := str(definition.get("difficulty", ""))
	refs["dungeon"].text = ("%s · %s" % [title_text, diff_text]) if diff_text != "" else title_text
	refs["hp"].text = "体力 %d / %d" % [GameState.player_current_hp, GameState.player_max_hp]
	refs["points"].text = "练习点 %d" % GameState.scrap_metal
	var earned: Dictionary = state.get("earned", {})
	var quality := str(definition.get("quality", "common"))
	refs["earned"].text = "本趟 %s：%d" % [ExplorationContent.MATERIAL_NAMES[quality], int(earned.get("materials", {}).get(quality, 0))]

	var depth := int(state.get("depth", 0))
	var boss_defeated := bool(state.get("boss_defeated", false))
	refs["stage"].text = "第 %d / 6 段" % (depth + 1) if depth < 6 else ("出口已开放" if boss_defeated else "终点挑战 · 首领战")
	if state.get("stage", "") != "map":
		var current := GameState.get_exploration_node(str(state.get("current_node_id", "")))
		refs["stage"].text = ("第 %d 段 · " % (depth + 1) if depth < 6 else "") + str(KINDS.get(SchoolExplorationRoutes.kind_for(current), "途中"))

	_progress.depth = depth
	_progress.boss_defeated = boss_defeated
	_progress.queue_redraw()
	for index in 6:
		var lbl := refs.get("cp_" + str(index)) as Label
		if is_instance_valid(lbl):
			lbl.add_theme_color_override("font_color", Color("#FFF8EC") if index <= depth else SchoolObjectUI.INK)
	var boss_lbl := refs.get("cp_6") as Label
	if is_instance_valid(boss_lbl):
		boss_lbl.add_theme_color_override("font_color", Color("#FFF8EC") if (boss_defeated or depth >= 6) else SchoolObjectUI.INK)
	var exit_lbl := refs.get("cp_7") as Label
	if is_instance_valid(exit_lbl):
		exit_lbl.add_theme_color_override("font_color", Color("#FFF8EC") if boss_defeated else SchoolObjectUI.INK)

	var last: Dictionary = state.get("last_result", {})
	var result_id := str(last.get("node_id", ""))
	if result_id != _feedback_node_id:
		_feedback_node_id = result_id
		var previous_node := GameState.get_exploration_node(result_id)
		_feedback_text = "" if not previous_node.get("enemy_keys", []).is_empty() else "已完成：%s%s" % [last.get("title", ""), " · 恢复%d体力" % int(last["heal"]) if int(last.get("heal", 0)) > 0 else ""]
	if _feedback_text != "":
		var fb_bg := _pill_panel(content, "FeedbackBacking", Rect2(440, 8, 1040, 42), Color(0.99, 0.95, 0.87, 0.95), Color("#C9AE80"))
		var fb := SchoolObjectUI.text(fb_bg, "Feedback", _feedback_text, Rect2(20, 3, 1000, 36), 22, SchoolObjectUI.INK, true)
		fb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_refresh_deck_shelf(state.get("deck", []))

	if _confirm_retreat:
		_draw_retreat()
	elif state.get("stage", "") == "map":
		var available := GameState.get_exploration_available_nodes()
		var card_w := 360.0
		var gap := 58.0
		var left := (1920.0 - (available.size() * card_w + maxf(0, available.size() - 1) * gap)) / 2.0
		for index in available.size():
			_route_card(GameState.get_exploration_node(available[index]), Vector2(left + index * (card_w + gap), 64.0))
		var buttons: Array = refs["card_buttons"].values()
		for index in buttons.size():
			buttons[index].focus_neighbor_left = buttons[index].get_path_to(buttons[maxi(0, index - 1)])
			buttons[index].focus_neighbor_right = buttons[index].get_path_to(buttons[mini(buttons.size() - 1, index + 1)])
			buttons[index].focus_neighbor_top = buttons[index].get_path_to(refs["pause"])
		if not buttons.is_empty(): buttons[0].grab_focus.call_deferred()
	else:
		_encounter(GameState.get_exploration_node(str(state.get("current_node_id", ""))))

func _refresh_deck_shelf(run_deck: Array) -> void:
	var deck := refs["deck"] as Control
	_clear(deck)
	var count := run_deck.size()
	if count == 0: return
	var start_x := 288.0
	var avail_w := 1020.0
	var card_w := 108.0
	var card_h := 152.0
	var step := minf(162.0, (avail_w - card_w) / maxf(1, count - 1)) if count > 1 else 0.0
	var duel_tex := load(DUEL_FRAME_PATH) as Texture2D if ResourceLoader.exists(DUEL_FRAME_PATH) else null
	for index in count:
		var id := str(run_deck[index].get("id", ""))
		var card_data: CardData = GameState.get_card(id)
		var card_title := card_data.name if card_data != null else str(run_deck[index].get("name", id))
		var x := start_x + index * step
		var holder := Control.new()
		holder.name = "Card_" + id
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.add_child(holder)
		DaylightUI.place(holder, x, 854, card_w, 186)

		var art := TextureRect.new()
		art.name = "Art"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.clip_contents = true
		art.texture = SceneSkin.illustration_texture(SceneSkin.card_illustration_path(id))
		holder.add_child(art)
		if duel_tex != null:
			var sx := card_w / 512.0
			var sy := card_h / 720.0
			DaylightUI.place(art, 34.0 * sx, 104.0 * sy, 444.0 * sx, 460.0 * sy)
			var frame := TextureRect.new()
			frame.name = "Frame"
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			frame.stretch_mode = TextureRect.STRETCH_SCALE
			frame.texture = duel_tex
			holder.add_child(frame)
			DaylightUI.place(frame, 0, 0, card_w, card_h)
		else:
			DaylightUI.place(art, 6, 6, card_w - 12, card_h - 12)

		var cap := SchoolObjectUI.text(holder, "Name", card_title, Rect2(-10, 155, card_w + 20, 28), 16, SchoolObjectUI.INK, true)
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _illustration(parent: Control, kind: String, rect: Rect2) -> TextureRect:
	var art := SchoolObjectUI.art(parent, "EncounterArt", "", rect)
	var key := "battle" if kind == "elite" else kind
	var index := ATLAS_KINDS.find(key)
	if _atlas != null and index >= 0:
		var texture := AtlasTexture.new()
		texture.atlas = _atlas
		var cell := _atlas.get_size() / Vector2(4, 2)
		texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
		texture.filter_clip = true
		art.texture = texture
	return art

func _route_card(node: Dictionary, point: Vector2) -> void:
	var kind := SchoolExplorationRoutes.kind_for(node)
	var tone: Color = COLORS.get(kind, COLORS["battle"])
	var card := Control.new()
	card.name = "Route_" + str(node["id"])
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(card)
	DaylightUI.place(card, point.x, point.y, 360, 514)

	_pill_panel(card, "StandeePaper", Rect2(0, 12, 360, 502), Color("#FAF2E4"), Color("#C8AF82"))
	_pill_panel(card, "BrassClip", Rect2(158, 0, 44, 20), Color("#D29F4C"), Color("#8F6422"))
	var header := _pill_panel(card, "KindBanner", Rect2(44, 26, 272, 42), tone, tone.darkened(0.2))
	var kind_lbl := SchoolObjectUI.text(header, "KindLabel", str(KINDS.get(kind, "探索")), Rect2(8, 2, 256, 38), 22, Color("#FFF7E8"), true)
	kind_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kind_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))

	_pill_panel(card, "ArtMat", Rect2(30, 80, 300, 212), Color("#F2E6D0"), Color("#D2C09E"))
	_illustration(card, kind, Rect2(38, 86, 284, 200))

	var title_lbl := SchoolObjectUI.text(card, "RouteName", str(node["title"]), Rect2(24, 302, 312, 38), 26, SchoolObjectUI.INK, true)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))

	var description := SchoolObjectUI.text(card, "Description", str(node["description"]), Rect2(26, 344, 308, 62), 20, SchoolObjectUI.INK, true)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.clip_text = true
	description.set_deferred("size", Vector2(308, 62))

	var reward := ExplorationContent.reward_text(node.get("reward", {}))
	if kind == "npc": reward = "帮忙整理 / 停下来聊聊"
	elif kind == "merchant": reward = "整理训练记录"
	elif int(node.get("heal", 0)) > 0: reward = "恢复 %d 体力" % int(node["heal"])
	elif kind == "exit": reward = "清点这一趟的收获离开"
	var reward_label := SchoolObjectUI.text(card, "Reward", reward, Rect2(26, 408, 308, 32), 19, SchoolObjectUI.MUTED, true)
	reward_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_label.clip_text = true
	reward_label.set_deferred("size", Vector2(308, 32))

	var cta_bar := _pill_panel(card, "ActionBadge", Rect2(44, 448, 272, 46), tone, tone.darkened(0.2))
	var cta_lbl := SchoolObjectUI.text(cta_bar, "CTALabel", str(CTA_LABELS.get(kind, "选择路线")), Rect2(8, 2, 256, 42), 22, Color("#FFF8EC"), true)
	cta_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var button := SchoolObjectUI.hit(card, "Choose", Rect2(4, 14, 352, 496))
	SchoolObjectUI.borderless(button)
	button.pressed.connect(_choose.bind(str(node["id"])))
	refs["card_buttons"][node["id"]] = button

func _choose(id: String) -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	_feedback_text = ""
	if not GameState.choose_exploration_node(id): _busy = false

func _modal_paper(parent: Control, node_name: String, rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", CombatSkin.paper(Vector4(24, 24, 24, 24)))
	parent.add_child(panel)
	DaylightUI.place(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return panel

func _encounter(node: Dictionary) -> void:
	if node.is_empty(): return
	var kind := SchoolExplorationRoutes.kind_for(node)
	_modal_paper(content, "EncounterSurface", Rect2(160, 32, 1600, 536))
	_pill_panel(content, "EncounterArtFrame", Rect2(198, 72, 512, 424), Color("#F2E6D0"), Color("#D2C09E"))
	_illustration(content, kind, Rect2(208, 82, 492, 404))
	var heading := SchoolObjectUI.text(content, "EncounterTitle", str(node["title"]), Rect2(760, 68, 940, 74), 44)
	heading.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var copy := SchoolObjectUI.text(content, "EncounterDescription", str(node.get("description", "")), Rect2(764, 148, 920, 92), 27)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.set_deferred("size", Vector2(920, 92))
	var tone: Color = COLORS.get(kind, COLORS["chest"])
	match kind:
		"merchant":
			SchoolObjectUI.text(content, "SupplyContact", "补给联络点已完成登记，可以继续前进。", Rect2(764, 260, 920, 96), 27)
			refs["continue"] = _action(content, "LeaveMerchant", Rect2(1380, 444, 300, 68), "继续训练", _settle.bind("leave"), tone, true)
		"npc":
			for index in node.get("choices", []).size():
				var choice: Dictionary = node["choices"][index]
				var reward := ExplorationContent.reward_text(choice.get("reward", {})) if int(choice.get("heal", 0)) == 0 else "恢复%d体力" % int(choice["heal"])
				var button := _action(content, "Choice_" + str(choice["id"]), Rect2(764, 268 + index * 110, 916, 84), str(choice["title"]) + " · " + reward, _settle.bind(str(choice["id"])), tone, true)
				refs["choice_buttons"][choice["id"]] = button
		"exit":
			SchoolObjectUI.text(content, "ExitSummary", ExplorationContent.reward_text(GameState.exploration_state.get("earned", {})) + "\n此前训练消耗 %d 练习点" % int(GameState.exploration_state.get("spent_points", 0)), Rect2(764, 255, 920, 100), 27)
			refs["continue"] = _action(content, "ConfirmExit", Rect2(1070, 420, 610, 82), "收好这一趟的收获 · 返回体育馆", _exit_run, tone, true)
		_:
			SchoolObjectUI.text(content, "EncounterReward", "恢复%d体力" % int(node.get("heal", 0)) if int(node.get("heal", 0)) > 0 else ExplorationContent.reward_text(node.get("reward", {})), Rect2(764, 255, 920, 90), 29)
			refs["continue"] = _action(content, "SettleEncounter", Rect2(1110, 420, 570, 82), "坐下来歇一会儿" if kind == "rest" else "打开补给箱", _settle.bind("victory"), tone, true)

func _settle(outcome: String) -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	if not GameState.complete_exploration_node(str(GameState.exploration_state.get("current_node_id", "")), outcome): _busy = false

func _exit_run() -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	if GameState.finish_exploration("victory"): CampusLife.return_from_training()
	else: _busy = false

func _action(parent: Control, node_name: String, rect: Rect2, label: String, callback: Callable, color: Color = Color("#4E6C88"), light_text: bool = false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = label
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color
		if state == "hover": box.bg_color = color.lightened(0.08)
		elif state in ["pressed", "hover_pressed"]: box.bg_color = color.darkened(0.12)
		elif state == "disabled": box.bg_color = Color("#A89E92")
		box.set_corner_radius_all(10)
		box.set_border_width_all(0)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := Color("#FFF8EC") if light_text else SchoolObjectUI.INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, ink)
	SchoolObjectUI.borderless(button)
	parent.add_child(button)
	DaylightUI.place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	button.pressed.connect(callback)
	return button

func _pause() -> void:
	if not _busy: GameState.pause_exploration()

func _request_retreat() -> void:
	if _busy or SceneManager.is_transitioning: return
	_confirm_retreat = true
	_refresh()

func _draw_retreat() -> void:
	_modal_paper(content, "RetreatSurface", Rect2(160, 32, 1600, 536))
	_pill_panel(content, "RetreatArtFrame", Rect2(198, 72, 512, 424), Color("#F2E6D0"), Color("#D2C09E"))
	_illustration(content, "exit", Rect2(208, 82, 492, 404))
	var heading := SchoolObjectUI.text(content, "RetreatTitle", "结束这次训练？", Rect2(760, 88, 920, 82), 44)
	heading.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	SchoolObjectUI.text(content, "RetreatDescription", "已收集的材料与练习点会保留。\n结束后，这条路线将不能继续。", Rect2(760, 200, 920, 120), 29)
	refs["cancel_retreat"] = _action(content, "CancelRetreat", Rect2(760, 412, 410, 78), "再走一会儿", func(): _confirm_retreat = false; _refresh(), Color("#4A6B69"), true)
	refs["confirm_retreat"] = _action(content, "ConfirmRetreat", Rect2(1240, 412, 410, 78), "结束并返回", func(): GameState.retreat_exploration(), Color("#8E4652"), true)
	refs["cancel_retreat"].grab_focus.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _confirm_retreat:
			_confirm_retreat = false
			_refresh()
		else: _pause()
		get_viewport().set_input_as_handled()
