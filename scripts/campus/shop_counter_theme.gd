class_name ShopCounterTheme
extends RefCounted

## Self-contained warm daylight watercolor theme for CampusShopPanel (registered to campus_shop_ui_clean.png at 1920x1080).
const DESIGN := Vector2(1920.0, 1080.0)
const NATIVE := Vector2(1920.0, 1080.0)
const PLATE_PATH := "res://assets/ui/campus_life/shop_counter_plate.png"
const WIDE_BG_PATH := "res://assets/ui/campus_life/campus_shop_bg_wide.png"
const UI_LAYER_PATH := "res://assets/ui/campus_life/campus_shop_ui_clean.png"

const PAPER := Color("#F7F0E0")
const INK := Color("#303B45")
const MUTED := Color("#5C6668")
const HIGHLIGHT := Color("#BA6A58")
const SAGE := Color("#5E7560")
const ACCENT := Color("#EFE7D4")

const SHOP_RECTS := {
	"LocationName": [172, 118, 480, 48],
	"LocalService": [172, 168, 480, 36],
	"Balance": [1336, 148, 193, 52],
	"CloseButton": [1549, 148, 198, 52],
	"Mode_buy": [670, 146, 142, 52],
	"Mode_sell": [826, 146, 174, 52],
	"Talk": [1018, 146, 280, 52],
	"Category_cards": [198, 224, 294, 46],
	"Category_materials": [533, 224, 294, 46],
	"Category_supplies": [868, 224, 294, 46],
	"SelectedName": [1308, 338, 424, 46],
	"ProductPreview": [1318, 386, 404, 124],
	"Description": [1314, 514, 412, 92],
	"UnitPrice": [1314, 608, 412, 36],
	"QuantityMinus": [1356, 650, 94, 79],
	"Quantity": [1464, 650, 110, 79],
	"QuantityPlus": [1588, 650, 94, 79],
	"Total": [1304, 742, 432, 46],
	"ConfirmTrade": [1358, 801, 323, 79],
	"Feedback": [460, 949, 1000, 36],
	"Rules": [460, 1004, 1000, 38],
}

static func panel(parent: Control, node_name: String, rect: Rect2, fill: Color = Color("#FAF8F0")) -> Panel:
	var node := SchoolObjectUI.slab(parent, node_name, rect, fill)
	var style := node.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_corner_radius_all(13)
	style.border_color = Color("#B7C8CD")
	style.set_border_width_all(1)
	return node

static func text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 24, muted: bool = false) -> Label:
	var node := SchoolObjectUI.text(parent, node_name, copy, rect, font_size, MUTED if muted else INK)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func prose(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 19) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.name = node_name
	node.bbcode_enabled = false
	node.fit_content = false
	node.scroll_active = false
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.text = copy
	node.add_theme_font_size_override("normal_font_size", font_size)
	node.add_theme_color_override("default_color", INK)
	node.add_theme_constant_override("line_separation", 3)
	parent.add_child(node)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return node

static func button(parent: Control, node_name: String, copy: String, rect: Rect2, highlighted: bool = false) -> Button:
	var node := Button.new()
	node.name = node_name
	node.text = copy
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 23)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = SAGE if highlighted else PAPER
		if state == "hover":
			style.bg_color = Color("#4E6450") if highlighted else Color("#FFFDF7")
		elif state in ["pressed", "hover_pressed"]:
			style.bg_color = style.bg_color.darkened(0.08)
		elif state == "disabled":
			style.bg_color = Color("#E7DFCE")
		style.border_color = Color("#4C604E") if highlighted else Color("#C4B399")
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		node.add_theme_stylebox_override(state, style)
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(key, Color("#FFFDF7") if highlighted else INK)
	node.add_theme_color_override("font_disabled_color", Color("#988E7F"))
	parent.add_child(node)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	SchoolObjectUI.set_selected(node, highlighted)
	return node

static func apply(host: Control) -> void:
	var art := host.find_child("LocalShopBackground", true, false) as TextureRect
	if art != null and ResourceLoader.exists(PLATE_PATH):
		art.texture = load(PLATE_PATH) as Texture2D
		art.stretch_mode = TextureRect.STRETCH_SCALE
	for panel_node in host.find_children("*", "Panel", true, false):
		if panel_node.name not in ["FooterBacking", "FeedbackBacking"]:
			panel_node.hide()
		else:
			var fstyle := panel_node.get_theme_stylebox("panel") as StyleBoxFlat
			if fstyle != null:
				fstyle.bg_color = Color(0.98, 0.95, 0.88, 0.94) if panel_node.name == "FeedbackBacking" else Color(0.97, 0.94, 0.87, 0.88)
				fstyle.border_color = Color("#BA6A58") if panel_node.name == "FeedbackBacking" else Color("#C4B399")
				fstyle.set_corner_radius_all(10)
	for btn in host.find_children("*", "Button", true, false):
		var keep_pill := btn.name.begins_with("Mode_") or btn.name.begins_with("Category_") or btn.name == "Talk"
		if not keep_pill:
			var tile_selected := btn.name.begins_with("Product_") and btn.name == "Product_" + str(host.selected_id)
			_overlay(btn, tile_selected)
		if btn.name == "ConfirmTrade":
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				btn.add_theme_color_override(key, Color("#FFFDF7"))
			btn.add_theme_color_override("font_disabled_color", Color(0.96, 0.92, 0.86, 0.72))
			btn.add_theme_font_size_override("font_size", 24)
		elif btn.name in ["CloseButton", "QuantityMinus", "QuantityPlus"]:
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				btn.add_theme_color_override(key, INK)
			btn.add_theme_font_size_override("font_size", 28 if btn.name.begins_with("Quantity") else 23)
	for id in SHOP_RECTS:
		var node := host.find_child(id, true, false) as Control
		if node != null:
			_register(node, SHOP_RECTS[id])
	for centered_id in ["Balance", "SelectedName", "UnitPrice", "Quantity", "Total", "Feedback", "Rules"]:
		var lbl := host.find_child(centered_id, true, false) as Label
		if lbl != null:
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var loc_lbl := host.find_child("LocationName", true, false) as Label
	if loc_lbl != null:
		loc_lbl.add_theme_font_size_override("font_size", 32)
	var svc_lbl := host.find_child("LocalService", true, false) as Label
	if svc_lbl != null:
		svc_lbl.add_theme_font_size_override("font_size", 20)
	var qty_lbl := host.find_child("Quantity", true, false) as Label
	if qty_lbl != null:
		qty_lbl.add_theme_font_size_override("font_size", 30)
	var total_lbl := host.find_child("Total", true, false) as Label
	if total_lbl != null:
		total_lbl.add_theme_font_size_override("font_size", 21)
	var unit_lbl := host.find_child("UnitPrice", true, false) as Label
	if unit_lbl != null:
		unit_lbl.add_theme_font_size_override("font_size", 22)
	var sel_lbl := host.find_child("SelectedName", true, false) as Label
	if sel_lbl != null:
		sel_lbl.add_theme_font_size_override("font_size", 30)
	var index := 0
	for tile in host.refs.get("products", {}).values():
		_register(tile, [198 + (index % 3) * 335, 326 + (index / 3) * 302, 294, 262])
		_register(tile.get_node("ProductArt"), [22, 16, 250, 146])
		var pname := tile.get_node("ProductName") as Label
		_register(pname, [18, 168, 258, 42])
		pname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pname.add_theme_font_size_override("font_size", 25)
		var pprice := tile.get_node("Price") as Label
		_register(pprice, [18, 212, 258, 32])
		pprice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pprice.add_theme_font_size_override("font_size", 20)
		index += 1

static func _rect(values: Array) -> Rect2:
	return Rect2(Vector2(values[0], values[1]) * DESIGN / NATIVE, Vector2(values[2], values[3]) * DESIGN / NATIVE)

static func _register(node: Control, values: Array) -> void:
	var rect := _rect(values)
	node.position = rect.position
	node.size = rect.size
	node.set_meta("concept_source_rect", Rect2(values[0], values[1], values[2], values[3]))

static func _overlay(btn: Button, selected_tile: bool = false) -> void:
	if selected_tile:
		var sel := StyleBoxFlat.new()
		sel.bg_color = Color(0.73, 0.42, 0.35, 0.09)
		sel.border_color = HIGHLIGHT
		sel.set_border_width_all(2)
		sel.set_corner_radius_all(10)
		btn.add_theme_stylebox_override("normal", sel)
	else:
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if btn.name == "ConfirmTrade":
		var dis := StyleBoxFlat.new()
		dis.bg_color = Color(0.88, 0.85, 0.80, 0.45)
		dis.set_corner_radius_all(12)
		btn.add_theme_stylebox_override("disabled", dis)
	else:
		btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(0.45, 0.35, 0.25, 0.08 if state == "hover" else 0.16)
		wash.set_corner_radius_all(10)
		btn.add_theme_stylebox_override(state, wash)

