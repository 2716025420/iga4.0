class_name ZodiacAlbumPanel
extends Control

## Pure 2D watercolor paper album for permanent Zodiac story badges.
signal close_requested
signal action_requested(action: String, payload: Dictionary)

const DESIGN := Vector2(1740.0, 960.0)
const PAPER := Color("#FBF5E9")
const CARD_FILL := Color("#F3EBDC")
const CARD_HOVER := Color("#EAE1CE")
const CARD_SELECTED := Color("#DCE9DD")
const CARD_UNCOLLECTED := Color("#EFE9DE")
const DETAIL_FILL := Color("#F6EFE1")
const BORDER_SOFT := Color("#D4C7B2")
const BORDER_ACTIVE := Color("#6E8774")
const INK := Color("#2D3A46")
const MUTED := Color("#6A7078")
const SAGE := Color("#54745D")
const WARM_GOLD := Color("#A47842")

var context: Dictionary = {}
var refs: Dictionary = {}
var selected_zodiac := "hero"
var _uncollected_shader: Shader

static func create(_kind: String = "zodiac", panel_context: Dictionary = {}) -> ZodiacAlbumPanel:
	var panel := ZodiacAlbumPanel.new()
	panel.set_meta("design_size", DESIGN)
	panel.custom_minimum_size = DESIGN
	panel.size = DESIGN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.refresh(panel_context)
	return panel

func _ready() -> void:
	Platform.input_mode_changed.connect(_on_input_mode_changed)

func _on_input_mode_changed(_touch: bool) -> void:
	var hint_node := find_child("CloseHint", true, false) as Label
	if is_instance_valid(hint_node):
		hint_node.text = Platform.hint("Esc 返回 · 方向键浏览", "点击星座查看详细档案")

func refresh(panel_context: Dictionary = {}) -> void:
	if not panel_context.is_empty():
		context.merge(panel_context, true)
	if context.has("selected_zodiac") and ZodiacCatalog.known(str(context["selected_zodiac"])):
		selected_zodiac = str(context["selected_zodiac"])
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	theme = DaylightUI.get_theme()
	size = DESIGN

	var backing := SchoolPaperSurface.create(self, "AlbumPaper", Rect2(Vector2.ZERO, DESIGN), PAPER)
	backing.mouse_filter = Control.MOUSE_FILTER_STOP

	var snapshot := SpecialCardCollection.snapshot()
	var owned_count: int = snapshot["collected"].size()

	var title := _text(self, "Title", "十二星座图鉴", Rect2(64, 34, 340, 56), 44, INK)
	title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	_text(self, "Subtitle", "永久剧情收藏 · 已收录 %d / 12" % owned_count, Rect2(376, 46, 520, 40), 24, SAGE if owned_count > 0 else MUTED)

	var records_btn := _pill_button(self, "OpenRecords", "放映档案", Rect2(1292, 40, 210, 56), false)
	records_btn.pressed.connect(func(): action_requested.emit("open_records", {}))
	refs["open_records"] = records_btn

	var close := _pill_button(self, "CloseButton", "返回 ×", Rect2(1526, 40, 146, 56), false)
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close

	var rule := SchoolObjectUI.rule(self, "HeaderRule", Rect2(64, 118, 1608, 2))
	rule.color = BORDER_SOFT

	if _uncollected_shader == null and ResourceLoader.exists("res://assets/shaders/uncollected_badge.gdshader"):
		_uncollected_shader = load("res://assets/shaders/uncollected_badge.gdshader") as Shader

	var badges := {}
	var order := ZodiacCatalog.ORDER
	for index in order.size():
		var id: String = order[index]
		var data := ZodiacCatalog.definition(id)
		var owned := SpecialCardCollection.collected(id)
		var is_sel := id == selected_zodiac
		var col := index % 4
		var row := index / 4
		var tile := _tile_button(self, "Badge_" + id, Rect2(64 + col * 246, 146 + row * 230, 230, 212), owned, is_sel)
		var icon := SchoolObjectUI.art(tile, "BadgeIcon", "res://assets/ui/zodiac_badges/%s.svg" % str(data["zodiac"]), Rect2(63, 16, 104, 104))
		if not owned and _uncollected_shader != null:
			var mat := ShaderMaterial.new()
			mat.shader = _uncollected_shader
			icon.material = mat
		var name_lbl := _text(tile, "Name", str(data["name"]), Rect2(14, 128, 202, 36), 27, INK, true)
		name_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		_text(tile, "State", "已收录 · %s" % str(data["archetype"]) if owned else "未收录 · %s" % str(data["archetype"]), Rect2(14, 168, 202, 28), 19, SAGE if owned else MUTED, true)
		tile.pressed.connect(_select_badge.bind(id))
		badges[id] = tile
	refs["badges"] = badges

	_build_detail_pane(1078, 146, 594, 672)

	_text(self, "PermanentStory", "剧情收藏永久保留 · 不加入普通卡组，不参与商店交易", Rect2(64, 868, 980, 40), 22, MUTED)
	var hint_label := _text(self, "CloseHint", Platform.hint("Esc 返回 · 方向键浏览", "点击星座查看详细档案"), Rect2(1140, 868, 532, 40), 22, MUTED)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_wire_focus()

func _select_badge(id: String) -> void:
	selected_zodiac = id
	refresh()
	var btn := refs.get("badges", {}).get(id) as Button
	if is_instance_valid(btn):
		btn.grab_focus.call_deferred()

func _build_detail_pane(x: float, y: float, w: float, h: float) -> void:
	var pane := Panel.new()
	pane.name = "ZodiacDetail"
	pane.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = DETAIL_FILL
	style.border_color = BORDER_SOFT
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	pane.add_theme_stylebox_override("panel", style)
	add_child(pane)
	DaylightUI.place(pane, x, y, w, h)

	var sel := ZodiacCatalog.definition(selected_zodiac)
	var sel_owned := SpecialCardCollection.collected(selected_zodiac)

	var icon := SchoolObjectUI.art(pane, "DetailBadgeIcon", "res://assets/ui/zodiac_badges/%s.svg" % str(sel["zodiac"]), Rect2(28, 24, 92, 92))
	if not sel_owned and _uncollected_shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = _uncollected_shader
		icon.material = mat

	var heading := _text(pane, "ZodiacName", str(sel["name"]), Rect2(138, 24, w - 166, 48), 36, INK)
	heading.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	_text(pane, "Archetype", "对应原型 · %s    |    能力：%s" % [str(sel["archetype"]), str(sel["power"])], Rect2(138, 76, w - 166, 36), 22, SAGE if sel_owned else MUTED)
	_text(pane, "Motto", "「%s」" % str(sel["motto"]), Rect2(28, 128, w - 56, 34), 22, WARM_GOLD)

	var divider := SchoolObjectUI.rule(pane, "DetailRule", Rect2(28, 170, w - 56, 1))
	divider.color = BORDER_SOFT

	var status_line := "收录状态：已于故事中取得（永久保留）" if sel_owned else "收录状态：尚未取得（需通过正式剧情获得）"
	var prose_text := "%s\n\n能力说明：%s\n\n制约与代价：%s\n\n相互关系：%s" % [
		status_line, str(sel["ability"]), str(sel["limits"]), str(sel["interactions"])
	]
	var body := RichTextLabel.new()
	body.name = "ZodiacDescription"
	body.bbcode_enabled = false
	body.fit_content = false
	body.scroll_active = true
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = prose_text
	body.add_theme_font_size_override("normal_font_size", 22)
	body.add_theme_constant_override("line_separation", 8)
	body.add_theme_color_override("default_color", INK)
	pane.add_child(body)
	DaylightUI.place(body, 28, 186, w - 56, 368)
	refs["detail"] = body

	var key_plate := Panel.new()
	key_plate.name = "KeyPlate"
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color("#ECE4D3")
	key_style.border_color = BORDER_SOFT
	key_style.set_border_width_all(1)
	key_style.set_corner_radius_all(8)
	key_plate.add_theme_stylebox_override("panel", key_style)
	pane.add_child(key_plate)
	DaylightUI.place(key_plate, 28, 574, w - 56, 72)

	var progress := SpecialCardCollection.key_progress()
	var ready_text := " · 集齐完备" if progress["ready"] else ""
	_text(key_plate, "KeyProgress", "其余星座 %d/11 · 钥匙：%s%s" % [progress["other_collected"], "已收录" if progress["has_key"] else "未收录", ready_text], Rect2(18, 10, w - 92, 52), 22, SAGE if progress["ready"] else INK)

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

func _tile_button(parent: Control, node_name: String, rect: Rect2, owned: bool, selected: bool) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = CARD_SELECTED if selected else (CARD_FILL if owned else CARD_UNCOLLECTED)
		if state == "hover":
			box.bg_color = CARD_SELECTED.lightened(0.03) if selected else CARD_HOVER
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = box.bg_color.darkened(0.06)
		box.border_color = BORDER_ACTIVE if selected else BORDER_SOFT
		box.set_border_width_all(2 if selected else 1)
		box.set_corner_radius_all(10)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	parent.add_child(button)
	DaylightUI.place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	SchoolObjectUI.set_selected(button, selected)
	return button

func _pill_button(parent: Control, node_name: String, copy: String, rect: Rect2, primary: bool) -> Button:
	var button := SchoolObjectUI.hit(parent, node_name, rect, copy, 24)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#DCE9DD") if primary else Color("#EFE6D5")
		if state == "hover":
			box.bg_color = Color("#D0E1D2") if primary else Color("#E5D9C4")
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = box.bg_color.darkened(0.08)
		elif state == "disabled":
			box.bg_color = Color("#F4EDE0")
		box.border_color = BORDER_ACTIVE if primary else BORDER_SOFT
		box.set_border_width_all(1)
		box.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, INK)
	button.add_theme_color_override("font_disabled_color", MUTED)
	SchoolObjectUI.borderless(button)
	return button

