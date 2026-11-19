class_name ZodiacAlbumPanel
extends Control

## Museum-ivory 12-zodiac binder (overview wall + antique open-book Left-Card / Right-Info detail spread).
signal close_requested
signal action_requested(action: String, payload: Dictionary)

const DESIGN := Vector2(1920.0, 1080.0)
const PAPER := Color("#FAF6ED")
const WALNUT_BACKDROP := Color("#1E1814")
const BOOK_PAPER := Color("#FAF6EC")
const PILL_FILL := Color("#EFE7D8")
const PILL_HOVER := Color("#E5DBC7")
const PILL_PRESSED := Color("#DBD0B9")
const INK := Color("#231D18")
const SECONDARY := Color("#544A40")
const RULE := Color("#B9975B")
const BRONZE := Color("#9E7B52")
const SAGE := Color("#54745D")
const ROSE := Color("#B85D66")
const WARM_GOLD := Color("#8C6A36")

const CARD_FRAME_PATH := "res://assets/ui/zodiac_cards/zodiac_card_frame.png"
const CARD_BACK_PATH := "res://assets/ui/zodiac_cards/zodiac_card_back.png"
const SEAL_CIRCLE_PATH := "res://assets/ui/zodiac_cards/anim_zodiac_seal_circle.svg"
const SPARKLE_ATLAS_PATH := "res://assets/ui/zodiac_cards/anim_cel_reveal_sparkle_4x2.png"
const RESONANCE_HALO_PATH := "res://assets/ui_core/animations/ui_zodiac_resonance_halo.png"
const BOOK_SPREAD_PATH := "res://assets/ui_core/v14_ui/zodiac/ui_zodiac_book_spread.png"
const RIBBON_SAGE_PATH := "res://assets/ui_core/v14_ui/zodiac/ui_zodiac_ribbon_sage.png"
const RIBBON_ROSE_PATH := "res://assets/ui_core/v14_ui/zodiac/ui_zodiac_ribbon_rose.png"
const SERIF_FONT_PATH := "res://assets/fonts/NotoSerifSC-SemiBold.ttf"

const ROMAN_NUMERALS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

const CARD_CANVAS := Vector2(640.0, 960.0)
const ART_COVER_RECT := Rect2(35.0, 34.0, 570.0, 823.0)
const NAMEPLATE_RECT := Rect2(56.0, 870.0, 528.0, 48.0)
const CLIP_POLYGON_POINTS := [
	Vector2(86.0, 40.0), Vector2(554.0, 40.0), Vector2(570.0, 61.0), Vector2(604.0, 79.0),
	Vector2(604.0, 812.0), Vector2(568.0, 832.0), Vector2(551.0, 853.0), Vector2(89.0, 853.0),
	Vector2(70.0, 833.0), Vector2(36.0, 812.0), Vector2(36.0, 79.0), Vector2(67.0, 62.0)
]

var context: Dictionary = {}
var refs: Dictionary = {}
var selected_zodiac := "hero"
var view_mode := "overview"
var _uncollected_shader: Shader
var _card_textures: Dictionary = {}
var _frame_texture: Texture2D
var _back_texture: Texture2D
var _seal_texture: Texture2D
var _book_spread_texture: Texture2D
var _ribbon_sage_texture: Texture2D
var _ribbon_rose_texture: Texture2D
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


func _exit_tree() -> void:
	if Platform.input_mode_changed.is_connected(_on_input_mode_changed):
		Platform.input_mode_changed.disconnect(_on_input_mode_changed)
	if is_instance_valid(_reveal_tween):
		_reveal_tween.kill()
	if is_instance_valid(_sparkle_tween):
		_sparkle_tween.kill()


func _process(delta: float) -> void:
	if is_instance_valid(_resonance_halo) and _resonance_halo.visible and not bool(SaveManager.settings.get("reduced_motion", false)):
		_resonance_halo.rotation += delta * 0.25


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or view_mode != "book_detail":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_LEFT:
			_turn_page(-1)
			get_viewport().set_input_as_handled()
		elif kev.keycode == KEY_RIGHT:
			_turn_page(1)
			get_viewport().set_input_as_handled()


func cancel_pending() -> bool:
	if view_mode == "book_detail":
		view_mode = "overview"
		refresh()
		var btn := refs.get("badges", {}).get(selected_zodiac) as Button
		if is_instance_valid(btn):
			_focus_control_safe.bind(btn).call_deferred()
		return true
	return false


func _focus_control_safe(ctrl: Control) -> void:
	if is_instance_valid(ctrl) and ctrl.is_inside_tree() and ctrl.is_visible_in_tree():
		ctrl.grab_focus()


func _on_input_mode_changed(_touch: bool) -> void:
	var hint_node := find_child("CloseHint", true, false) as Label
	if is_instance_valid(hint_node):
		if view_mode == "book_detail":
			hint_node.text = Platform.hint("Esc 返回总览 · ← / → 翻页 · 永久剧情收藏，不参与商店交易", "点击顶部页签或左右按钮翻页 · Esc 返回")
		else:
			hint_node.text = Platform.hint("Esc 返回 · 方向键浏览 · Enter 翻开典籍详情", "点击星卡翻开典籍详情")


func refresh(panel_context: Dictionary = {}) -> void:
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	if _sparkle_tween and _sparkle_tween.is_valid():
		_sparkle_tween.kill()
	if not panel_context.is_empty():
		context.merge(panel_context, true)
	if context.has("selected_zodiac") and ZodiacCatalog.known(str(context["selected_zodiac"])):
		selected_zodiac = str(context["selected_zodiac"])
	var req_mode := str(panel_context.get("view_mode", ""))
	if req_mode in ["overview", "book_detail"]:
		view_mode = req_mode

	var play_reveal_for := str(panel_context.get("play_reveal", ""))
	if not _owned_cache.is_empty():
		for id in ZodiacCatalog.ORDER:
			var now_owned := SpecialCardCollection.collected(id)
			if now_owned and not bool(_owned_cache.get(id, false)):
				selected_zodiac = id
				play_reveal_for = id
				break
	if play_reveal_for != "":
		view_mode = "book_detail"

	_ensure_assets_loaded()
	_resonance_halo = null
	_detail_seal = null
	_detail_sparkle = null
	_detail_face = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	theme = DaylightUI.get_theme()
	size = DESIGN

	if view_mode == "book_detail":
		_build_book_detail(play_reveal_for)
	else:
		_build_overview()


func _build_overview() -> void:
	var bleed := ColorRect.new()
	bleed.name = "FullBleedPaper"
	bleed.color = PAPER
	bleed.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bleed)
	DaylightUI.place(bleed, -600, -300, 3120, 1680)

	var snapshot: Dictionary = SpecialCardCollection.snapshot()
	var owned_count: int = snapshot["collected"].size()

	var title := _text(self, "Title", "十二星座图鉴", Rect2(80, 42, 340, 56), 40, INK)
	if _serif_font != null:
		title.add_theme_font_override("font", _serif_font)
	_text(self, "Subtitle", "永久剧情收藏 · 已收录 %d / 12 · 点击星卡翻开典籍详情" % owned_count, Rect2(390, 52, 680, 38), 21, SECONDARY)

	var open_detail := _pill_button(self, "OpenDetailBook", "翻开典籍详情 →", Rect2(1248, 46, 236, 44), true)
	open_detail.pressed.connect(func():
		view_mode = "book_detail"
		refresh({"play_reveal": selected_zodiac if SpecialCardCollection.collected(selected_zodiac) else ""})
	)
	refs["open_detail"] = open_detail

	var records_btn := _pill_button(self, "OpenRecords", "放映档案", Rect2(1506, 46, 176, 44))
	records_btn.pressed.connect(func(): action_requested.emit("open_records", {}))
	refs["open_records"] = records_btn

	var close := _pill_button(self, "CloseButton", "返回 ×", Rect2(1704, 46, 136, 44))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close

	var header_rule := SchoolObjectUI.rule(self, "HeaderRule", Rect2(80, 110, 1760, 1))
	header_rule.color = Color(RULE, 0.55)

	var badges := {}
	var order := ZodiacCatalog.ORDER
	var active_res := GameState.get_active_zodiac_id()
	for index in order.size():
		var id: String = order[index]
		var data: Dictionary = ZodiacCatalog.definition(id)
		var owned := SpecialCardCollection.collected(id)
		_owned_cache[id] = owned
		var is_sel := id == selected_zodiac
		var is_res := id == active_res
		var col := index % 6
		var row := index / 6
		var tile_rect := Rect2(104.0 + col * 290.0, 146.0 + row * 412.0, 230.0, 345.0)

		if is_sel:
			_selection_marker(self, tile_rect)

		var tile := _tile_button(self, "Badge_" + id, tile_rect, is_sel)
		var face := ZodiacCardFace.new()
		face.name = "CardFace"
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.configure(id, data, owned, _card_textures.get(id), _frame_texture, _back_texture, _serif_font, true)
		tile.add_child(face)
		DaylightUI.place(face, 0, 0, tile_rect.size.x, tile_rect.size.y)

		var badge_path := "res://assets/ui/zodiac_badges/%s.svg" % str(data["zodiac"])
		var icon := SchoolObjectUI.art(tile, "BadgeIcon", badge_path, Rect2(82.0, 210.0, 66.0, 66.0))
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

		if is_res:
			var res_tag := _text(self, "ResTag_" + id, "✦ 共鸣中", Rect2(tile_rect.position.x + 12.0, tile_rect.position.y - 26.0, tile_rect.size.x - 24.0, 22.0), 15, SAGE, true)
			res_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var caption_color := INK if owned else SECONDARY
		var caption := _text(self, "Caption_" + id, "%02d · %s" % [int(data["number"]), str(data["name"])], Rect2(tile_rect.position.x - 10.0, tile_rect.position.y + tile_rect.size.y + 8.0, tile_rect.size.x + 20.0, 28.0), 19, caption_color, true)
		if _serif_font != null and owned:
			caption.add_theme_font_override("font", _serif_font)

		tile.pressed.connect(_select_badge.bind(id))
		badges[id] = tile
	refs["badges"] = badges

	var footer_rule := SchoolObjectUI.rule(self, "FooterRule", Rect2(80, 992, 1760, 1))
	footer_rule.color = Color(RULE, 0.55)

	_text(self, "PermanentStory", "剧情收藏永久保留 · 不加入普通卡组，不参与商店交易", Rect2(80, 1014, 900, 30), 19, SECONDARY)
	var hint_label := _text(self, "CloseHint", Platform.hint("Esc 返回 · 方向键浏览 · Enter 翻开典籍详情", "点击星卡翻开典籍详情"), Rect2(1260, 1014, 580, 30), 19, SECONDARY)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_wire_focus()


func _build_book_detail(play_reveal_for: String) -> void:
	for id in ZodiacCatalog.ORDER:
		_owned_cache[id] = SpecialCardCollection.collected(id)

	var bleed := ColorRect.new()
	bleed.name = "FullBleedPaper"
	bleed.color = WALNUT_BACKDROP
	bleed.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bleed)
	DaylightUI.place(bleed, -600, -300, 3120, 1680)

	# Top bar over leather desk backdrop
	var back_overview := _pill_button(self, "BackToOverview", "← 返回十二星座总览", Rect2(80.0, 18.0, 240.0, 42.0))
	back_overview.pressed.connect(func():
		view_mode = "overview"
		refresh()
	)
	refs["back_overview"] = back_overview

	# 12 Roman-numeral quick bookmarks (use child Label so "X" is never mistaken for a close button)
	var book_tabs := {}
	for i in ZodiacCatalog.ORDER.size():
		var z_id: String = ZodiacCatalog.ORDER[i]
		var z_owned := SpecialCardCollection.collected(z_id)
		var is_cur := z_id == selected_zodiac
		var roman: String = ROMAN_NUMERALS[i] if i < ROMAN_NUMERALS.size() else str(i + 1)
		var tab := Button.new()
		tab.name = "BookTab_" + z_id
		tab.text = ""
		tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var z_data: Dictionary = ZodiacCatalog.definition(z_id)
		tab.tooltip_text = "%02d · %s" % [int(z_data.get("number", i + 1)), str(z_data.get("name", z_id))]
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb := StyleBoxFlat.new()
			if is_cur:
				sb.bg_color = Color("#FAF6EC")
			elif z_owned:
				sb.bg_color = Color(0.95, 0.90, 0.80, 0.20 if st == "normal" else 0.34)
			else:
				sb.bg_color = Color(1.0, 1.0, 1.0, 0.11 if st == "normal" else 0.20)
			sb.set_border_width_all(0)
			sb.set_corner_radius_all(8)
			tab.add_theme_stylebox_override(st, sb)
		SchoolObjectUI.borderless(tab)
		add_child(tab)
		DaylightUI.place(tab, 344.0 + float(i) * 95.0, 19.0, 86.0, 40.0)
		var txt_col := INK if is_cur else (Color("#EFE5D2") if z_owned else Color("#B5AA9B"))
		var tab_lbl := _text(tab, "RomanText", roman, Rect2(0.0, 0.0, 86.0, 40.0), 17, txt_col, true)
		if _serif_font != null:
			tab_lbl.add_theme_font_override("font", _serif_font)
		tab.pressed.connect(_select_badge.bind(z_id))
		book_tabs[z_id] = tab
	refs["book_tabs"] = book_tabs

	var records_btn := _pill_button(self, "OpenRecords", "放映档案", Rect2(1506, 18, 176, 42))
	records_btn.pressed.connect(func(): action_requested.emit("open_records", {}))
	refs["open_records"] = records_btn

	var close := _pill_button(self, "CloseButton", "返回 ×", Rect2(1704, 18, 136, 42))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close

	# Centered Antique Open-Book Spread
	var book := Control.new()
	book.name = "BookSpread"
	book.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(book)
	DaylightUI.place(book, 170.0, 74.0, 1580.0, 936.0)

	if _book_spread_texture != null:
		var spread_art := TextureRect.new()
		spread_art.name = "BookSpreadArtwork"
		spread_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spread_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spread_art.stretch_mode = TextureRect.STRETCH_SCALE
		spread_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spread_art.texture = _book_spread_texture
		book.add_child(spread_art)
		DaylightUI.place(spread_art, 0.0, 0.0, 1580.0, 936.0)
	else:
		var book_canvas := _ZodiacBookCanvas.new()
		book_canvas.name = "ZodiacBookCanvas"
		book_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		book.add_child(book_canvas)
		DaylightUI.place(book_canvas, 0.0, 0.0, 1580.0, 936.0)

	var sel: Dictionary = ZodiacCatalog.definition(selected_zodiac)
	var sel_owned := SpecialCardCollection.collected(selected_zodiac)
	var is_active_res := GameState.get_active_zodiac_id() == selected_zodiac
	var idx := maxi(0, ZodiacCatalog.ORDER.find(selected_zodiac))
	var roman_str: String = ROMAN_NUMERALS[idx] if idx < ROMAN_NUMERALS.size() else str(idx + 1)

	# ==================== LEFT PAGE: Large Tarot Card Showcase ====================
	var left_hdr := _text(book, "LeftArchetypeHeader", "NO.%02d · %s原型" % [int(sel["number"]), str(sel["archetype"])], Rect2(198.0, 62.0, 414.0, 34.0), 19, INK, true)
	if _serif_font != null:
		left_hdr.add_theme_font_override("font", _serif_font)

	var use_spread_art := _book_spread_texture != null
	var niche_rect := Rect2(193.0, 120.0, 424.0, 640.0) if use_spread_art else Rect2(188.0, 114.0, 434.0, 651.0)
	var card_w := 412.0 if use_spread_art else 422.0
	var card_h := 618.0 if use_spread_art else 633.0
	var card_pos := Vector2(6.0, 11.0) if use_spread_art else Vector2(6.0, 9.0)

	var niche := Panel.new()
	niche.name = "CardNiche"
	niche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if use_spread_art:
		niche.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		var niche_sb := StyleBoxFlat.new()
		niche_sb.bg_color = Color("#1F1A17")
		niche_sb.border_color = Color("#4A3B31")
		niche_sb.set_border_width_all(3)
		niche_sb.shadow_color = Color(0.08, 0.06, 0.04, 0.26)
		niche_sb.shadow_size = 10
		niche.add_theme_stylebox_override("panel", niche_sb)
	book.add_child(niche)
	DaylightUI.place(niche, niche_rect.position.x, niche_rect.position.y, niche_rect.size.x, niche_rect.size.y)

	if use_spread_art:
		var card_shadow := Panel.new()
		card_shadow.name = "CardDropShadow"
		card_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh_sb := StyleBoxFlat.new()
		sh_sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		sh_sb.shadow_color = Color(0.18, 0.13, 0.08, 0.28)
		sh_sb.shadow_size = 8
		sh_sb.shadow_offset = Vector2(2.0, 4.0)
		card_shadow.add_theme_stylebox_override("panel", sh_sb)
		niche.add_child(card_shadow)
		DaylightUI.place(card_shadow, card_pos.x, card_pos.y, card_w, card_h)

	if is_active_res and ResourceLoader.exists(RESONANCE_HALO_PATH):
		var halo_dim := 500.0 if use_spread_art else 520.0
		_resonance_halo = TextureRect.new()
		_resonance_halo.name = "DetailResonanceHalo"
		_resonance_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_resonance_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_resonance_halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_resonance_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_resonance_halo.texture = load(RESONANCE_HALO_PATH) as Texture2D
		_resonance_halo.modulate = Color(1.0, 1.0, 1.0, 0.88)
		_resonance_halo.pivot_offset = Vector2(halo_dim * 0.5, halo_dim * 0.5)
		niche.add_child(_resonance_halo)
		DaylightUI.place(_resonance_halo, (niche_rect.size.x - halo_dim) * 0.5, (niche_rect.size.y - halo_dim) * 0.5, halo_dim, halo_dim)

	var seal_dim := 480.0 if use_spread_art else 500.0
	_detail_seal = TextureRect.new()
	_detail_seal.name = "DetailRevealSeal"
	_detail_seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_seal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_seal.texture = _seal_texture
	_detail_seal.modulate.a = 0.0
	_detail_seal.visible = false
	_detail_seal.pivot_offset = Vector2(seal_dim * 0.5, seal_dim * 0.5)
	niche.add_child(_detail_seal)
	DaylightUI.place(_detail_seal, (niche_rect.size.x - seal_dim) * 0.5, (niche_rect.size.y - seal_dim) * 0.5, seal_dim, seal_dim)

	var detail_face := ZodiacCardFace.new()
	detail_face.name = "DetailCardFace"
	detail_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_face.configure(selected_zodiac, sel, sel_owned, _card_textures.get(selected_zodiac), _frame_texture, _back_texture, _serif_font, true)
	niche.add_child(detail_face)
	DaylightUI.place(detail_face, card_pos.x, card_pos.y, card_w, card_h)
	_detail_face = detail_face

	var badge_rect := Rect2(142.0, 386.0, 128.0, 128.0) if use_spread_art else Rect2(146.0, 396.0, 130.0, 130.0)
	var detail_badge_icon := SchoolObjectUI.art(detail_face, "DetailBadgeIcon", "res://assets/ui/zodiac_badges/%s.svg" % str(sel["zodiac"]), badge_rect)
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

	var spark_dim := 460.0 if use_spread_art else 480.0
	_detail_sparkle = TextureRect.new()
	_detail_sparkle.name = "DetailRevealSparkle"
	_detail_sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_sparkle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_sparkle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_sparkle.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_sparkle.visible = false
	niche.add_child(_detail_sparkle)
	DaylightUI.place(_detail_sparkle, (niche_rect.size.x - spark_dim) * 0.5, (niche_rect.size.y - spark_dim) * 0.5, spark_dim, spark_dim)

	var left_ftr := _text(book, "LeftCardCaption", "%s · %s" % [str(sel["name"]), str(sel["power"])], Rect2(174.0, 782.0, 462.0, 38.0), 23, INK, true)
	if _serif_font != null:
		left_ftr.add_theme_font_override("font", _serif_font)
	var left_motto := _text(book, "Motto", "「%s」" % str(sel["motto"]), Rect2(140.0, 822.0, 530.0, 30.0), 17, WARM_GOLD, true)
	left_motto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# ==================== RIGHT PAGE: Editorial Structured Introduction ====================
	var eng_tag := "%s · %s" % [roman_str, str(sel["zodiac"]).to_upper()]
	var latin_lbl := _text(book, "ZodiacLatin", eng_tag, Rect2(884.0, 40.0, 360.0, 36.0), 23, BRONZE)
	if _serif_font != null:
		latin_lbl.add_theme_font_override("font", _serif_font)

	var status_pill := SchoolObjectUI.slab(book, "StatusTag", Rect2(1270.0, 44.0, 210.0, 30.0), Color(SAGE, 0.14) if sel_owned else Color(SECONDARY, 0.10))
	var st_sb := status_pill.get_theme_stylebox("panel") as StyleBoxFlat
	st_sb.set_corner_radius_all(12)
	st_sb.border_color = Color(SAGE if sel_owned else SECONDARY, 0.45)
	st_sb.set_border_width_all(1)
	var st_txt := _text(status_pill, "StatusText", "已收录 · 永久收藏" if sel_owned else "故事中待收录", Rect2(0.0, 0.0, 210.0, 30.0), 15, SAGE if sel_owned else SECONDARY, true)
	st_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var heading := _text(book, "ZodiacName", "%s · %s" % [str(sel["name"]), str(sel["archetype"])], Rect2(884.0, 96.0, 390.0, 46.0), 34, INK)
	if _serif_font != null:
		heading.add_theme_font_override("font", _serif_font)
	var power_lbl := _text(book, "Archetype", "核心权能：%s" % str(sel["power"]), Rect2(1258.0, 106.0, 222.0, 32.0), 19, WARM_GOLD)
	power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Section 1: Battle Resonance (Rose Ribbon)
	var resonance_spec: Dictionary = PlayerJourney.zodiac_resonance_spec(selected_zodiac)
	_build_ribbon_tag(book, "ResonanceRibbon", "战斗共鸣", Rect2(884.0, 162.0, 196.0, 36.0), true)
	var res_title := str(resonance_spec.get("title", "母卡共鸣效果"))
	var res_summary := str(resonance_spec.get("summary", "该星座对应章回与共鸣效果将随正式剧情开放。"))
	var res_body := _text(book, "ZodiacResonanceDesc", "%s —— %s" % [res_title, res_summary], Rect2(884.0, 206.0, 594.0, 50.0), 18, INK)
	res_body.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	res_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	DaylightUI.place(res_body, 884.0, 206.0, 594.0, 50.0)

	var res_copy := ("✦ 共鸣中：" + res_title) if is_active_res else ("激活共鸣：" + res_title if sel_owned else "尚未收录 · 无法激活共鸣")
	var res_btn := Button.new()
	res_btn.name = "ResonateButton"
	res_btn.text = res_copy
	res_btn.disabled = not sel_owned
	res_btn.tooltip_text = "点击可取消当前星座共鸣" if is_active_res else "点击装备此星座战斗共鸣被动"
	book.add_child(res_btn)
	DaylightUI.place(res_btn, 884.0, 264.0, 360.0, 46.0)
	if is_active_res:
		DynamicUI.make_cel_button(res_btn, Color("#359686"), Color("#FFFDF8"), Color("#359686"), 18, 12)
	elif sel_owned:
		DynamicUI.make_cel_button(res_btn, Color("#D45B49"), Color("#FFFDF8"), Color("#D45B49"), 18, 12)
	else:
		DynamicUI.make_cel_button(res_btn, Color("#DFD9CE"), Color("#7E766C"), Color("#B9975B"), 18, 12)
	DaylightUI.bind_button_audio(res_btn)
	var target_zodiac := selected_zodiac
	res_btn.pressed.connect(func():
		if not is_active_res:
			AudioManager.play_sfx_zodiac()
		GameState.set_active_zodiac_id("" if is_active_res else target_zodiac)
		refresh()
	)
	refs["resonate_button"] = res_btn

	# Section 2: Ability (Sage Ribbon)
	_build_ribbon_tag(book, "AbilityRibbon", "能力说明", Rect2(884.0, 330.0, 196.0, 36.0), false)
	var abl_lbl := _text(book, "ZodiacAbility", str(sel["ability"]), Rect2(884.0, 376.0, 594.0, 76.0), 19, INK)
	abl_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	abl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	DaylightUI.place(abl_lbl, 884.0, 376.0, 594.0, 76.0)
	refs["detail"] = abl_lbl

	# Section 3: Limits (Sage Ribbon)
	_build_ribbon_tag(book, "LimitsRibbon", "制约与代价", Rect2(884.0, 466.0, 196.0, 36.0), false)
	var lim_lbl := _text(book, "ZodiacLimits", str(sel["limits"]), Rect2(884.0, 512.0, 594.0, 76.0), 19, INK)
	lim_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	lim_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	DaylightUI.place(lim_lbl, 884.0, 512.0, 594.0, 76.0)

	# Section 4: Interactions (Sage Ribbon)
	_build_ribbon_tag(book, "InteractionsRibbon", "相互关系", Rect2(884.0, 602.0, 196.0, 36.0), false)
	var int_lbl := _text(book, "ZodiacInteractions", str(sel["interactions"]), Rect2(884.0, 648.0, 594.0, 82.0), 19, INK)
	int_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	int_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	DaylightUI.place(int_lbl, 884.0, 648.0, 594.0, 82.0)

	# Footer progress & page flip controls inside Right Page
	var bottom_rule := SchoolObjectUI.rule(book, "DetailRuleBottom", Rect2(884.0, 756.0, 594.0, 1.5))
	bottom_rule.color = Color(BRONZE, 0.50)

	var progress: Dictionary = SpecialCardCollection.key_progress()
	var ready_text := " · 集齐完备" if bool(progress["ready"]) else ""
	_text(book, "KeyProgress", "其余星座 %d / 11 · 最终钥匙：%s%s" % [int(progress["other_collected"]), "已收录" if bool(progress["has_key"]) else "未收录", ready_text], Rect2(884.0, 770.0, 594.0, 30.0), 18, SAGE if bool(progress["ready"]) else INK)

	var track := ColorRect.new()
	track.name = "KeyProgressTrack"
	track.color = Color(BRONZE, 0.25)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.add_child(track)
	DaylightUI.place(track, 884.0, 806.0, 594.0, 4.0)

	var ratio := clampf(float(progress["other_collected"]) / 11.0, 0.0, 1.0)
	var fill := ColorRect.new()
	fill.name = "KeyProgressFill"
	fill.color = SAGE if bool(progress["ready"]) else BRONZE
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	book.add_child(fill)
	DaylightUI.place(fill, 884.0, 806.0, 594.0 * ratio, 4.0)

	var prev_btn := _pill_button(book, "PrevZodiacBtn", "‹ 上一张", Rect2(884.0, 830.0, 156.0, 42.0))
	prev_btn.pressed.connect(_turn_page.bind(-1))
	refs["prev_page"] = prev_btn

	var page_lbl := _text(book, "PageCounter", "%02d / 12" % (idx + 1), Rect2(1078.0, 832.0, 206.0, 38.0), 20, BRONZE, true)
	if _serif_font != null:
		page_lbl.add_theme_font_override("font", _serif_font)

	var next_btn := _pill_button(book, "NextZodiacBtn", "下一张 ›", Rect2(1322.0, 830.0, 156.0, 42.0))
	next_btn.pressed.connect(_turn_page.bind(1))
	refs["next_page"] = next_btn

	# Subtle bottom desk hint
	var hint_label := _text(self, "CloseHint", Platform.hint("Esc 返回总览 · ← / → 翻页 · 剧情收藏永久保留，不参与商店交易", "点击页签或左右按钮翻页 · 剧情收藏永久保留，不参与商店交易"), Rect2(170.0, 1022.0, 1580.0, 32.0), 19, Color("#C6BBA8"), true)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if play_reveal_for != "" and play_reveal_for == selected_zodiac and SpecialCardCollection.collected(selected_zodiac):
		_play_reveal_effect()


func _build_ribbon_tag(parent: Control, node_name: String, copy: String, rect: Rect2, is_rose: bool) -> void:
	var holder := Control.new()
	holder.name = node_name
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	DaylightUI.place(holder, rect.position.x, rect.position.y, rect.size.x, rect.size.y)

	var tex := _ribbon_rose_texture if is_rose else _ribbon_sage_texture
	if tex != null:
		var art := TextureRect.new()
		art.name = "RibbonTexture"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.texture = tex
		holder.add_child(art)
		DaylightUI.place(art, 0.0, 0.0, rect.size.x, rect.size.y)
	else:
		var rib := _RibbonHeaderCanvas.new()
		rib.name = "RibbonCanvas"
		rib.is_rose = is_rose
		holder.add_child(rib)
		DaylightUI.place(rib, 0.0, 0.0, rect.size.x, rect.size.y)

	var lbl := _text(holder, "RibbonLabel", copy, Rect2(14.0, 0.0, rect.size.x - 24.0, rect.size.y), 18, Color("#7D353C") if is_rose else Color("#4C5F3B"))
	if _serif_font != null:
		lbl.add_theme_font_override("font", _serif_font)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _turn_page(step: int) -> void:
	var cur := ZodiacCatalog.ORDER.find(selected_zodiac)
	if cur < 0:
		cur = 0
	var next_idx := posmod(cur + step, ZodiacCatalog.ORDER.size())
	var next_id: String = ZodiacCatalog.ORDER[next_idx]
	_select_badge(next_id)


func _select_badge(id: String) -> void:
	selected_zodiac = id
	view_mode = "book_detail"
	var should_reveal := SpecialCardCollection.collected(id)
	refresh({"play_reveal": id if should_reveal else "", "view_mode": "book_detail"})


func _play_reveal_effect() -> void:
	if not is_instance_valid(_detail_face):
		return
	if bool(SaveManager.settings.get("reduced_motion", false)):
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
	if _book_spread_texture == null and ResourceLoader.exists(BOOK_SPREAD_PATH):
		_book_spread_texture = load(BOOK_SPREAD_PATH) as Texture2D
	if _ribbon_sage_texture == null and ResourceLoader.exists(RIBBON_SAGE_PATH):
		_ribbon_sage_texture = load(RIBBON_SAGE_PATH) as Texture2D
	if _ribbon_rose_texture == null and ResourceLoader.exists(RIBBON_ROSE_PATH):
		_ribbon_rose_texture = load(RIBBON_ROSE_PATH) as Texture2D
	if _card_textures.is_empty():
		for id in ZodiacCatalog.ORDER:
			var data: Dictionary = ZodiacCatalog.definition(id)
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
		var up_id: String = order[posmod(i - 6, order.size())]
		var down_id: String = order[(i + 6) % order.size()]
		btn.focus_neighbor_left = btn.get_path_to(badges[prev_id])
		btn.focus_neighbor_right = btn.get_path_to(badges[next_id])
		btn.focus_neighbor_top = btn.get_path_to(open_records if i < 6 else badges[up_id])
		btn.focus_neighbor_bottom = btn.get_path_to(close if i >= 6 else badges[down_id])
	if is_instance_valid(close) and is_instance_valid(open_records):
		open_records.focus_neighbor_right = open_records.get_path_to(close)
		close.focus_neighbor_left = close.get_path_to(open_records)


func _text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int, color: Color, center: bool = false) -> Label:
	var label := SchoolObjectUI.text(parent, node_name, copy, rect, font_size, color, center)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _selection_marker(parent: Control, tile_rect: Rect2) -> void:
	var pad := Vector2(6.0, 6.0)
	var rect := Rect2(tile_rect.position - pad, tile_rect.size + pad * 2.0)
	_draw_hairline_box(parent, "SelectedCardOutline", rect, RULE, 2.0)


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


func _pill_button(parent: Control, node_name: String, copy: String, rect: Rect2, accent: bool = false) -> Button:
	var button := SchoolObjectUI.hit(parent, node_name, rect, copy, 19)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		if accent:
			box.bg_color = Color("#359686")
			if state == "hover":
				box.bg_color = Color("#2C8072")
			elif state in ["pressed", "hover_pressed"]:
				box.bg_color = Color("#246C60")
		else:
			box.bg_color = PILL_FILL
			if state == "hover":
				box.bg_color = PILL_HOVER
			elif state in ["pressed", "hover_pressed"]:
				box.bg_color = PILL_PRESSED
			elif state == "disabled":
				box.bg_color = Color(PILL_FILL, 0.55)
		box.set_border_width_all(0)
		box.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var fcol := Color("#FFFDF8") if accent else INK
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, fcol)
	button.add_theme_color_override("font_disabled_color", SECONDARY)
	SchoolObjectUI.borderless(button)
	return button


class _ZodiacBookCanvas:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var mid := w * 0.5

		# Drop shadow + espresso leather book cover
		draw_rect(Rect2(6.0, 10.0, w, h), Color(0.0, 0.0, 0.0, 0.34), true)
		_draw_rounded_box(Rect2(0.0, 0.0, w, h), 14.0, Color("#3B291F"), Color("#634937"), 2.0)

		# Page thickness stacks (outer 3 stepped ivory sheets on left & right)
		draw_rect(Rect2(14.0, 14.0, w - 28.0, h - 28.0), Color("#D2C6B0"), true)
		draw_rect(Rect2(22.0, 16.0, w - 44.0, h - 32.0), Color("#E3D8C4"), true)
		draw_rect(Rect2(30.0, 18.0, w - 60.0, h - 36.0), Color("#EFE7D6"), true)

		# Main warm cream left & right spreads
		draw_rect(Rect2(38.0, 18.0, w - 76.0, h - 36.0), Color("#FAF6EC"), true)

		# Subtle spine gutter shadow down the center
		for step in 16:
			var dist := float(step) * 3.0
			var a := (1.0 - float(step) / 16.0) * 0.14
			draw_line(Vector2(mid - dist, 18.0), Vector2(mid - dist, h - 18.0), Color(0.24, 0.17, 0.12, a), 3.0)
			draw_line(Vector2(mid + dist, 18.0), Vector2(mid + dist, h - 18.0), Color(0.24, 0.17, 0.12, a * 0.8), 3.0)
		draw_line(Vector2(mid, 18.0), Vector2(mid, h - 18.0), Color(0.32, 0.24, 0.18, 0.45), 1.5)

		# Left page: margin diamond rail (x=48..70)
		draw_line(Vector2(70.0, 26.0), Vector2(70.0, h - 26.0), Color("#46392F", 0.55), 1.5)
		draw_line(Vector2(50.0, 26.0), Vector2(50.0, h - 26.0), Color("#46392F", 0.25), 1.0)
		for yi in 10:
			var dy := 76.0 + float(yi) * 86.0
			_draw_diamond(Vector2(60.0, dy), 5.0, Color("#B9975B", 0.55), true)

		# Left page: antique dotted frame & floral/gold corner medallions
		var lp := Rect2(86.0, 40.0, 638.0, h - 80.0)
		draw_rect(lp, Color("#46392F", 0.72), false, 1.5)
		draw_rect(Rect2(lp.position.x + 8.0, lp.position.y + 8.0, lp.size.x - 16.0, lp.size.y - 16.0), Color("#B9975B", 0.48), false, 1.0)
		_draw_filigree_corner(Vector2(lp.position.x, lp.position.y), Vector2(1.0, 1.0))
		_draw_filigree_corner(Vector2(lp.end.x, lp.position.y), Vector2(-1.0, 1.0))
		_draw_filigree_corner(Vector2(lp.position.x, lp.end.y), Vector2(1.0, -1.0))
		_draw_filigree_corner(Vector2(lp.end.x, lp.end.y), Vector2(-1.0, -1.0))

		# Left page top & bottom horizontal rules flanking labels
		draw_line(Vector2(118.0, 79.0), Vector2(210.0, 79.0), Color("#5E4D3F", 0.75), 1.5)
		draw_line(Vector2(600.0, 79.0), Vector2(692.0, 79.0), Color("#5E4D3F", 0.75), 1.5)
		draw_line(Vector2(118.0, 801.0), Vector2(210.0, 801.0), Color("#5E4D3F", 0.75), 1.5)
		draw_line(Vector2(600.0, 801.0), Vector2(692.0, 801.0), Color("#5E4D3F", 0.75), 1.5)

		# Right page: faint 8-point compass star watermark at top-right
		var star_c := Vector2(w - 116.0, 108.0)
		for k in 8:
			var ang := float(k) * PI * 0.25
			var r_out := 38.0 if k % 2 == 0 else 22.0
			draw_line(star_c, star_c + Vector2(cos(ang), sin(ang)) * r_out, Color("#E3D3B3", 0.55), 1.6)

		# Right page: signature L-axis bronze header bar + bottom-right L corner bracket
		draw_line(Vector2(864.0, 52.0), Vector2(864.0, 396.0), Color("#9E7B52", 0.90), 5.0)
		draw_line(Vector2(842.0, 82.0), Vector2(w - 120.0, 82.0), Color("#9E7B52", 0.90), 4.5)
		draw_line(Vector2(w - 134.0, h - 56.0), Vector2(w - 78.0, h - 56.0), Color("#9E7B52", 0.85), 5.0)
		draw_line(Vector2(w - 78.0, h - 112.0), Vector2(w - 78.0, h - 54.0), Color("#9E7B52", 0.85), 5.0)

	func _draw_rounded_box(r: Rect2, rad: float, fill: Color, border: Color, bw: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.border_color = border
		sb.set_border_width_all(int(bw))
		sb.set_corner_radius_all(int(rad))
		draw_style_box(sb, r)

	func _draw_diamond(center: Vector2, r: float, col: Color, filled: bool) -> void:
		var pts := PackedVector2Array([
			center + Vector2(0.0, -r),
			center + Vector2(r * 0.75, 0.0),
			center + Vector2(0.0, r),
			center + Vector2(-r * 0.75, 0.0)
		])
		if filled:
			draw_colored_polygon(pts, col)
		else:
			pts.append(pts[0])
			draw_polyline(pts, col, 1.4, true)

	func _draw_filigree_corner(origin: Vector2, dir: Vector2) -> void:
		var ink_c := Color("#46392F", 0.78)
		var gold_c := Color("#C9A265", 0.85)
		var c1 := origin + Vector2(22.0 * dir.x, 22.0 * dir.y)
		draw_circle(c1, 8.5, gold_c)
		draw_arc(c1, 13.0, 0.0, TAU, 24, ink_c, 1.4, true)
		var arm_h := PackedVector2Array([
			origin + Vector2(34.0 * dir.x, 14.0 * dir.y),
			origin + Vector2(62.0 * dir.x, 12.0 * dir.y),
			origin + Vector2(78.0 * dir.x, 20.0 * dir.y),
			origin + Vector2(54.0 * dir.x, 26.0 * dir.y)
		])
		draw_polyline(arm_h, ink_c, 1.6, true)
		var arm_v := PackedVector2Array([
			origin + Vector2(14.0 * dir.x, 34.0 * dir.y),
			origin + Vector2(12.0 * dir.x, 62.0 * dir.y),
			origin + Vector2(20.0 * dir.x, 78.0 * dir.y),
			origin + Vector2(26.0 * dir.x, 54.0 * dir.y)
		])
		draw_polyline(arm_v, ink_c, 1.6, true)


class _RibbonHeaderCanvas:
	extends Control
	var is_rose := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var fill := Color("#EAB4B7", 0.90) if is_rose else Color("#DFE4C2", 0.92)
		var edge := Color("#D5969A", 0.85) if is_rose else Color("#C6CE9E", 0.85)
		var curl := Color("#FFF7EE", 0.88)
		var pts := PackedVector2Array([
			Vector2(0.0, 2.0),
			Vector2(w - 6.0, 0.0),
			Vector2(w, h * 0.5),
			Vector2(w - 8.0, h - 2.0),
			Vector2(2.0, h),
		])
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, edge, 1.5, true)
		# Delicate hand-drawn swirl on right side matching reference ribbon
		var sx := w - 42.0
		var sy := h * 0.52
		draw_arc(Vector2(sx, sy), 7.5, PI * 0.2, TAU, 16, curl, 2.0, true)
		draw_arc(Vector2(sx + 13.0, sy - 1.0), 5.0, PI, TAU * 0.9, 14, curl, 1.8, true)


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

	func _ready() -> void:
		_layout_nameplate()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
			_layout_nameplate()

	func _layout_nameplate() -> void:
		if not is_instance_valid(_nameplate):
			return
		var k := size / CARD_CANVAS
		if k.x <= 0.0 or k.y <= 0.0:
			return
		DaylightUI.place(_nameplate, NAMEPLATE_RECT.position.x * k.x, NAMEPLATE_RECT.position.y * k.y, NAMEPLATE_RECT.size.x * k.x, NAMEPLATE_RECT.size.y * k.y)
		_nameplate.add_theme_font_size_override("font_size", clampi(roundi(38.0 * k.y), 11, 26))

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
