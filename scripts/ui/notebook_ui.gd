class_name NotebookUI
extends RefCounted

const INK := Color("#232C47")
const MUTED := Color("#4E5066")
const PLUM := Color("#74638E")

static func label(parent: Control, node_name: String, copy: String, point: Vector2, extent: Vector2, font_size: int = 28, color: Color = INK) -> Label:
	var result := Label.new()
	result.name = node_name
	result.text = copy
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	if font_size >= 38: result.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	else: result.add_theme_font_override("font", DaylightUI.body_font())
	parent.add_child(result)
	DaylightUI.place(result, point.x, point.y, extent.x, extent.y)
	return result

static func paper(parent: Control, node_name: String, point: Vector2, extent: Vector2, key: String = "card_frame") -> Panel:
	var result := Panel.new()
	result.name = node_name
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_stylebox_override("panel", SceneSkin.style(key, Vector4.ZERO))
	parent.add_child(result)
	DaylightUI.place(result, point.x, point.y, extent.x, extent.y)
	return result

static func button(parent: Control, node_name: String, copy: String, point: Vector2, extent: Vector2, primary: bool = false) -> Button:
	var result := Button.new()
	result.name = node_name
	result.text = copy
	result.add_theme_font_size_override("font_size", 30)
	result.add_theme_color_override("font_color", Color("#FFFCF7") if primary else INK)
	result.add_theme_color_override("font_hover_color", Color("#FFFCF7") if primary else INK)
	result.add_theme_color_override("font_pressed_color", INK)
	for state in ["normal", "hover", "pressed", "disabled"]:
		result.add_theme_stylebox_override(state, SceneSkin.style("button_primary" if primary else "button_secondary", Vector4(18, 8, 18, 8), Color(0.96, 0.94, 1.0) if state == "pressed" else Color.WHITE))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	DaylightUI.bind_button_feedback(result)
	parent.add_child(result)
	DaylightUI.place(result, point.x, point.y, extent.x, extent.y)
	return result

static func icon(parent: Control, key: String, point: Vector2, extent: Vector2 = Vector2(38, 38)) -> TextureRect:
	var result := TextureRect.new()
	result.name = "Icon_" + key
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.texture = load("res://assets/ui/system/" + key + ".svg")
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(result)
	DaylightUI.place(result, point.x, point.y, extent.x, extent.y)
	return result

static func saved_copy(metadata: Dictionary) -> String:
	if not metadata.get("available", false): return "空白存档 · 尚未记录"
	var timestamp: int = int(metadata.get("saved_at", 0)) + int(Time.get_time_zone_from_system()["bias"]) * 60
	var date := Time.get_datetime_string_from_unix_time(timestamp, true).left(10)
	return "%s    体力 %d\n%s%s" % [DayCycleService.date_label(int(metadata.get("day",1)),int(metadata.get("hour",8))),metadata.get("hp",0),date," · 备份可恢复" if metadata.get("backup",false) else ""]
