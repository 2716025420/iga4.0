class_name CampusDialogueUI
extends Control

## Unified warm-paper journal dialogue box matching main story StoryChrome style.
## Displays live 256x256 character avatars with per-line emotion matching and breathing cursor.

signal closed

const DESIGN := Vector2(1920.0, 1080.0)
const SPEAKER_MAP := {
	"我": "ye_zhou",
	"叶舟": "ye_zhou",
	"林知夏": "lin_zhi_xia",
	"唐小满": "tang_xiao_man",
	"柳宇龙": "liu_yu_long",
	"杨子英": "yang_zi_ying",
	"姜梓": "jiang_zi",
	"黄秋枫": "huang_qiufeng"
}

var lines: Array = []
var line_index := 0
var body: RichTextLabel
var speaker: Label
var portrait: TextureRect
var continue_cursor: Label
var _typing := 0.0
var _cursor_tween: Tween
var _fallback_face: Texture2D = null


func _ready() -> void:
	size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = DaylightUI.get_theme()

	var backdrop := ColorRect.new()
	backdrop.name = "DialogueBackdrop"
	backdrop.color = Color(0.10, 0.14, 0.22, 0.14)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	DaylightUI.place(backdrop, -260.0, 0.0, 2440.0, 1080.0)

	var control_strip := ColorRect.new()
	control_strip.name = "ControlsContrast"
	control_strip.color = Color(0.18, 0.20, 0.28, 0.68)
	control_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control_strip)
	DaylightUI.place(control_strip, -260.0, 987.0, 2440.0, 93.0)

	SchoolObjectUI.art(self, "StoryChrome", "res://assets/ui/school_objects/story_chrome.png", Rect2(0.0, 0.0, 1920.0, 1080.0))

	portrait = SchoolObjectUI.art(self, "SpeakerPortrait", "", Rect2(110.0, 785.0, 136.0, 170.0))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	speaker = SchoolObjectUI.text(self, "Speaker", "", Rect2(265.0, 717.0, 240.0, 62.0), 31, Color("#FFF8EC"), true)
	speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speaker.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	speaker.add_theme_constant_override("outline_size", 0)

	body = RichTextLabel.new()
	body.name = "DialogueText"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.fit_content = false
	body.scroll_active = true
	body.add_theme_font_size_override("normal_font_size", 32)
	body.add_theme_font_size_override("bold_font_size", 32)
	body.add_theme_constant_override("line_separation", 11)
	body.add_theme_color_override("default_color", SchoolObjectUI.INK)
	add_child(body)
	DaylightUI.place(body, 315.0, 805.0, 1415.0, 145.0)

	continue_cursor = SchoolObjectUI.text(self, "ContinueCursor", "点击继续", Rect2(1624.0, 928.0, 112.0, 36.0), 19, Color("#6D6257"))
	continue_cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_cursor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var close := _strip_button("CloseDialogue", "结束交谈 · Esc", Rect2(86.0, 998.0, 250.0, 58.0))
	var next := _strip_button("NextLine", "继续 · Enter / Space", Rect2(1460.0, 998.0, 370.0, 58.0))
	next.pressed.connect(advance)
	close.pressed.connect(_close)
	next.grab_focus.call_deferred()
	_show_line()


func _exit_tree() -> void:
	if is_instance_valid(_cursor_tween):
		_cursor_tween.kill()


func _strip_button(node_name: String, copy: String, rect: Rect2) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = copy
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 25)
	for state in ["normal", "disabled"]:
		btn.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed", "hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(1.0, 0.94, 0.83, 0.18 if state == "hover" else 0.28)
		wash.set_corner_radius_all(8)
		btn.add_theme_stylebox_override(state, wash)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, Color("#FFF6E8"))
	SchoolObjectUI.borderless(btn)
	DaylightUI.bind_button_audio(btn)
	add_child(btn)
	DaylightUI.place(btn, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return btn


func present(script_lines: Array, face: Texture2D = null) -> void:
	lines = script_lines
	_fallback_face = face
	if is_instance_valid(portrait) and face != null:
		portrait.texture = face
		portrait.visible = true
	if is_inside_tree():
		_show_line()


func _emotion_for_line(copy: String) -> String:
	for kw in ["异常", "危险", "警报", "停下", "小心", "覆写", "担心"]:
		if copy.contains(kw):
			return "worried"
	for kw in ["笑", "欢迎", "成交", "加油", "开心", "舒服", "轻松", "汽水", "辛苦", "太好"]:
		if copy.contains(kw):
			return "happy"
	return "neutral"


func _resolve_avatar_texture(speaker_name: String, copy: String) -> Texture2D:
	var char_id := str(SPEAKER_MAP.get(speaker_name.strip_edges(), ""))
	if char_id == "":
		return null
	var emotion := _emotion_for_line(copy)
	var emo_path := "res://assets/sprites/characters/phase_two/avatars/%s_%s.png" % [char_id, emotion]
	if ResourceLoader.exists(emo_path):
		return load(emo_path) as Texture2D
	var neutral_path := "res://assets/sprites/characters/phase_two/avatars/%s_neutral.png" % char_id
	if ResourceLoader.exists(neutral_path):
		return load(neutral_path) as Texture2D
	var port_path := "res://assets/sprites/characters/phase_two/portraits/%s.png" % char_id
	if ResourceLoader.exists(port_path):
		return load(port_path) as Texture2D
	var half_path := "res://assets/sprites/characters/phase_two/halfbody/%s_neutral.png" % char_id
	if not ResourceLoader.exists(half_path):
		half_path = "res://assets/sprites/characters/phase_two/halfbody/%s.png" % char_id
	if ResourceLoader.exists(half_path):
		var half_tex := load(half_path) as Texture2D
		if half_tex != null:
			var atlas := AtlasTexture.new()
			atlas.atlas = half_tex
			var sz := half_tex.get_size()
			atlas.region = Rect2(sz.x * 0.20, sz.y * 0.04, sz.x * 0.60, sz.y * 0.40)
			atlas.filter_clip = true
			return atlas
	return null


func _show_line() -> void:
	if lines.is_empty() or line_index >= lines.size():
		_close()
		return
	var current_speaker := str(lines[line_index][0])
	var current_text := str(lines[line_index][1])
	speaker.text = current_speaker
	var resolved_tex := _resolve_avatar_texture(current_speaker, current_text)
	if resolved_tex != null:
		portrait.texture = resolved_tex
		portrait.visible = true
	elif _fallback_face != null:
		portrait.texture = _fallback_face
		portrait.visible = true
	else:
		portrait.texture = null
		portrait.visible = false
	body.text = current_text
	body.scroll_to_line(0)
	_typing = 0.0
	body.visible_characters = -1 if SaveManager.typing_interval() <= 0.0 else 0
	_set_cursor_active(body.visible_characters < 0)


func _set_cursor_active(active: bool) -> void:
	if not is_instance_valid(continue_cursor):
		return
	continue_cursor.visible = active
	if is_instance_valid(_cursor_tween):
		_cursor_tween.kill()
		_cursor_tween = null
	if not active or bool(SaveManager.settings.get("reduced_motion", false)):
		continue_cursor.modulate.a = 0.85
		continue_cursor.position.x = 1624.0
		return
	continue_cursor.modulate.a = 0.50
	continue_cursor.position.x = 1620.0
	_cursor_tween = create_tween().set_loops()
	_cursor_tween.tween_property(continue_cursor, "modulate:a", 0.95, 0.58).set_trans(Tween.TRANS_SINE)
	_cursor_tween.parallel().tween_property(continue_cursor, "position:x", 1626.0, 0.58).set_trans(Tween.TRANS_SINE)
	_cursor_tween.tween_property(continue_cursor, "modulate:a", 0.50, 0.58).set_trans(Tween.TRANS_SINE)
	_cursor_tween.parallel().tween_property(continue_cursor, "position:x", 1620.0, 0.58).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if not is_instance_valid(body) or body.visible_characters < 0:
		return
	var interval: float = SaveManager.typing_interval()
	if interval <= 0.0:
		body.visible_characters = -1
		_set_cursor_active(true)
		return
	_typing += delta
	var next_chars := mini(body.get_total_character_count(), int(_typing / interval))
	body.visible_characters = next_chars
	if next_chars >= body.get_total_character_count():
		body.visible_characters = -1
		_set_cursor_active(true)


func advance() -> void:
	if body.visible_characters >= 0 and body.visible_characters < body.get_total_character_count():
		body.visible_characters = -1
		_set_cursor_active(true)
		return
	line_index += 1
	_show_line()


func _close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			advance()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_close()
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance()
		accept_event()
