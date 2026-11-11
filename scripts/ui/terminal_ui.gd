class_name TerminalUI
extends RefCounted

const INK := Color("#294963")
const MUTED := Color("#788F9A")
const MINT := Color("#D8EAE2")

static func panel(parent: Control, id: String, rect: Rect2, fill: Color = Color("#FAFBF7")) -> Panel:
	var node := SchoolObjectUI.slab(parent,id,rect,fill)
	var style := node.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_border_width_all(0)
	style.set_corner_radius_all(16)
	return node

static func text(parent: Control, id: String, copy: String, rect: Rect2, font_size: int = 28, muted: bool = false) -> Label:
	var node := SchoolObjectUI.text(parent,id,copy,rect,font_size,MUTED if muted else INK)
	node.add_theme_font_override("font",DaylightUI.get_theme().default_font)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func button(parent: Control, id: String, copy: String, rect: Rect2, selected: bool = false) -> Button:
	var node := SchoolObjectUI.hit(parent,id,rect,copy,27)
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = MINT if selected else Color("#FBFCF8")
		if state == "hover": style.bg_color = Color("#E8F0E9")
		elif state in ["pressed","hover_pressed"]: style.bg_color = Color("#CADDD8")
		elif state == "disabled": style.bg_color = Color("#E5E9E6")
		style.set_corner_radius_all(13)
		style.set_content_margin_all(12)
		node.add_theme_stylebox_override(state,style)
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: node.add_theme_color_override(key,INK)
	node.set_meta("choice_selected",selected)
	return node

static func prose(parent: Control, id: String, copy: String, rect: Rect2, font_size: int = 26) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.name = id
	node.text = copy
	node.scroll_active = true
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	node.add_theme_font_override("normal_font",DaylightUI.get_theme().default_font)
	node.focus_mode = Control.FOCUS_ALL
	node.add_theme_font_size_override("normal_font_size",font_size)
	node.add_theme_color_override("default_color",INK)
	node.add_theme_constant_override("line_separation",9)
	parent.add_child(node)
	DaylightUI.place(node,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	return node

static func field_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FBFCF8")
	style.set_border_width_all(0)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	return style

static func list(parent: Control, id: String, rect: Rect2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	DaylightUI.place(scroll,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
	var box := VBoxContainer.new()
	box.name = "Rows"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",18)
	scroll.add_child(box)
	return box
