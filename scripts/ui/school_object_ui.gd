class_name SchoolObjectUI
extends RefCounted

## Native 16:9 illustrations supply the composition; all text and input remain live.
const DESIGN := Vector2(1920, 1080)
const INK := Color("#38445E")
const MUTED := Color("#75798E")
const PURPLE := Color("#82749F")

static func art(parent: Control, node_name: String, path: String, rect: Rect2 = Rect2(0, 0, 1920, 1080)) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(path): node.texture = load(path)
	parent.add_child(node)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return node

static func text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 28, color: Color = INK, centered: bool = false) -> Label:
	var label := NotebookUI.label(parent, node_name, copy, rect.position, rect.size, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	return label

static func hit(parent: Control, node_name: String, rect: Rect2, copy: String = "", font_size: int = 30) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = copy
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed", "focus"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(1.0,0.95,0.85,0.18) if state == "hover" else Color(0.22,0.32,0.46,0.18)
		if state == "focus":
			wash.bg_color = Color.TRANSPARENT
			wash.border_color = Color("#DAAC62")
			wash.set_border_width_all(2)
		wash.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state,wash)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: button.add_theme_color_override(key, INK)
	button.add_theme_color_override("font_disabled_color", Color("#8C9095"))
	parent.add_child(button)
	DaylightUI.place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	if copy.strip_edges() in ["×","✕","✖","X"]: style_close_button(button)
	return button

static func slab(parent: Control, node_name: String, rect: Rect2, fill: Color = Color("#EEE7DF")) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.39, 0.42, 0.53, 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	DaylightUI.place(panel, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return panel

static func rule(parent: Control, node_name: String, rect: Rect2) -> ColorRect:
	var line := ColorRect.new()
	line.name = node_name
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = Color(0.39, 0.42, 0.53, 0.22)
	parent.add_child(line)
	DaylightUI.place(line, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return line

static func style_close_button(button: BaseButton) -> void:
	for state in ["normal","disabled","focus"]:
		button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["hover","pressed","hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(INK.r,INK.g,INK.b,0.08 if state == "hover" else 0.14)
		wash.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state,wash)

static func borderless(button: BaseButton) -> void:
	button.add_theme_color_override("font_disabled_color",Color("#8C9095"))
	if button is Button and button.text.strip_edges() in ["×","✕","✖","X"]:
		style_close_button(button)
		return
	# Keep the existing fills and keyboard operation without drawing a focus frame.
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var source := button.get_theme_stylebox(state)
		if source is StyleBoxFlat:
			var style := source.duplicate() as StyleBoxFlat
			style.set_border_width_all(0)
			button.add_theme_stylebox_override(state,style)


## Apply after the choice's own styles; keep press and keyboard feedback intact.
static func set_selected(button: Button, selected: bool) -> void:
	button.set_meta("choice_selected",selected)
	if selected and not button.has_meta("choice_hover_defaults"):
		var defaults := {}
		for state in ["hover","hover_pressed"]:
			defaults[state] = {"override":button.has_theme_stylebox_override(state),"value":button.get_theme_stylebox(state)}
		for key in ["font_hover_color","font_hover_pressed_color","icon_hover_color","icon_hover_pressed_color"]:
			defaults[key] = {"override":button.has_theme_color_override(key),"value":button.get_theme_color(key)}
		button.set_meta("choice_hover_defaults",defaults)
	if selected:
		button.add_theme_stylebox_override("hover",button.get_theme_stylebox("normal"))
		button.add_theme_stylebox_override("hover_pressed",button.get_theme_stylebox("pressed"))
		for prefix in ["font","icon"]:
			button.add_theme_color_override(prefix+"_hover_color",button.get_theme_color(prefix+"_color"))
			button.add_theme_color_override(prefix+"_hover_pressed_color",button.get_theme_color(prefix+"_pressed_color"))
	elif button.has_meta("choice_hover_defaults"):
		var defaults: Dictionary = button.get_meta("choice_hover_defaults")
		for state in ["hover","hover_pressed"]:
			if defaults[state]["override"]: button.add_theme_stylebox_override(state,defaults[state]["value"])
			else: button.remove_theme_stylebox_override(state)
		for key in ["font_hover_color","font_hover_pressed_color","icon_hover_color","icon_hover_pressed_color"]:
			if defaults[key]["override"]: button.add_theme_color_override(key,defaults[key]["value"])
			else: button.remove_theme_color_override(key)
	if button.has_meta("DaylightFeedbackBound"): DaylightUI._update_button_feedback(button)

static func fit_surface(control: Control, rise: float, shear: float = 0.0, depth: float = 1.0) -> void:
	# An affine surface transforms the painted button, text and native input together.
	# The two basis vectors follow the illustrated plate's horizontal and depth edges.
	var parent := control.get_parent()
	var index := control.get_index()
	var surface := Node2D.new()
	surface.name = str(control.name) + "Surface"
	var origin := control.position
	var extent := control.size
	parent.remove_child(control)
	parent.add_child(surface)
	parent.move_child(surface,index)
	surface.add_child(control)
	control.position = Vector2.ZERO
	surface.transform = Transform2D(Vector2(1.0,rise/maxf(1.0,extent.x)),Vector2(shear/maxf(1.0,extent.y),depth),origin)
