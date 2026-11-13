class_name ShopCounterTheme
extends RefCounted

## Self-contained warm paper/storefront theme for CampusShopPanel (decoupled from retired TerminalUI).
const DESIGN := Vector2(1920.0, 1080.0)
const NATIVE := Vector2(1672.0, 941.0)
const PLATE_PATH := "res://assets/ui/campus_life/shop_counter_plate.png"

const PAPER := Color("#F6F2E5")
const INK := Color("#294963")
const MUTED := Color("#627786")
const HIGHLIGHT := Color("#3E657E")
const ACCENT := Color("#D8EAE2")

const SHOP_RECTS := {
	"LocationName": [139, 79, 1060, 65],
	"LocalService": [142, 145, 1025, 45],
	"Balance": [1207, 130, 185, 45],
	"CloseButton": [1414, 91, 125, 59],
	"Mode_buy": [131, 230, 151, 55],
	"Mode_sell": [297, 230, 178, 55],
	"Talk": [572, 230, 200, 55],
	"Category_cards": [131, 301, 262, 56],
	"Category_materials": [408, 301, 278, 56],
	"Category_supplies": [700, 301, 278, 56],
	"SelectedName": [1064, 218, 471, 57],
	"ProductPreview": [1064, 285, 473, 185],
	"Description": [1070, 495, 460, 70],
	"UnitPrice": [1070, 579, 460, 45],
	"QuantityMinus": [1070, 630, 103, 55],
	"Quantity": [1214, 630, 60, 55],
	"QuantityPlus": [1302, 630, 93, 55],
	"Total": [1070, 706, 460, 45],
	"ConfirmTrade": [1070, 759, 467, 67],
	"Feedback": [136, 831, 1350, 35],
	"Rules": [169, 863, 1300, 35],
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

static func prose(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 24) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.name = node_name
	node.bbcode_enabled = false
	node.fit_content = false
	node.scroll_active = true
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.text = copy
	node.add_theme_font_size_override("normal_font_size", font_size)
	node.add_theme_color_override("default_color", INK)
	node.add_theme_constant_override("line_separation", 8)
	parent.add_child(node)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return node

static func button(parent: Control, node_name: String, copy: String, rect: Rect2, highlighted: bool = false) -> Button:
	var node := Button.new()
	node.name = node_name
	node.text = copy
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = HIGHLIGHT if highlighted else ACCENT
		if state == "hover":
			style.bg_color = Color("#34576F") if highlighted else Color("#E5F2EB")
		elif state in ["pressed", "hover_pressed"]:
			style.bg_color = style.bg_color.darkened(0.10)
		elif state == "disabled":
			style.bg_color = Color("#E5ECE8")
		style.border_color = Color("#AEC4C9")
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		node.add_theme_stylebox_override(state, style)
	node.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(key, Color.WHITE if highlighted else INK)
	node.add_theme_color_override("font_disabled_color", Color("#8B9BA2"))
	parent.add_child(node)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	SchoolObjectUI.set_selected(node, highlighted)
	return node

static func apply(host: Control) -> void:
	for node in host.find_children("*", "TextureRect", true, false):
		if node.get_meta("shop_dynamic_patch", false):
			node.get_parent().remove_child(node)
			node.queue_free()
	var art := host.find_child("LocalShopBackground", true, false) as TextureRect
	if art != null and ResourceLoader.exists(PLATE_PATH):
		art.texture = load(PLATE_PATH) as Texture2D
		art.stretch_mode = TextureRect.STRETCH_SCALE
	for panel_node in host.find_children("*", "Panel", true, false):
		panel_node.hide()
	for btn in host.find_children("*", "Button", true, false):
		_overlay(btn)
		if btn.name == "ConfirmTrade":
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				btn.add_theme_color_override(key, Color("#FFFDF7"))
			btn.add_theme_color_override("font_disabled_color", Color("#E4EFE7"))
		elif btn.name.begins_with("Mode_") or btn.name.begins_with("Category_") or btn.name in ["Talk", "CloseButton", "QuantityMinus", "QuantityPlus"]:
			for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				btn.add_theme_color_override(key, INK)
	for id in SHOP_RECTS:
		var node := host.find_child(id, true, false) as Control
		if node != null:
			_register(node, SHOP_RECTS[id])
	_blank_patch(host, [129, 374, 855, 463], [104, 374, 14, 463])
	_blank_patch(host, [128, 297, 855, 63], [104, 297, 14, 63])
	var texture: Texture2D = load(PLATE_PATH) as Texture2D if ResourceLoader.exists(PLATE_PATH) else null
	var index := 0
	for tile in host.refs.get("products", {}).values():
		_register(tile, [131 + (index % 3) * 289, 377 + (index / 3) * 235, 271, 221])
		if texture != null:
			_plate(tile, texture, Rect2(131, 377, 271, 221))
		_register(tile.get_node("ProductArt"), [20, 13, 231, 133])
		_register(tile.get_node("ProductName"), [20, 153, 231, 35])
		_register(tile.get_node("Price"), [20, 191, 231, 26])
		index += 1
	if texture != null:
		for id in ["buy", "sell"]:
			var mode_node := host.find_child("Mode_" + id, true, false) as Button
			if mode_node != null:
				_plate(mode_node, texture, Rect2(131, 230, 151, 55) if id == host.mode else Rect2(297, 230, 178, 55))
		for id in ["cards", "materials", "supplies"]:
			var node := host.find_child("Category_" + id, true, false) as Button
			if node != null:
				_plate(node, texture, Rect2(131, 301, 262, 56) if id == host.category else Rect2(408, 301, 278, 56))

static func _rect(values: Array) -> Rect2:
	return Rect2(Vector2(values[0], values[1]) * DESIGN / NATIVE, Vector2(values[2], values[3]) * DESIGN / NATIVE)

static func _register(node: Control, values: Array) -> void:
	var rect := _rect(values)
	node.position = rect.position
	node.size = rect.size
	node.set_meta("concept_source_rect", Rect2(values[0], values[1], values[2], values[3]))

static func _overlay(btn: Button) -> void:
	for state in ["normal", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(0.2, 0.42, 0.51, 0.07 if state == "hover" else 0.15)
		wash.set_corner_radius_all(12)
		btn.add_theme_stylebox_override(state, wash)

static func _plate(btn: Button, texture: Texture2D, region: Rect2) -> void:
	var crop := AtlasTexture.new()
	crop.atlas = texture
	crop.region = region
	var style := StyleBoxTexture.new()
	style.texture = crop
	style.set_texture_margin_all(14)
	btn.add_theme_stylebox_override("normal", style)
	for state in ["hover", "pressed", "hover_pressed"]:
		var wash := style.duplicate() as StyleBoxTexture
		wash.modulate_color = Color(0.94, 1.0, 1.0) if state == "hover" else Color(0.86, 0.93, 0.94)
		btn.add_theme_stylebox_override(state, wash)

static func _blank_patch(host: Control, target: Array, source: Array) -> void:
	var image := host.find_child("LocalShopBackground", true, false) as TextureRect
	if image == null or image.texture == null:
		return
	var patch := TextureRect.new()
	patch.name = "DynamicListBacking"
	patch.set_meta("shop_dynamic_patch", true)
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	patch.stretch_mode = TextureRect.STRETCH_SCALE
	var crop := AtlasTexture.new()
	crop.atlas = image.texture
	crop.region = Rect2(source[0], source[1], source[2], source[3])
	patch.texture = crop
	image.get_parent().add_child(patch)
	image.get_parent().move_child(patch, image.get_index() + 1)
	_register(patch, target)

