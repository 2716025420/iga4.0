class_name ZodiacAlbumPanel
extends Control

## Museum-ivory 12-zodiac special card binder (1920x1080) with cel-anime card portraits and reveal effects.
signal close_requested
signal action_requested(action: String, payload: Dictionary)

const DESIGN := Vector2(1920.0, 1080.0)
const PAPER := Color("#FAF6ED")
const DETAIL_FILL := Color("#F1E9D9")
const PILL_FILL := Color("#EFE7D8")
const PILL_HOVER := Color("#E5DBC7")
const PILL_PRESSED := Color("#DBD0B9")
const INK := Color("#1E2836")
const SECONDARY := Color("#424D5C")
const RULE := Color("#B9975B")
const SAGE := Color("#54745D")
const WARM_GOLD := Color("#8C6A36")

const CARD_FRAME_PATH := "res://assets/ui/zodiac_cards/zodiac_card_frame.png"
const CARD_BACK_PATH := "res://assets/ui/zodiac_cards/zodiac_card_back.png"
const SEAL_CIRCLE_PATH := "res://assets/ui/zodiac_cards/anim_zodiac_seal_circle.svg"
const SPARKLE_ATLAS_PATH := "res://assets/ui/zodiac_cards/anim_cel_reveal_sparkle_4x2.png"
const RESONANCE_HALO_PATH := "res://assets/ui_core/animations/ui_zodiac_resonance_halo.png"
const SERIF_FONT_PATH := "res://assets/fonts/NotoSerifSC-SemiBold.ttf"

const CARD_CANVAS := Vector2(640.0, 960.0)
const ART_COVER_RECT := Rect2(35.0, 34.0, 570.0, 823.0)
const NAMEPLATE_RECT := Rect2(56.0, 862.0, 528.0, 56.0)
const CLIP_POLYGON_POINTS := [
	Vector2(86.0, 40.0), Vector2(554.0, 40.0), Vector2(570.0, 61.0), Vector2(604.0, 79.0),
	Vector2(604.0, 812.0), Vector2(568.0, 832.0), Vector2(551.0, 853.0), Vector2(89.0, 853.0),
	Vector2(70.0, 833.0), Vector2(36.0, 812.0), Vector2(36.0, 79.0), Vector2(67.0, 62.0)
]

var context: Dictionary = {}
var refs: Dictionary = {}
var selected_zodiac := "hero"
var _uncollected_shader: Shader
var _card_textures: Dictionary = {}
var _frame_texture: Texture2D
var _back_texture: Texture2D
var _seal_texture: Texture2D
var _sparkle_frames: Array[AtlasTexture] = []
var _serif_font: Font
var _owned_cache: Dictionary = {}
var _reveal_tween: Tween
var _sparkle_tween: Tween
var _detail_seal: TextureRect
var _detail_sparkle: TextureRect
var _detail_face: Control
var _resonance_halo: TextureRect

static func create(_kind: String = "zodiac", panel_context: Dictionary = {}) -> ZodiacAlbumPanel:
	var panel := ZodiacAlbumPanel.new()
	panel.set_meta("design_size", DESIGN)
	panel.set_meta("full_scene_overlay", true)
	panel.custom_minimum_size = DESIGN
	panel.size = DESIGN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.refresh(panel_context)
	return panel

func _ready() -> void:
	Platform.input_mode_changed.connect(_on_input_mode_changed)

func _process(delta: float) -> void:
	if is_instance_valid(_resonance_halo) and _resonance_halo.visible and not SaveManager.settings.get("reduced_motion", false):
		_resonance_halo.rotation += delta * 0.25

func _on_input_mode_changed(_touch: bool) -> void:
	var hint_node := find_child("CloseHint", true, false) as Label
	if is_instance_valid(hint_node):
		hint_node.text = Platform.hint("Esc 返回 · 方向键浏览", "点击星座查看详细档案")

func refresh(panel_context: Dictionary = {}) -> void:
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if _sparkle_tween and _sparkle_tween.is_valid():
		_sparkle_tween.kill()
	if not panel_context.is_empty():
		context.merge(panel_context, true)
	if context.has("selected_zodiac") and ZodiacCatalog.known(str(context["selected_zodiac"])):
		selected_zodiac = str(context["selected_zodiac"])

	var play_reveal_for := str(panel_context.get("play_reveal", ""))
	if not _owned_cache.is_empty():
		for id in ZodiacCatalog.ORDER:
			var now_owned := SpecialCardCollection.collected(id)
			if now_owned and not bool(_owned_cache.get(id, false)):
				selected_zodiac = id
				play_reveal_for = id
				break

	_ensure_assets_loaded()
	_resonance_halo = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	theme = DaylightUI.get_theme()
	size = DESIGN

	# Full-bleed paper backing covers ultra-wide 20:9 margins seamlessly without side bars.
	var bleed := ColorRect.new()
	bleed.name = "FullBleedPaper"
	bleed.color = PAPER
	bleed.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bleed)
	DaylightUI.place(bleed, -600, -300, 3120, 1680)

	var snapshot := SpecialCardCollection.snapshot()
	var owned_count: int = snapshot["collected"].size()

	var title := _text(self, "Title", "十二星座图鉴", Rect2(80, 48, 340, 58), 40, INK)
	if _serif_font != null:
		title.add_theme_font_override("font", _serif_font)
	_text(self, "Subtitle", "永久剧情收藏 · 已收录 %d / 12" % owned_count, Rect2(395, 58, 480, 38), 22, SECONDARY)

	var records_btn := _pill_button(self, "OpenRecords", "放映档案", Rect2(1506, 48, 180, 44))
	records_btn.pressed.connect(func(): action_requested.emit("open_records", {}))
	refs["open_records"] = records_btn

	var close := _pill_button(self, "CloseButton", "返回 ×", Rect2(1704, 48, 136, 44))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close

	var header_rule := SchoolObjectUI.rule(self, "HeaderRule", Rect2(80, 113, 1760, 1))
	header_rule.color = Color(RULE, 0.50)

	var badges := {}
	var order := ZodiacCatalog.ORDER
	for index in order.size():
		var id: String = order[index]
		var data := ZodiacCatalog.definition(id)
		var owned := SpecialCardCollection.collected(id)
		_owned_cache[id] = owned
		var is_sel := id == selected_zodiac
		var col := index % 4
		var row := index / 4
		var tile_rect := Rect2(107.0 + col * 224.0, 152.0 + row * 266.0, 148.0, 222.0)

		if is_sel:
			_selection_marker(self, tile_rect)

		var tile := _tile_button(self, "Badge_" + id, tile_rect, is_sel)
		var face := ZodiacCardFace.new()
		face.name = "CardFace"
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.configure(id, data, owned, _card_textures.get(id), _frame_texture, _back_texture, _serif_font, false)
		tile.add_child(face)
		DaylightUI.place(face, 0, 0, tile_rect.size.x, tile_rect.size.y)

		var badge_path := "res://assets/ui/zodiac_badges/%s.svg" % str(data["zodiac"])
		var icon := SchoolObjectUI.art(tile, "BadgeIcon", badge_path, Rect2(52, 138, 44, 44))
		if owned:
			icon.material = null
			icon.visible = false
		else:
			if _uncollected_shader != null:
				var mat := ShaderMaterial.new()
				mat.shader = _uncollected_shader
				icon.material = mat
			icon.modulate = Color(0.95, 0.90, 0.80, 0.88)
			icon.visible = true

		var caption_color := INK if owned else SECONDARY
		var caption := _text(self, "Caption_" + id, "%02d · %s" % [int(data["number"]), str(data["name"])], Rect2(tile_rect.position.x - 16.0, tile_rect.position.y + tile_rect.size.y + 8.0, tile_rect.size.x + 32.0, 26.0), 18, caption_color, true)
		if _serif_font != null and owned:
			caption.add_theme_font_override("font", _serif_font)

		tile.pressed.connect(_select_badge.bind(id))
		badges[id] = tile
	refs["badges"] = badges

	var divider := SchoolObjectUI.rule(self, "DetailDivider", Rect2(1009, 148, 1, 805))
	divider.color = Color(RULE, 0.45)

	_build_detail_pane(1041.0, 151.0, 799.0, 799.0)

	var footer_rule := SchoolObjectUI.rule(self, "FooterRule", Rect2(80, 982, 1760, 1))
	footer_rule.color = Color(RULE, 0.50)

	_text(self, "PermanentStory", "剧情收藏永久保留 · 不加入普通卡组，不参与商店交易", Rect2(80, 1007, 900, 28), 19, SECONDARY)
	var hint_label := _text(self, "CloseHint", Platform.hint("Esc 返回 · 方向键浏览", "点击星座查看详细档案"), Rect2(1380, 1007, 460, 28), 19, SECONDARY)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_wire_focus()
	if play_reveal_for != "" and play_reveal_for == selected_zodiac and SpecialCardCollection.collected(selected_zodiac):
		_play_reveal_effect()

func _select_badge(id: String) -> void:
	selected_zodiac = id
	var should_reveal := SpecialCardCollection.collected(id)
	refresh({"play_reveal": id if should_reveal else ""})
	var btn := refs.get("badges", {}).get(id) as Button
	if is_instance_valid(btn):
		btn.grab_focus.call_deferred()

func _build_detail_pane(x: float, y: float, w: float, h: float) -> void:
	var pane := Panel.new()
	pane.name = "ZodiacDetail"
	pane.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = DETAIL_FILL
	style.set_border_width_all(0)
	pane.add_theme_stylebox_override("panel", style)
	add_child(pane)
	DaylightUI.place(pane, x, y, w, h)

	_draw_hairline_box(pane, "MatRule", Rect2(12, 12, w - 24.0, h - 24.0), Color(RULE, 0.42))

	var sel := ZodiacCatalog.definition(selected_zodiac)
	var sel_owned := SpecialCardCollection.collected(selected_zodiac)

	var card_rect := Rect2(32.0, 117.0, 348.0, 522.0)
	var is_active_res := GameState.get_active_zodiac_id() == selected_zodiac
	if is_active_res and ResourceLoader.exists(RESONANCE_HALO_PATH):
		_resonance_halo = TextureRect.new()
		_resonance_halo.name = "DetailResonanceHalo"
		_resonance_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_resonance_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_resonance_halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_resonance_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_resonance_halo.texture = load(RESONANCE_HALO_PATH) as Texture2D
		_resonance_halo.modulate = Color(1.0, 1.0, 1.0, 0.88)
		_resonance_halo.pivot_offset = Vector2(236.0, 236.0)
		pane.add_child(_resonance_halo)
		DaylightUI.place(_resonance_halo, card_rect.position.x + (card_rect.size.x - 472.0) * 0.5, card_rect.position.y + (card_rect.size.y - 472.0) * 0.5, 472.0, 472.0)

	_detail_seal = TextureRect.new()
	_detail_seal.name = "DetailRevealSeal"
	_detail_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_seal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_seal.texture = _seal_texture
	_detail_seal.modulate.a = 0.0
	_detail_seal.visible = false
	_detail_seal.pivot_offset = Vector2(230.0, 230.0)
	pane.add_child(_detail_seal)
	DaylightUI.place(_detail_seal, card_rect.position.x + (card_rect.size.x - 460.0) * 0.5, card_rect.position.y + (card_rect.size.y - 460.0) * 0.5, 460.0, 460.0)

	var detail_face := ZodiacCardFace.new()
	detail_face.name = "DetailCardFace"
	detail_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_face.configure(selected_zodiac, sel, sel_owned, _card_textures.get(selected_zodiac), _frame_texture, _back_texture, _serif_font, true)
	pane.add_child(detail_face)
	DaylightUI.place(detail_face, card_rect.position.x, card_rect.position.y, card_rect.size.x, card_rect.size.y)
	_detail_face = detail_face

	var detail_badge_icon := SchoolObjectUI.art(detail_face, "DetailBadgeIcon", "res://assets/ui/zodiac_badges/%s.svg" % str(sel["zodiac"]), Rect2(122.0, 326.0, 104.0, 104.0))
	if sel_owned:
		detail_badge_icon.material = null
		detail_badge_icon.visible = false
	else:
		if _uncollected_shader != null:
			var mat := ShaderMaterial.new()
			mat.shader = _uncollected_shader
			detail_badge_icon.material = mat
		detail_badge_icon.modulate = Color(0.95, 0.90, 0.80, 0.88)
		detail_badge_icon.visible = true

	_detail_sparkle = TextureRect.new()
	_detail_sparkle.name = "DetailRevealSparkle"
	_detail_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_sparkle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_sparkle.visible = false
	pane.add_child(_detail_sparkle)
	DaylightUI.place(_detail_sparkle, card_rect.position.x - 36.0, card_rect.position.y + (card_rect.size.y - 420.0) * 0.5, 420.0, 420.0)

	var col_x := 418.0
	var col_w := 340.0

	var heading := _text(pane, "ZodiacName", str(sel["name"]), Rect2(col_x, 78.0, col_w, 48.0), 38, INK)
	if _serif_font != null:
		heading.add_theme_font_override("font", _serif_font)

	_text(pane, "Archetype", "%02d · %s · %s" % [int(sel["number"]), str(sel["archetype"]), str(sel["power"])], Rect2(col_x, 136.0, col_w, 28.0), 19, SAGE if sel_owned else SECONDARY)
	var motto := _text(pane, "Motto", "「%s」" % str(sel["motto"]), Rect2(col_x, 178.0, col_w, 46.0), 20, WARM_GOLD)
	motto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var top_rule := SchoolObjectUI.rule(pane, "DetailRule", Rect2(col_x, 238.0, col_w, 1.0))
	top_rule.color = Color(RULE, 0.55)

	var status_line := "收录状态：已于故事中取得（永久保留）" if sel_owned else "收录状态：尚未取得（需通过正式剧情获得）"
	var resonance_spec := PlayerJourney.zodiac_resonance_spec(selected_zodiac)
	var resonance_line := "\n\n战斗共鸣（%s）：%s" % [str(resonance_spec.get("title", "共鸣效果")), str(resonance_spec.get("summary", "暂无"))] if not resonance_spec.is_empty() else ""
	var prose_text := "%s%s\n\n能力说明：%s\n\n制约与代价：%s\n\n相互关系：%s" % [
		status_line, resonance_line, str(sel["ability"]), str(sel["limits"]), str(sel["interactions"])
	]
	var body := RichTextLabel.new()
	body.name = "ZodiacDescription"
	body.bbcode_enabled = false
	body.fit_content = false
	body.scroll_active = true
	body.clip_contents = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = prose_text
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_constant_override("line_separation", 3)
	body.add_theme_color_override("default_color", INK)
	body.custom_minimum_size = Vector2(col_w, 256.0)
	pane.add_child(body)
	DaylightUI.place(body, col_x, 252.0, col_w, 256.0)
	refs["detail"] = body

	var res_title := str(resonance_spec.get("title", "星座共鸣"))
	var res_copy := ("✦ 共鸣中：" + res_title) if is_active_res else ("激活共鸣：" + res_title if sel_owned else "尚未收录 · 无法共鸣")
	var res_btn := _pill_button(pane, "ResonateButton", res_copy, Rect2(col_x, 540.0, col_w, 46.0))
	res_btn.add_theme_font_size_override("font_size", 16)
	res_btn.clip_text = true
	res_btn.custom_minimum_size = Vector2(col_w, 46.0)
	res_btn.tooltip_text = "点击可取消当前星座共鸣" if is_active_res else "点击装备此星座战斗共鸣被动"
	res_btn.disabled = not sel_owned
	if is_active_res:
		var active_box := StyleBoxFlat.new()
		active_box.bg_color = Color(0.33, 0.45, 0.36, 0.22)
		active_box.set_border_width_all(0)
		active_box.set_corner_radius_all(6)
		res_btn.add_theme_stylebox_override("normal", active_box)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			res_btn.add_theme_color_override(key, SAGE)
	SchoolObjectUI.set_selected(res_btn, is_active_res)
	var target_zodiac := selected_zodiac
	res_btn.pressed.connect(func():
		if not is_active_res:
			AudioManager.play_sfx_zodiac()
		GameState.set_active_zodiac_id("" if is_active_res else target_zodiac)
		refresh()
	)
	refs["resonate_button"] = res_btn

	var bottom_rule := SchoolObjectUI.rule(pane, "DetailRuleBottom", Rect2(col_x, 616.0, col_w, 1.0))
	bottom_rule.color = Color(RULE, 0.55)

	var progress := SpecialCardCollection.key_progress()
	var ready_text := " · 集齐完备" if progress["ready"] else ""
	_text(pane, "KeyProgress", "其余星座 %d / 11 · 钥匙：%s%s" % [progress["other_collected"], "已收录" if progress["has_key"] else "未收录", ready_text], Rect2(col_x, 634.0, col_w, 32.0), 19, SAGE if progress["ready"] else INK)

	var track := ColorRect.new()
	track.name = "KeyProgressTrack"
	track.color = Color(RULE, 0.25)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(track)
	DaylightUI.place(track, col_x, 676.0, col_w, 3.0)

	var ratio := clampf(float(progress["other_collected"]) / 11.0, 0.0, 1.0)
	var fill := ColorRect.new()
	fill.name = "KeyProgressFill"
	fill.color = SAGE if progress["ready"] else RULE
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(fill)
	DaylightUI.place(fill, col_x, 676.0, col_w * ratio, 3.0)

func _play_reveal_effect() -> void:
	if not is_instance_valid(_detail_face):
		return
	if SaveManager.settings.get("reduced_motion", false):
		_detail_face.modulate.a = 0.0
		_reveal_tween = create_tween()
		_reveal_tween.tween_property(_detail_face, "modulate:a", 1.0, 0.16)
		return

	if is_instance_valid(_detail_seal):
		_detail_seal.visible = true
		_detail_seal.rotation_degrees = -12.0
		_detail_seal.modulate.a = 0.0
		_reveal_tween = create_tween()
		_reveal_tween.set_parallel(true)
		_reveal_tween.tween_property(_detail_seal, "rotation_degrees", -6.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_property(_detail_seal, "modulate:a", 0.82, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_property(_detail_seal, "rotation_degrees", 3.0, 0.24).set_delay(0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_reveal_tween.tween_property(_detail_seal, "modulate:a", 0.70, 0.24).set_delay(0.18)
		_reveal_tween.tween_property(_detail_seal, "rotation_degrees", 10.0, 0.28).set_delay(0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_reveal_tween.tween_property(_detail_seal, "modulate:a", 0.0, 0.28).set_delay(0.42)
		_reveal_tween.chain().tween_callback(func():
			if is_instance_valid(_detail_seal):
				_detail_seal.visible = false
		)

	if is_instance_valid(_detail_sparkle) and not _sparkle_frames.is_empty():
		var frame_count := _sparkle_frames.size()
		_detail_sparkle.texture = _sparkle_frames[0]
		_sparkle_tween = create_tween()
		_sparkle_tween.tween_interval(0.12)
		_sparkle_tween.tween_callback(func():
			if is_instance_valid(_detail_sparkle):
				_detail_sparkle.visible = true
		)
		_sparkle_tween.tween_method(_set_sparkle_frame, 0.0, float(frame_count) - 0.01, float(frame_count) / 12.0)
		_sparkle_tween.tween_callback(func():
			if is_instance_valid(_detail_sparkle):
				_detail_sparkle.visible = false
		)

func _set_sparkle_frame(step_value: float) -> void:
	if not is_instance_valid(_detail_sparkle) or _sparkle_frames.is_empty():
		return
	var idx := clampi(int(floorf(step_value)), 0, _sparkle_frames.size() - 1)
	_detail_sparkle.texture = _sparkle_frames[idx]

func _ensure_assets_loaded() -> void:
	if _uncollected_shader == null and ResourceLoader.exists("res://assets/shaders/uncollected_badge.gdshader"):
		_uncollected_shader = load("res://assets/shaders/uncollected_badge.gdshader") as Shader
	if _serif_font == null and ResourceLoader.exists(SERIF_FONT_PATH):
		_serif_font = load(SERIF_FONT_PATH) as Font
	if _frame_texture == null and ResourceLoader.exists(CARD_FRAME_PATH):
		_frame_texture = load(CARD_FRAME_PATH) as Texture2D
	if _back_texture == null and ResourceLoader.exists(CARD_BACK_PATH):
		_back_texture = load(CARD_BACK_PATH) as Texture2D
	if _seal_texture == null and ResourceLoader.exists(SEAL_CIRCLE_PATH):
		_seal_texture = load(SEAL_CIRCLE_PATH) as Texture2D
	if _card_textures.is_empty():
		for id in ZodiacCatalog.ORDER:
			var data := ZodiacCatalog.definition(id)
			var card_path := "res://assets/ui/zodiac_cards/zodiac_%02d_%s_%s.png" % [int(data["number"]), str(data["zodiac"]), id]
			if ResourceLoader.exists(card_path):
				_card_textures[id] = load(card_path) as Texture2D
	if _sparkle_frames.is_empty() and ResourceLoader.exists(SPARKLE_ATLAS_PATH):
		var sheet := load(SPARKLE_ATLAS_PATH) as Texture2D
		if sheet != null:
			for row in 2:
				for col in 4:
					var atlas := AtlasTexture.new()
					atlas.atlas = sheet
					atlas.region = Rect2(col * 512.0, row * 512.0, 512.0, 512.0)
					atlas.filter_clip = true
					_sparkle_frames.append(atlas)

func _wire_focus() -> void:
	var close := refs.get("close") as Button
	var open_records := refs.get("open_records") as Button
	var badges: Dictionary = refs.get("badges", {})
	var order := ZodiacCatalog.ORDER
	for i in order.size():
		var btn := badges.get(order[i]) as Button
		if btn == null:
			continue
		var prev_id: String = order[posmod(i - 1, order.size())]
		var next_id: String = order[(i + 1) % order.size()]
		var up_id: String = order[posmod(i - 4, order.size())]
		var down_id: String = order[(i + 4) % order.size()]
		btn.focus_neighbor_left = btn.get_path_to(badges[prev_id])
		btn.focus_neighbor_right = btn.get_path_to(badges[next_id])
		btn.focus_neighbor_top = btn.get_path_to(open_records if i < 4 else badges[up_id])
		btn.focus_neighbor_bottom = btn.get_path_to(close if i >= 8 else badges[down_id])
	if is_instance_valid(close) and is_instance_valid(open_records):
		open_records.focus_neighbor_right = open_records.get_path_to(close)
		close.focus_neighbor_left = close.get_path_to(open_records)

func _text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int, color: Color, center: bool = false) -> Label:
	var label := SchoolObjectUI.text(parent, node_name, copy, rect, font_size, color, center)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _selection_marker(parent: Control, tile_rect: Rect2) -> void:
	var pad := Vector2(4.0, 7.0)
	var rect := Rect2(tile_rect.position - pad, tile_rect.size + pad * 2.0)
	_draw_hairline_box(parent, "SelectedCardOutline", rect, RULE, 1.5)

func _draw_hairline_box(parent: Control, node_name: String, rect: Rect2, color: Color, thickness: float = 1.0) -> void:
	var holder := Control.new()
	holder.name = node_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	DaylightUI.place(holder, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	for edge in [
		Rect2(0.0, 0.0, rect.size.x, thickness),
		Rect2(0.0, rect.size.y - thickness, rect.size.x, thickness),
		Rect2(0.0, 0.0, thickness, rect.size.y),
		Rect2(rect.size.x - thickness, 0.0, thickness, rect.size.y)
	]:
		var line := ColorRect.new()
		line.color = color
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(line)
		DaylightUI.place(line, edge.position.x, edge.position.y, edge.size.x, edge.size.y)

func _tile_button(parent: Control, node_name: String, rect: Rect2, selected: bool) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 0)
		if state == "hover":
			box.bg_color = Color(RULE, 0.09)
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = Color(RULE, 0.16)
		box.set_border_width_all(0)
		box.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(button)
	DaylightUI.place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	SchoolObjectUI.set_selected(button, selected)
	return button

func _pill_button(parent: Control, node_name: String, copy: String, rect: Rect2) -> Button:
	var button := SchoolObjectUI.hit(parent, node_name, rect, copy, 20)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PILL_FILL
		if state == "hover":
			box.bg_color = PILL_HOVER
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = PILL_PRESSED
		elif state == "disabled":
			box.bg_color = Color(PILL_FILL, 0.55)
		box.set_border_width_all(0)
		box.set_corner_radius_all(6)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, INK)
	button.add_theme_color_override("font_disabled_color", SECONDARY)
	SchoolObjectUI.borderless(button)
	return button

class ZodiacCardFace extends Control:
	var _owned := false
	var _art: Texture2D
	var _frame: Texture2D
	var _back: Texture2D
	var _title := ""
	var _font: Font
	var _nameplate: Label

	func configure(_id: String, data: Dictionary, owned: bool, art_tex: Texture2D, frame_tex: Texture2D, back_tex: Texture2D, serif_font: Font, show_nameplate: bool = true) -> void:
		_owned = owned
		_art = art_tex
		_frame = frame_tex
		_back = back_tex
		_title = str(data.get("name", ""))
		_font = serif_font
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		if _nameplate != null:
			_nameplate.queue_free()
			_nameplate = null
		if _owned and show_nameplate and _title != "":
			_nameplate = Label.new()
			_nameplate.name = "CardNameplate"
			_nameplate.text = _title
			_nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_nameplate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_nameplate.add_theme_color_override("font_color", INK)
			if _font != null:
				_nameplate.add_theme_font_override("font", _font)
			add_child(_nameplate)
			_layout_nameplate()
		if not resized.is_connected(_layout_nameplate):
			resized.connect(_layout_nameplate)
		queue_redraw()

	func _layout_nameplate() -> void:
		if not is_instance_valid(_nameplate):
			return
		var k := size / CARD_CANVAS
		if k.x <= 0.0 or k.y <= 0.0:
			return
		_nameplate.position = NAMEPLATE_RECT.position * k
		_nameplate.size = NAMEPLATE_RECT.size * k
		_nameplate.add_theme_font_size_override("font_size", clampi(roundi(48.0 * k.y), 11, 32))

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		if _owned and _art != null and _frame != null:
			var k := size / CARD_CANVAS
			var tex_w := float(_art.get_width())
			var tex_h := float(_art.get_height())
			if tex_w > 0.0 and tex_h > 0.0:
				var cover_scale := maxf(ART_COVER_RECT.size.x / tex_w, ART_COVER_RECT.size.y / tex_h)
				var drawn_size := Vector2(tex_w, tex_h) * cover_scale
				# Top-centered aspect-cover crop per art_cover_alignment [0.5, 0].
				var art_origin := Vector2(ART_COVER_RECT.position.x + (ART_COVER_RECT.size.x - drawn_size.x) * 0.5, ART_COVER_RECT.position.y)
				var pts := PackedVector2Array()
				var uvs := PackedVector2Array()
				for p in CLIP_POLYGON_POINTS:
					pts.append(p * k)
					uvs.append(Vector2((p.x - art_origin.x) / drawn_size.x, (p.y - art_origin.y) / drawn_size.y))
				draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, _art)
			draw_texture_rect(_frame, Rect2(Vector2.ZERO, size), false)
		elif _back != null:
			draw_texture_rect(_back, Rect2(Vector2.ZERO, size), false)
